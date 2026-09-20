/// T-1: display-only numeric formatter for question content.
///
/// The active question bank stores option/explanation numbers as plain
/// longhand decimal strings (the bank generator's formatting policy is
/// "plain decimal, never exponent"), which renders very small
/// physics/chemistry quantities as 15–28 character strings such as
/// `0.00000000000000808`. The stored VALUES are correct — only their
/// rendered form is unreadable — so this formatter rewrites display text
/// only; the question bank JSON is never modified.
///
/// Behaviour (value-preserving in every branch):
///   * ordinary numbers (short decimals, integers, prose): unchanged
///   * very small (< 1e-4) / very large (>= 1e6) longhand decimals:
///     rewritten as `d.dd × 10ⁿ` with Unicode superscripts, sign and unit kept
///   * existing scientific notation (`8.08 × 10⁻¹⁵ V`): normalized —
///     identical when already clean
///   * the malformed generator form `0.00000183 × 10⁻⁵ N` (tiny mantissa
///     multiplied by a second power of ten): collapsed into one clean power
///     of ten (`1.83 × 10⁻¹¹ N`) — never double-applied
///   * anything this formatter cannot parse with confidence (units it does
///     not recognize, chained expressions like `3 × 10⁸ × 2`, exponent-less
///     "× 10", words after a value) is left EXACTLY as stored
library;

import 'dart:math' as math;

/// Fast-path gate: only strings containing a numeric token we might rewrite
/// go through the parser. Everything else returns untouched.
final RegExp _needsWorkRe = RegExp(r'\d\.\d{7,}|\d\.\d+\s*[×xX·]\s*10|\d{10,}');

/// Optional-sign decimal number at a scan position: "8.08", "-0.5", ".5".
final RegExp _numRe = RegExp(r'^(-?\d+(?:\.\d+)?|-?\.\d+)');

/// A "× 10ⁿ" / "× 10^n" / "× 10^(n)" marker directly after a mantissa.
/// The multiplication sign may be ×, x, X or ·, with optional spaces.
final RegExp _markerRe =
    RegExp(r'^\s*[×xX·]\s*10(?:\^\((-?\d+)\)|\^(-?\d+)|([⁻⁰¹²³⁴⁵⁶⁷⁸⁹]+))');

/// Unicode superscripts → ASCII (for exponent parsing only).
const Map<String, String> _supAscii = {
  '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4',
  '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9', '⁻': '-',
};

const List<String> _supDigits = [
  '⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹',
];

/// Physical units that may follow a rewritten value and be re-attached after
/// reformatting. Longest-first matching plus a word-boundary check keeps
/// prose safe: "5 min" consumes "min", "5 moles" rejects "mol" (the word
/// continues) and leaves the token unchanged.
const List<String> _units = [
  // compound / multi-token
  'kg m/s', 'kg/m³', 'g/cm³', 'g/mol', 'N m²/C²', 'N/C', 'V/m', 'mmHg',
  'm/s²', 'rad/s²',
  // velocity
  'km/s', 'cm/s', 'mm/s', 'm/s', 'rad/s',
  // concentration
  'mol/L', 'mol/dm³', 'g/dm³', 'mg/L',
  // length
  'km', 'cm', 'mm', 'nm', 'μm', 'm',
  // mass
  'kg', 'mg', 'μg', 'g',
  // time
  'ms', 'μs', 'ns', 'min', 'h', 's',
  // electric
  'mV', 'kV', 'MV', 'V', 'mA', 'μA', 'kA', 'A', 'mC', 'μC', 'nC', 'pC', 'C',
  'mF', 'μF', 'nF', 'pF', 'F', 'mΩ', 'kΩ', 'MΩ', 'Ω',
  // force / energy / power
  'μN', 'mN', 'kN', 'MN', 'N', 'mJ', 'kJ', 'MJ', 'eV', 'keV', 'MeV', 'GeV',
  'J', 'mW', 'kW', 'MW', 'W',
  // magnetic / thermal / other
  'mT', 'μT', 'T', 'kHz', 'MHz', 'GHz', 'Hz', 'kPa', 'MPa', 'hPa', 'Pa',
  'atm', 'bar', 'mol', 'mmol', 'K', '°C', 'mrad', 'rad', '°',
  'mL', 'dL', 'L', 'm²', 'cm²', 'mm²', 'km²', 'm³', 'cm³', 'mm³',
];

final List<String> _sortedUnits = List<String>.of(_units)
  ..sort((a, b) => b.length.compareTo(a.length));

/// Rewrites unreadable numeric tokens in [input] for display.
///
/// Pure string→string: the returned value never changes any numeric value,
/// sign, unit, or option ordering, and the input string is never mutated.
/// Returns [input] itself (same instance) when nothing needed changing.
String formatNumericDisplay(String input) {
  if (!_needsWorkRe.hasMatch(input)) return input;

  final buf = StringBuffer();
  var i = 0;
  var changed = false;

  while (i < input.length) {
    final ch = input[i];
    final cp = ch.codeUnitAt(0);
    final numericStart =
        (cp >= 0x30 && cp <= 0x39) || ch == '.' || ch == '-';

    final m = numericStart ? _matchNumber(input, i) : null;
    if (m == null) {
      buf.write(ch);
      i++;
      continue;
    }

    String? replacement;
    var consumedEnd = m.end;
    if (m.value.isFinite) {
      final u = _matchUnit(input, m.end);
      if (u != null && _shouldRewrite(m, u.$1.isEmpty)) {
        replacement = _formatSci(m.value, u.$1) + u.$2;
        consumedEnd = u.$3;
      }
    }

    final span = input.substring(i, consumedEnd);
    if (replacement != null && replacement != span) {
      buf.write(replacement);
      changed = true;
    } else {
      buf.write(span);
    }
    i = consumedEnd;
  }

  return changed ? buf.toString() : input;
}

