import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/color_palette.dart';

/// A single settings row used inside a [SettingsSection].
///
/// Mirrors the original private `_SettingsTile` from the old profile
/// screen: 38x38 colored icon tile, 14-bold title, 12-subtitle, optional
/// trailing widget, full-row tap target.
///
/// Takes a [ColorPalette] so the icon background and tint follow the
/// active brand color. When [iconColor] is provided (e.g. for the
/// destructive "Sign Out" tile) it overrides the palette's primary.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;
  final ColorPalette palette;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.palette,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = (iconColor ?? palette.primary).withValues(alpha: 0.08);
    final iconFg = iconColor ?? palette.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconFg, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor ?? AppColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
