import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A labeled group of [SettingsTile]s. Composes a small uppercase header
/// above a rounded white card containing the children separated by a thin
/// divider.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEDE8F5)),
          ),
          child: Column(
            children: _withDividers(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> tiles) {
    if (tiles.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) {
        out.add(const Divider(
          color: Color(0xFFF0ECF8),
          height: 1,
          indent: 56,
        ));
      }
    }
    return out;
  }
}
