import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';

/// A labeled group of [SettingsTile]s. Composes a small uppercase header
/// above a rounded card containing the children separated by a thin
/// divider. Reads surface/border colors from the current theme so it
/// works correctly in both light and dark modes.
class SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainer;
    final border = Theme.of(context).colorScheme.outline;
    final dividerColor = Theme.of(context).colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
          ),
          child: Column(
            children: _withDividers(children, dividerColor),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> tiles, Color dividerColor) {
    if (tiles.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) {
        out.add(Divider(
          color: dividerColor,
          height: 1,
          indent: 56,
        ));
      }
    }
    return out;
  }
}
