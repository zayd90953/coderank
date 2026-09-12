import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/firebase_user_util.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/widgets/subject_icon_badge.dart';
import '../../daily_challenge/presentation/daily_challenge_screen.dart';
import '../../mock_test/presentation/mock_test_chooser_screen.dart';
import '../../navigation/main_nav_screen.dart';
import '../../practice/presentation/practice_screen.dart';
import '../../practice/presentation/setup/practice_setup_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// The Home tab. Mirrors the `home_wanted.jpeg` reference:
/// time-based greeting + rank-progress subtitle, XP/streak/tier
/// header pills, a "Your Progress" card with ranking + Deep Analytics
/// link, a "Continue Learning" row with badge chips + Explore All
/// link, a "Daily NEET Challenge" card, and a "Subjects" row.
///
/// Every tap routes to a real destination so no card is a dead button:
///   * Practice   → PracticeScreen
///   * Mock Test  → PracticeScreen (mock-test flow)
///   * Explore All → PracticeScreen
///   * Daily Challenge card → DailyChallengeScreen
///   * Deep Analytics link → Analytics tab via MainNavScreen.switchTab
///   * Rank card → Leaderboard tab via MainNavScreen.switchTab
///   * Subject tiles → PracticeSetupScreen(subject: ...)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good morning";
    if (hour >= 12 && hour < 17) return "Good afternoon";
    if (hour >= 17 && hour < 21) return "Good evening";
    if (hour >= 21 || hour < 5) return "Late night grind";
    return "Welcome back";
  }

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final user = firebaseCurrentUserOrNull();
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim().split(' ').first
        : "Student";

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<UserProgressData>(
          valueListenable: UserProgressService.instance.progressNotifier,
          builder: (context, data, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GreetingHeader(
                    palette: palette,
                    greeting: getGreeting(),
                    name: name,
                    user: user,
                    data: data,
                    onAvatarTap: () => _openProfile(context),
                  ),
                  const SizedBox(height: 22),

                  // ── Your Progress card ─────────────────────────────────
                  _ProgressCard(palette: palette, data: data),
                  const SizedBox(height: 28),

                  // ── Continue Learning row ─────────────────────────────
                  const _SectionTitle("Continue Learning"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          palette: palette,
                          icon: Icons.menu_book_rounded,
                          iconColor: AppColors.physics,
                          iconBg: Theme.of(context).colorScheme.surfaceContainerHighest,
                          title: "Practice",
                          subtitle: "Subject MCQs",
                          badge: "2,200+ Qs",
                          onTap: () => _openPractice(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          palette: palette,
                          icon: Icons.timer_rounded,
                          iconColor: AppColors.warning,
                          iconBg: Theme.of(context).colorScheme.surfaceContainerHighest,
                          title: "Mock Test",
                          subtitle: "Timed Exam",
                          badge: "Exam Mode",
                          onTap: () => _openMockTest(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Daily NEET Challenge card
                  _DailyChallengeCard(
                    palette: palette,
                    isCompleted: UserProgressService
                        .instance.dailyChallengeCompletedToday(),
                    onTap: () => _openDailyChallenge(context),
                  ),

                  const SizedBox(height: 28),

                  // ── Subjects row ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle("Subjects"),
                      TextButton(
                        onPressed: () => _openPractice(context),
                        child: Text(
                          "See all",
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SubjectTile(
                          title: "Physics",
                          onTap: () => _openSubject(context, 'Physics'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SubjectTile(
                          title: "Chemistry",
                          onTap: () => _openSubject(context, 'Chemistry'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SubjectTile(
                          title: "Biology",
                          onTap: () => _openSubject(context, 'Biology'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── Rank card → leaderboard tab ───────────────────────
                  _RankCard(
                    palette: palette,
                    onTap: () => MainNavScreen.switchTab(context, 2),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPractice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PracticeScreen()),
    );
  }

  void _openSubject(BuildContext context, String subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSetupScreen(subject: subject),
      ),
    );
  }

  void _openMockTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MockTestChooserScreen()),
    );
  }

  void _openDailyChallenge(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DailyChallengeScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting header (greeting + name + subtitle + XP/streak/tier-avatar pills)
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final ColorPalette palette;
  final String greeting;
  final String name;
  final User? user;
  final UserProgressData data;
  final VoidCallback onAvatarTap;

  const _GreetingHeader({
    required this.palette,
    required this.greeting,
    required this.name,
    required this.user,
    required this.data,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(name);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$greeting 🔥, $name",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitleFor(data),
                style: TextStyle(
                  fontSize: 13,
                  color: onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Streak pill
        if (data.streakDays > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF8A00).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🔥", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  "${data.streakDays}d",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        // Tier avatar circle — tap to open Profile (P4-3: profile entry).
        Material(
          color: palette.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initialsFor(String name) {
    if (user != null &&
        user!.photoURL != null &&
        user!.photoURL!.isNotEmpty) {
      return name.isNotEmpty ? name[0].toUpperCase() : "S";
    }
    return name.isNotEmpty ? name[0].toUpperCase() : "S";
  }

  String _subtitleFor(UserProgressData data) {
    if (data.totalQuestions == 0) {
      return "Start your first practice session to get ranked!";
    }
    final acc = data.overallAccuracy.round();
    return "$acc% accuracy across ${data.totalQuestions} questions • Keep it up!";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Your Progress" card (XP pill, Ranking label, footer, Deep Analytics link)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final ColorPalette palette;
  final UserProgressData data;

  const _ProgressCard({required this.palette, required this.data});

  @override
  Widget build(BuildContext context) {
    final totalQuestions = data.totalQuestions;
    final accuracy = data.overallAccuracy.round();
    final tierProgress = data.tierProgress;
    final ceiling = data.nextTierTargetXp;
    // Honest, accuracy-based standing ("Unranked" until the user has
    // practiced; "Top X%" after). The old XP-derived formula produced
    // nonsense — it reset to "Top 99%" at every tier boundary.
    final rankValue = data.percentile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Your Progress",
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // XP pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFFFD166),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "${data.xpPoints} XP · ${data.tier}",
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _ProgressStat(
                  value: "$totalQuestions",
                  label: "Questions",
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _ProgressStat(
                  value: "$accuracy%",
                  label: "Accuracy",
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              // Ranking stat is tappable → Leaderboard tab (the doc
              // comment always promised this; it was never wired).
              Expanded(
                child: InkWell(
                  onTap: () => MainNavScreen.switchTab(context, 2),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _ProgressStat(
                      value: rankValue,
                      label: "Ranking",
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: tierProgress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  data.totalQuestions == 0
                      ? "Start practicing to build your rank"
                      : "Next tier at $ceiling XP",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => MainNavScreen.switchTab(context, 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Deep Analytics",
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textOnPrimary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProgressStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Continue Learning" + "Daily NEET Challenge" cards
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final ColorPalette palette;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _ActionCard({
    required this.palette,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.primarySubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final ColorPalette palette;

  /// A-3: when true, the right-hand CTA flips to a "✅ Done today" pill
  /// (muted, non-actionable) so the user can see at a glance that today's
  /// daily is already done. Tapping the card still opens the launcher,
  /// which shows the locked-state button.
  final bool isCompleted;

  final VoidCallback onTap;

  const _DailyChallengeCard({
    required this.palette,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text("🔥", style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily NEET Challenge",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? "Today's challenge complete — come back tomorrow"
                          : "Solve today's high-yield set & earn +50 XP",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceVariant.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("✅", style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        "Done today",
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "Solve",
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subjects row (unified SubjectIconBadge squircles + "Start" label)
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SubjectTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            children: [
              SubjectIconBadge(subject: title, size: 52),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Start",
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank card → leaderboard tab
// ─────────────────────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final ColorPalette palette;
  final VoidCallback onTap;

  const _RankCard({required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: palette.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Rank",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "See where you stand on the leaderboard",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
