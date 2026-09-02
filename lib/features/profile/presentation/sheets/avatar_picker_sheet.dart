import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/firebase_user_util.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '_sheet_chrome.dart';

const _avatarKeys = ['avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6'];

/// Show the avatar picker sheet. The user can either pick one of the six
/// preset illustrated avatars, or (if signed in via Google) reset to their
/// Google photo by clearing the chosen preset.
Future<String?> showAvatarPickerSheet(BuildContext context) {
  final user = firebaseCurrentUserOrNull();
  final hasGooglePhoto =
      user != null && user.photoURL != null && user.photoURL!.isNotEmpty;
  final palette = ColorPaletteController.instance.current;

  return showAppSheet<String>(
    context,
    StatefulBuilder(
      builder: (ctx, setModal) {
        final current =
            UserPreferencesService.instance.current.avatarAssetKey;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle('Choose Avatar'),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  for (final key in _avatarKeys)
                    _AvatarTile(
                      assetKey: key,
                      selected: current == key,
                      palette: palette,
                      onTap: () async {
                        await UserPreferencesService.instance
                            .setAvatarAssetKey(key);
                        if (context.mounted) Navigator.of(ctx).pop(key);
                      },
                    ),
                ],
              ),
            ),
            if (hasGooglePhoto)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: sheetSecondaryButton(
                  label: 'Reset to Google photo',
                  onPressed: () async {
                    await UserPreferencesService.instance
                        .setAvatarAssetKey(null);
                    if (context.mounted) Navigator.of(ctx).pop(null);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: sheetSecondaryButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AvatarTile extends StatelessWidget {
  final String assetKey;
  final bool selected;
  final ColorPalette palette;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.assetKey,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? palette.primary : Colors.transparent,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: Image.asset(
            'assets/avatars/$assetKey.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: palette.primarySubtle,
              child: Center(
                child: Icon(Icons.person_rounded, color: palette.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
