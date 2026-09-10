import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '_sheet_chrome.dart';

const _options = [
  ('system', 'System default', 'Match my device theme'),
  ('light', 'Light', 'Always use the light theme'),
  ('dark', 'Dark', 'Always use the dark theme'),
];

/// Show the theme picker sheet. Returns the chosen value if the user
/// picked one, or null on cancel.
Future<String?> showThemePickerSheet(BuildContext context) {
  return showAppSheet<String>(
    context,
    StatefulBuilder(
      builder: (ctx, setModal) {
        final current =
            UserPreferencesService.instance.current.themeMode;
        final palette = ColorPaletteController.instance.current;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle('App Theme', context: ctx),
            const SizedBox(height: 4),
            for (final (value, title, subtitle) in _options)
              InkWell(
                onTap: () async {
                  await UserPreferencesService.instance.setThemeMode(value);
                  if (context.mounted) Navigator.of(ctx).pop(value);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: current == value
                            ? Icon(
                                Icons.radio_button_checked_rounded,
                                color: palette.primary,
                                size: 22,
                              )
                            : Icon(
                                Icons.radio_button_unchecked_rounded,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: sheetSecondaryButton(
                context: ctx,
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
