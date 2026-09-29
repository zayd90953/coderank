import 'package:flutter/material.dart';

/// A-10 motion layer: staggers a fixed list of children — each fades up
/// into place [step] after the previous one, so a row of cards arrives
/// as a choreography instead of popping as a block.
///
/// Children are laid out in a [Column] or [Row] per [axis]. Wrap individual
/// children in [Expanded]/[Flexible] as needed — the flex wrappers stay
/// direct children of the flex and only their inner child animates.
///
/// Timers: none. The per-child delay is baked into each animation via a
/// [Interval], so the entrance is driven purely by frames (pumpAndSettle-
/// safe in widget tests).
class StaggeredEntrance extends StatefulWidget {
  final List<Widget> children;
  final Axis axis;
  final Duration step;
  final Duration duration;

  const StaggeredEntrance({
    super.key,
    required this.children,
    this.axis = Axis.vertical,
    this.step = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Next frame: lets the first frame paint fully hidden, then cascade in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (var i = 0; i < widget.children.length; i++) _wrapChild(i),
    ];
    return widget.axis == Axis.vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          )
        : Row(children: children);
  }

  /// Expanded/Flexible must remain DIRECT children of the Flex (their
  /// ParentData is claimed by the Row/Column), so the animation is applied
  /// to their inner child instead of wrapping them.
  Widget _wrapChild(int i) {
    final child = widget.children[i];
    Widget inner = child;
    if (child is Expanded) inner = child.child;
    if (child is Flexible) inner = child.child;
    final animated = _StaggeredChild(
      delay: widget.step * i,
      duration: widget.duration,
      started: _started,
      child: inner,
    );
    if (child is Expanded) {
      return Expanded(flex: child.flex, child: animated);
    }
    if (child is Flexible) {
      return Flexible(flex: child.flex, child: animated);
    }
    return animated;
  }
}

class _StaggeredChild extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final bool started;
  final Widget child;

  const _StaggeredChild({
    required this.delay,
    required this.duration,
    required this.started,
    required this.child,
  });

  @override
  State<_StaggeredChild> createState() => _StaggeredChildState();
}

class _StaggeredChildState extends State<_StaggeredChild>
    with SingleTickerProviderStateMixin {
  /// Total runtime = delay + fade; the delay portion sits inside the
  /// curve's [Interval] so no Timers are ever scheduled.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );

  late final Animation<double> _curved = CurvedAnimation(
    parent: _c,
    curve: Interval(_delayFraction, 1.0, curve: Curves.easeOut),
  );

  double get _delayFraction {
    final total = (widget.delay + widget.duration).inMicroseconds;
    return total == 0 ? 0.0 : widget.delay.inMicroseconds / total;
  }

  @override
  void initState() {
    super.initState();
    if (widget.started) _c.forward();
  }

  @override
  void didUpdateWidget(_StaggeredChild oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.started && !oldWidget.started) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(_curved),
        child: widget.child,
      ),
    );
  }
}
