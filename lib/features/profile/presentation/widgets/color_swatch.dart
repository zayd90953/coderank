import 'package:flutter/material.dart';

/// A small circular swatch showing a brand color, with an optional
/// selection ring. Used in the color picker and the Color Theme settings
/// tile trailing slot.
class ColorSwatch extends StatelessWidget {
  /// The color to fill the swatch with (typically a [ColorPalette.primary]).
  final Color color;

  /// Whether to draw a brand-tinted selection ring around the swatch.
  final bool selected;

  /// Outer ring color when [selected] is true. Defaults to
  /// `Colors.white` on dark mode / `Color(0xFFEDE8F5)` on light, but
  /// callers can pass a brand color to draw a "ring within a ring".
  final Color? ringColor;

  /// Diameter of the filled swatch circle, in logical pixels.
  final double size;

  const ColorSwatch({
    super.key,
    required this.color,
    this.selected = false,
    this.ringColor,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final outer = ringColor ?? const Color(0xFFEDE8F5);
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outer,
        border: selected
            ? Border.all(color: color, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
