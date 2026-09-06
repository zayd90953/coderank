import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '_sheet_chrome.dart';

/// Show the "Edit Display Name" sheet. Returns true if a name was saved.
Future<bool?> showEditNameSheet(BuildContext context,
    {required String initial}) {
  return showAppSheet<bool>(
    context,
    StatefulBuilder(
      builder: (ctx, setModal) {
        final controller = TextEditingController(
          text: initial == 'NEET Aspirant' ? '' : initial,
        );
        final palette = ColorPaletteController.instance.current;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle('Edit Display Name'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'e.g. Zayd Khan',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: sheetPrimaryButton(
                label: 'Save',
                primary: palette.primary,
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Display name cannot be empty.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  await UserPreferencesService.instance.setDisplayName(value);
                  if (context.mounted) Navigator.of(ctx).pop(true);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: sheetSecondaryButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
          ],
        );
      },
    ),
  );
}