/// Decide whether a parsed numeric token should be rewritten, based on its
/// stored form. "Ordinary" stored forms are never rewritten — readability is
/// the only goal, so short decimals and human-scale integers stay as-is.
bool _shouldRewrite(_NumMatch m, bool noUnit) {
  if (!m.value.isFinite) return false;
  if (m.hadMarker) {
    // Scientific notation: only normalize when the stored mantissa is
    // unreadably small (the generator's malformed `0.00000183 × 10⁻⁵`
    // form). Already-clean forms compare equal and are left identical.
    final mantissa = double.parse(m.raw);
    return mantissa.abs() < 1e-3;
  }
  final raw = m.raw;
  final dot = raw.indexOf('.');
  final bool ordinary;
  if (dot < 0) {
    ordinary = raw
            .replaceFirst(RegExp(r'^-'), '')
            .length <=
        9; // ≤ 999,999,999 stays longhand
  } else {
    ordinary = raw.length - dot - 1 <= 6; // ≤ 6 decimal places stays longhand
  }
  if (ordinary) return false;
  final abs = m.value.abs();
  return abs < 1e-4 || abs >= 1e6;
}

class _NumMatch {
  final double value;
  final int end;
  final bool hadMarker;

  /// The stored mantissa characters (without marker/exponent).
  final String raw;
  const _NumMatch(this.value, this.end, this.hadMarker, this.raw);
}

_NumMatch? _matchNumber(String s, int start) {
  final m = _numRe.firstMatch(s.substring(start));
  if (m == null) return null;
  final raw = m.group(1)!;
  final double mantissa;
  try {
    mantissa = double.parse(raw);
  } on FormatException {
    return null;
  }
  final i = start + m.end;

  final marker = _markerRe.firstMatch(s.substring(i));
  if (marker == null) return _NumMatch(mantissa, i, false, raw);

  final expText =
      marker.group(1) ?? marker.group(2) ?? _supToAscii(marker.group(3)!);
  final exp = int.tryParse(expText);
  if (exp == null) return null; // malformed exponent — leave token alone
  final value = mantissa * math.pow(10.0, exp).toDouble();
  return _NumMatch(value, i + marker.end, true, raw);
}

/// Matches a recognized physical unit (after optional spaces) at [start].
/// Returns `(unit, remainderAfterUnit, endPositionAfterUnit)`, or null when
/// no unit starts there — in which case the numeric token is left untouched.
(String, String, int)? _matchUnit(String s, int start) {
  var j = start;
  while (j < s.length && s[j] == ' ') {
    j++;
  }
  if (j >= s.length) return ('', '', s.length);
  for (final unit in _sortedUnits) {
    if (s.startsWith(unit, j)) {
      final after = j + unit.length;
      final wordContinues = after < s.length && _isLetter(s[after]);
      if (!wordContinues) return (unit, s.substring(after), after);
    }
  }
  // No unit word: allow a bare rewrite only when hard punctuation or the
  // end of the string follows (never "space + word" — that could be prose).
  if (j == start && _isHardBoundary(s[j])) {
    return ('', s.substring(j), j);
  }
  return null;
}

bool _isHardBoundary(String c) => ')],;='.contains(c);

bool _isLetter(String c) => c.toLowerCase() != c;

/// Formats [v] as `d.dd × 10ⁿ` (mantissa 3 sig figs, trailing zeros
/// trimmed, "1.00 × 10ⁿ" compacted to "10ⁿ"), re-attaching [unit].
String _formatSci(double v, String unit) {
  final negative = v < 0;
  final abs = v.abs();
  var exp = (math.log(abs) / math.ln10).floor();
  var mant = abs / math.pow(10.0, exp);
  if (mant >= 10) {
    mant /= 10;
    exp++;
  } else if (mant < 1) {
    mant *= 10;
    exp--;
  }
  var mantStr = mant.toStringAsFixed(2);
  if (mantStr == '10.00') {
    exp++;
    mantStr = '1.00';
  }
  mantStr = _trimZeros(mantStr);
  final sign = negative ? '-' : '';
  final sup = _toSuperscript(exp);
  final body = mantStr == '1' ? '10$sup' : '$mantStr × 10$sup';
  return unit.isEmpty ? '$sign$body' : '$sign$body $unit';
}

String _trimZeros(String s) {
  if (!s.contains('.')) return s;
  var t = s;
  while (t.endsWith('0')) {
    t = t.substring(0, t.length - 1);
  }
  return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
}

String _supToAscii(String s) =>
    s.split('').map((c) => _supAscii[c] ?? '').join();

String _toSuperscript(int n) {
  final digits = n
      .abs()
      .toString()
      .split('')
      .map((c) => _supDigits[int.parse(c)])
      .join();
  return n < 0 ? '⁻$digits' : digits;
}
