import 'package:flutter/material.dart';

/// A-10 motion layer: animates an integer from 0 (or [initial]) to [value],
/// so stats land instead of appearing. Purely presentational — it renders
/// [prefix][number][suffix]; pass text styling through [style].
///
/// Zero-state (0) renders instantly — no 500ms count-up for an empty stat.
class CountUp extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  late int _previous = 0;

  @override
  void didUpdateWidget(CountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previous = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value <= 0) {
      return Text('${widget.prefix}0${widget.suffix}', style: widget.style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _previous.toDouble(), end: widget.value.toDouble()),
      duration: widget.duration,
      curve: Curves.easeOut,
      builder: (context, v, _) {
        return Text(
          '${widget.prefix}${v.round()}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
