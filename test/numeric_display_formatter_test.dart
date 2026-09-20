// T-1 regression tests: the display formatter must make unreadable numeric
// values readable WITHOUT ever changing a numeric value, sign, unit, or
// option ordering, and WITHOUT touching anything it cannot parse safely.

import 'package:flutter_test/flutter_test.dart';
import 'package:coderank/shared/utils/numeric_display_formatter.dart';

void main() {
  group('ordinary values pass through untouched', () {
    test('prose and small integers', () {
      expect(
        formatNumericDisplay('A block of mass 2 kg on a frictionless surface'),
        'A block of mass 2 kg on a frictionless surface',
      );
      expect(
        formatNumericDisplay('A steady current of 0.5 A flows'),
        'A steady current of 0.5 A flows',
      );
      expect(
        formatNumericDisplay('The half-life is 5 min'),
        'The half-life is 5 min',
      );
      expect(formatNumericDisplay('No numbers here'), 'No numbers here');
    });

    test('short decimals keep their stored form', () {
      expect(formatNumericDisplay('0.0358 kg m/s'), '0.0358 kg m/s');
      // 0.000993 has 6 decimals → "ordinary" by policy → untouched.
      expect(formatNumericDisplay('0.000993 mm'), '0.000993 mm');
      expect(formatNumericDisplay('12.5 N'), '12.5 N');
      expect(formatNumericDisplay('981 cm/s²'), '981 cm/s²');
    });
  });

  group('very small numbers → readable scientific notation', () {
    test('the audited user-reported example', () {
      expect(
        formatNumericDisplay('0.00000000000000808 V'),
        '8.08 × 10⁻¹⁵ V',
      );
    });

    test('real bank values (NEET-9146 / NEET-9165 / NEET-9168)', () {
      expect(formatNumericDisplay('0.000000348 rad'), '3.48 × 10⁻⁷ rad');
      expect(
        formatNumericDisplay('0.000000000000000000000000000288 kg m/s'),
        '2.88 × 10⁻²⁸ kg m/s',
      );
      expect(
        formatNumericDisplay('0.000000916 × 10⁻⁵ N'),
        '9.16 × 10⁻¹² N',
      );
    });

    test('negative values keep their sign', () {
      expect(formatNumericDisplay('-0.000000426 rad'), '-4.26 × 10⁻⁷ rad');
    });
  });

  group('very large numbers → readable scientific notation', () {
    test('longhand large value with unit', () {
      expect(
        formatNumericDisplay('79999999999999996664957894656 C'),
        '8 × 10²⁸ C',
      );
    });
  });

  group('existing scientific notation normalizes value-preservingly', () {
    test('already-clean forms are identical', () {
      expect(formatNumericDisplay('8.08 × 10⁻¹⁵ V'), '8.08 × 10⁻¹⁵ V');
      expect(formatNumericDisplay('3 × 10⁸ m/s'), '3 × 10⁸ m/s');
    });

    test('tiny mantissa × second power of ten collapses exactly once', () {
      // The generator bug form — must NEVER become 0.00000183 × 10⁻¹⁰.
      expect(
        formatNumericDisplay('0.00000183 × 10⁻⁵ N'),
        '1.83 × 10⁻¹¹ N',
      );
      expect(
        formatNumericDisplay('0.00000736 × 10⁻⁴ m/s'),
        '7.36 × 10⁻¹⁰ m/s',
      );
    });
  });

  group('unsafe tokens are left exactly as stored', () {
    test('unrecognized unit word', () {
      expect(
        formatNumericDisplay('0.00000000000000808 parsecs'),
        '0.00000000000000808 parsecs',
      );
      expect(
        formatNumericDisplay('a drift of 0.000000342 furlongs'),
        'a drift of 0.000000342 furlongs',
      );
    });

    test('unit-like prefix that continues as a word is not consumed', () {
      // "mol" must not be eaten out of "moles".
      expect(formatNumericDisplay('5 moles'), '5 moles');
    });

    test('prose after the number (no unit) is left alone', () {
      expect(
        formatNumericDisplay('a shift of 0.0000000031 occurs'),
        'a shift of 0.0000000031 occurs',
      );
    });

    test('chained multiplication is not collapsed', () {
      expect(formatNumericDisplay('3 × 10⁸ × 2 m/s'), '3 × 10⁸ × 2 m/s');
    });

    test('exponent-less × 10 marker is not touched', () {
      expect(formatNumericDisplay('2.5 × 10 samples'), '2.5 × 10 samples');
    });
  });

  group('the formatter is display-only', () {
    test('returns the same instance when nothing needs rewriting', () {
      final input = '0.000993 mm';
      expect(identical(formatNumericDisplay(input), input), isTrue);
    });

    test('never mutates the input string', () {
      final input = '0.000000348 rad';
      final out = formatNumericDisplay(input);
      expect(identical(out, input), isFalse);
      expect(input, '0.000000348 rad', reason: 'stored text stays intact');
    });

    test('correct-option identity is unaffected (values preserved, order kept)',
        () {
      const options = [
        '0.0000017 rad',
        '0.000000348 rad',
        '0.00000139 rad',
        '0.00000114 rad',
      ];
      final formatted = options.map(formatNumericDisplay).toList();
      expect(formatted.length, 4);
      expect(formatted[0], '1.7 × 10⁻⁶ rad');
      expect(formatted[1], '3.48 × 10⁻⁷ rad');
      expect(formatted[2], '1.39 × 10⁻⁶ rad');
      expect(formatted[3], '1.14 × 10⁻⁶ rad');
      // Position/order is untouched — option B stays option B.
      expect(formatted[1], contains('3.48'));
    });
  });
}
