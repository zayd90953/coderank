import 'package:flutter/material.dart' hide ColorSwatch;
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/firebase_user_util.dart';
import '../../../shared/services/user_preferences_service.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../welcome/presentation/welcome_screen.dart';
import 'sheets/avatar_picker_sheet.dart';
import 'sheets/color_picker_sheet.dart';
import 'sheets/edit_name_sheet.dart';
import 'sheets/target_picker_sheet.dart';
import 'sheets/theme_picker_sheet.dart';
import 'widgets/color_swatch.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ── Auth flows (kept here so they stay co-located with their UI) ─────────

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text("Sign Out",
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text)),
          ],
        ),
        content: const Text(
          "Are you sure you want to sign out of CodeRank? Your study progress is safely saved.",
          style: TextStyle(fontSize: 14, color: AppColors.subtitle, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(
                    color: AppColors.subtitle, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Sign Out",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, ColorPalette palette) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Reset Progress?",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text)),
        content: const Text(
          "This will reset all your solved questions, XP, and subject accuracies back to zero. This cannot be undone.",
          style: TextStyle(fontSize: 13, color: AppColors.subtitle, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await UserPreferencesService.instance.resetProgress();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Study progress has been reset."),
                    backgroundColor: palette.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Reset All"),
          ),
        ],
      ),
    );
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  ({String name, String email, String? photoUrl, bool isGoogleUser})
      _identity() {
    final user = firebaseCurrentUserOrNull();
    final prefs = UserPreferencesService.instance.current;
    final custom = prefs.displayName?.trim();
    final fbName = user?.displayName?.trim();
    final name = (custom != null && custom.isNotEmpty)
        ? custom
        : (fbName != null && fbName.isNotEmpty)
            ? fbName
            : "NEET Aspirant";
    return (
      name: name,
      email: user?.email ?? "student@coderank.ai",
      photoUrl: user?.photoURL,
      isGoogleUser: user?.providerData
              .any((p) => p.providerId == 'google.com') ??
          false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final id = _identity();

    return ValueListenableBuilder<UserPreferences>(
      valueListenable: UserPreferencesService.instance.prefsNotifier,
      builder: (context, prefs, _) {
        return ValueListenableBuilder<UserProgressData>(
          valueListenable: UserProgressService.instance.progressNotifier,
          builder: (context, data, _) {
            return ValueListenableBuilder<ColorPalette>(
              valueListenable: ColorPaletteController.instance.paletteNotifier,
              builder: (context, palette, _) {
                return Scaffold(
                  backgroundColor: const Color(0xFFF8F7FD),
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: const BackButtonToHome(),
                    title: const Text("Student Profile",
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    centerTitle: true,
                  ),
                  body: SingleChildScrollView(
                    primary: true,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Column(
                      children: [
                        _HeaderCard(
                          name: id.name,
                          email: id.email,
                          photoUrl: id.photoUrl,
                          assetKey: prefs.avatarAssetKey,
                          tier: data.tier,
                          targetYear: prefs.targetYear,
                          targetState: prefs.targetState,
                          targetCollege: prefs.targetCollege,
                          palette: palette,
                          onAvatarTap: () => showAvatarPickerSheet(context),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.quiz_rounded,
                                value: "${data.totalQuestions}",
                                label: "Questions",
                                color: AppColors.physics,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.track_changes_rounded,
                                value: "${data.overallAccuracy.round()}%",
                                label: "Accuracy",
                                color: AppColors.chemistry,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.bolt_rounded,
                                value: "${data.xpPoints}",
                                label: "Total XP",
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Account ──
                        SettingsSection(
                          label: "Account",
                          children: [
                            _IdentityRow(
                              name: id.name,
                              email: id.email,
                              photoUrl: id.photoUrl,
                              assetKey: prefs.avatarAssetKey,
                              palette: palette,
                            ),
                            SettingsTile(
                              icon: Icons.edit_rounded,
                              title: "Edit Name",
                              subtitle: "How others see you in the app",
                              palette: palette,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.subtitle,
                              ),
                              onTap: () => showEditNameSheet(context,
                                  initial: id.name),
                            ),
                            SettingsTile(
                              icon: Icons.logout_rounded,
                              title: "Sign Out",
                              subtitle: "Return to the welcome screen",
                              textColor: AppColors.error,
                              iconColor: AppColors.error,
                              palette: palette,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.subtitle,
                              ),
                              onTap: () => _confirmSignOut(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── App ──
                        SettingsSection(
                          label: "App",
                          children: [
                            SettingsTile(
                              icon: Icons.palette_rounded,
                              title: "Theme",
                              subtitle: _themeLabel(prefs.themeMode),
                              palette: palette,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.subtitle,
                              ),
                              onTap: () => showThemePickerSheet(context),
                            ),
                            SettingsTile(
                              icon: Icons.color_lens_rounded,
                              title: "Color Theme",
                              subtitle: _colorLabel(prefs.colorThemeId),
                              palette: palette,
                              trailing: ColorSwatch(
                                color: palette.primary,
                                selected: true,
                                size: 22,
                              ),
                              onTap: () => showColorPickerSheet(context),
                            ),
                            SwitchSettingsTile(
                              icon: Icons.notifications_active_rounded,
                              title: "Daily Practice Reminder",
                              subtitle: "9:00 AM Daily NEET Challenge",
                              value: prefs.dailyReminderEnabled,
                              palette: palette,
                              onChanged: (v) => UserPreferencesService.instance
                                  .setDailyReminder(v),
                            ),
                            SettingsTile(
                              icon: Icons.tune_rounded,
                              title: "Practice Defaults",
                              subtitle:
                                  "${prefs.practiceQuestionCount} questions • ${prefs.practiceSecondsPerQuestion}s per question",
                              palette: palette,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.subtitle,
                              ),
                              onTap: () =>
                                  _showPracticeDefaultsDialog(context, prefs),
                            ),
                            SettingsTile(
                              icon: Icons.refresh_rounded,
                              title: "Reset Study Progress",
                              subtitle:
                                  "Clear questions and reset rank to test fresh",
                              textColor: AppColors.error,
                              iconColor: AppColors.error,
                              palette: palette,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.subtitle,
                              ),
                              onTap: () => _confirmReset(context, palette),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── About ──
                        SettingsSection(
                          label: "About",
                          children: [
                            SettingsTile(
                              icon: Icons.info_outline_rounded,
                              title: "Version",
                              subtitle: "CodeRank release info",
                              palette: palette,
                              trailing: const Text(
                                "v1.0.0",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.subtitle,
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.favorite_rounded,
                              title: "About CodeRank",
                              subtitle: "A smart learning platform for NEET aspirants",
                              palette: palette,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.subtitle,
                              ),
                              onTap: () => _showAboutDialog(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "CodeRank v1.0.0 • Made for Ambitious NEET Aspirants",
                          style: TextStyle(fontSize: 11, color: AppColors.subtitle),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _themeLabel(String value) {
    switch (value) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System default';
    }
  }

  String _colorLabel(String id) => ColorPalette.byId(id).label;

  void _showPracticeDefaultsDialog(
      BuildContext context, UserPreferences prefs) {
    final countController =
        TextEditingController(text: '${prefs.practiceQuestionCount}');
    final secondsController =
        TextEditingController(text: '${prefs.practiceSecondsPerQuestion}');
    final palette = ColorPaletteController.instance.current;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Practice Defaults",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Questions per session',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: secondsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Seconds per question',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(countController.text.trim());
              final seconds = int.tryParse(secondsController.text.trim());
              if (count == null ||
                  seconds == null ||
                  count <= 0 ||
                  seconds <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter positive numbers."),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              await UserPreferencesService.instance.setPracticeDefaults(
                count: count,
                seconds: seconds,
              );
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("About CodeRank",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text)),
        content: const Text(
          "CodeRank is a smart NEET prep companion built for ambitious students. "
          "Practice topic-wise, take mock tests, and climb the daily leaderboard "
          "as you build the consistency that cracks NEET.",
          style: TextStyle(fontSize: 13, color: AppColors.subtitle, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close",
                style: TextStyle(color: AppColors.subtitle)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Header card
// ──────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final String? assetKey;
  final String tier;
  final int? targetYear;
  final String? targetState;
  final String? targetCollege;
  final ColorPalette palette;
  final VoidCallback onAvatarTap;

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.assetKey,
    required this.tier,
    required this.targetYear,
    required this.targetState,
    required this.targetCollege,
    required this.palette,
    required this.onAvatarTap,
  });

  String _formatTarget() {
    final parts = <String>[];
    if (targetYear != null) parts.add('NEET $targetYear');
    if (targetCollege != null && targetCollege!.isNotEmpty) {
      parts.add(targetCollege!);
    } else if (targetState != null && targetState!.isNotEmpty) {
      parts.add(targetState!);
    }
    if (parts.isEmpty) return 'Tap to set your target';
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final hasFullTarget = targetCollege != null && targetCollege!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE8F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: ProfileAvatar(
                  displayName: name,
                  googlePhotoUrl: photoUrl,
                  assetKey: assetKey,
                  palette: palette,
                  radius: 40,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 3),
          Text(email,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => showTargetPickerSheet(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: palette.primarySubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_rounded,
                      size: 16, color: palette.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Target: ${_formatTarget()}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasFullTarget
                          ? palette.primary
                          : AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_rounded,
                      size: 12, color: palette.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Identity row inside the Account section
// ──────────────────────────────────────────

class _IdentityRow extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final String? assetKey;
  final ColorPalette palette;

  const _IdentityRow({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.assetKey,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: ProfileAvatar(
              displayName: name,
              googlePhotoUrl: photoUrl,
              assetKey: assetKey,
              palette: palette,
              radius: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.subtitle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// A settings tile with a trailing Switch.
// ──────────────────────────────────────────

class SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;
  final ColorPalette palette;

  const SwitchSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.palette,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = palette.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: iconColor ?? primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.subtitle)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: primary,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Stat card
// ──────────────────────────────────────────

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ProfileStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8F5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.subtitle,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
