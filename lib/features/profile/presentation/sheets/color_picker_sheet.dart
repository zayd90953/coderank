import 'package:flutter/material.dart' hide ColorSwatch;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '../widgets/color_swatch.dart';
import '_sheet_chrome.dart';

/// Show the color theme picker sheet. The user can pick one of the
/// three brand-color presets; the choice is persisted and the whole
/// app re-tints instantly. Returns the chosen id (e.g. `'ocean'`) or
/// null on cancel.
Future<String?> showColorPickerSheet(BuildContext context) {
  return showAppSheet<String>(
    context,
    StatefulBuilder(
      builder: (ctx, setModal) {
        final currentId =
            UserPreferencesService.instance.current.colorThemeId;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle('Color Theme'),
            const SizedBox(height: 4),
            for (final palette in ColorPalette.all)
              InkWell(
                onTap: () async {
                  await ColorPaletteController.instance.set(palette.id);
                  if (context.mounted) Navigator.of(ctx).pop(palette.id);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      ColorSwatch(
                        color: palette.primary,
                        selected: currentId == palette.id,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              palette.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subtitleFor(palette),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentId == palette.id)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.subtitle,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: sheetSecondaryButton(
                label: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        );
      },
    ),
  );
}

String _subtitleFor(ColorPalette p) {
  switch (p.id) {
    case 'ocean':
      return 'Calm sky-blue accent for focused study';
    case 'forest':
      return 'Grounded green accent for daily grind';
    case 'purple':
    default:
      return 'The classic CodeRank brand purple';
  }
}
