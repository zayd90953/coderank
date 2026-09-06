import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';

/// Renders the user's profile avatar with a brand-color gradient ring
/// drawn from the supplied [ColorPalette].
///
/// Render priority:
///   1. Google/Firebase photo (when [googlePhotoUrl] is non-null and
///      [assetKey] is null — user has not picked a preset).
///   2. Preset asset image at `assets/avatars/avatar_<key>.png`. Falls back
///      to initials via [errorBuilder] if the asset is missing/corrupt.
///   3. Initials on a white circle.
class ProfileAvatar extends StatelessWidget {
  final String displayName;
  final String? googlePhotoUrl;
  final String? assetKey;
  final double radius;
  final ColorPalette palette;

  const ProfileAvatar({
    super.key,
    required this.displayName,
    required this.palette,
    this.googlePhotoUrl,
    this.assetKey,
    this.radius = 40,
  });

  String get _initial {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'S';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Widget _initialsFallback() {
    final surface = AppColors.surface;
    return CircleAvatar(
      radius: radius,
      backgroundColor: surface,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: palette.primary,
        ),
      ),
    );
  }

  Widget _buildInner() {
    // 1) Preset avatar wins if the user explicitly picked one.
    if (assetKey != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        child: ClipOval(
          child: Image.asset(
            'assets/avatars/avatar_$assetKey.png',
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initialsFallback(),
          ),
        ),
      );
    }

    // 2) Google photo if we have one.
    if (googlePhotoUrl != null && googlePhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        child: ClipOval(
          child: Image.network(
            googlePhotoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initialsFallback(),
            loadingBuilder: (ctx, child, progress) =>
                progress == null ? child : _initialsFallback(),
          ),
        ),
      );
    }

    // 3) Initials.
    return _initialsFallback();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: palette.heroCardGradient,
      ),
      child: _buildInner(),
    );
  }
}
