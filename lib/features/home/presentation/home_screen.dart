import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/firebase_user_util.dart';
import '../../../shared/services/user_preferences_service.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/services/weak_area_tracking_service.dart';
import '../../../shared/widgets/count_up.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../../shared/widgets/subject_icon_badge.dart';
import '../../daily_challenge/presentation/daily_challenge_screen.dart';
import '../../diagnostic/presentation/diagnostic_subject_chooser_sheet.dart';
import '../../mock_test/presentation/mock_test_chooser_screen.dart';
import '../../navigation/main_nav_screen.dart';
import '../../practice/presentation/practice_screen.dart';
import '../../practice/presentation/question/question_screen.dart';
import '../../practice/presentation/setup/practice_setup_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../recommendations/data/recommendation_engine.dart';

/// The Home tab. Mirrors the `home_wanted.jpeg` reference:
/// time-based greeting + progress subtitle, XP/streak/tier
/// header pills, a "Your Progress" card with stats + Deep Analytics
/// link, a "Continue Learning" row with badge chips + Explore All
/// link, a "Daily NEET Challenge" card, and a "Subjects" row.
///
/// Every tap routes to a real destination so no card is a dead button:
///   * Practice   → PracticeScreen
///   * Mock Test  → PracticeScreen (mock-test flow)
///   * Explore All → PracticeScreen
///   * Daily Challenge card → DailyChallengeScreen
///   * Deep Analytics link → Analytics tab via MainNavScreen.switchTab
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

    // Name propagation fix: read the greeting name from the SAME source the
    // profile page writes to (UserPreferencesService). Firebase Auth's
    // `displayName` caches at sign-in, so reading it directly left Home
    // showing a stale name after "Edit Display Name".
    return ValueListenableBuilder<UserPreferences>(
      valueListenable: UserPreferencesService.instance.prefsNotifier,
      builder: (context, prefs, _) {
        final fallbackName = user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim().split(' ').first
            : "Student";
        final custom = prefs.displayName?.trim();
        final name = (custom != null && custom.isNotEmpty)
            ? custom.split(' ').first
            : fallbackName;

        return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<UserProgressData>(
          valueListenable: UserProgressService.instance.progressNotifier,
          builder: (context, data, _) {
            return ValueListenableBuilder<WeakAreaData>(
              // R-6: recommendations fuse progress + weak-area state, so
              // they recompute live whenever either changes.
              valueListenable:
                  WeakAreaTrackingService.instance.weakAreasNotifier,
              builder: (context, weakAreas, _) {
                final recommendations = RecommendationEngine.build(
                  progress: data,
                  weakAreas: weakAreas,
                  dailyChallengeDoneToday: UserProgressService.instance
                      .dailyChallengeCompletedToday(),
                );
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

                  // ── R-6: Recommended for you (recommendation-first) ────
                  _RecommendationSection(
                    recommendations: recommendations,
                    onOpenPractice: () => _openPractice(context),
                    onOpenDailyChallenge: () => _openDailyChallenge(context),
                    onOpenDiagnosticChooser: () =>
                        showDiagnosticSubjectChooser(context),
                    onOpenSubject: (subject) => _openSubject(context, subject),
                    onOpenChapterDrill: (subject, chapter) =>
                        _openChapterDrill(context, subject, chapter),
                  ),
                  const SizedBox(height: 28),

                  // ── Your Progress card ─────────────────────────────────
                  _ProgressCard(palette: palette, data: data),
                  const SizedBox(height: 28),

                  // ── Continue Learning row ─────────────────────────────
                  const _SectionTitle("Continue Learning"),
                  const SizedBox(height: 12),
                  // A-10: the two action cards cascade in from the left.
                  StaggeredEntrance(
                    axis: Axis.horizontal,
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

                  // ── Subjects row (B-4: "See all" removed — the three
                  // subject tiles below are already the full set) ──────────
                  const _SectionTitle("Subjects"),
                  const SizedBox(height: 8),
                  // A-10: subject tiles cascade in, left to right.
                  StaggeredEntrance(
                    axis: Axis.horizontal,
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
                ],
              ),
            );
              },
            );
          },
        ),
      ),
    );
      },
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

  /// R-6: chapter-focused drill from the weak-chapter recommendation —
  /// opens QuestionScreen with the optional chapter filter (R-5).
  void _openChapterDrill(
    BuildContext context,
    String subject,
    String chapter,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          subject: subject,
          chapter: chapter,
          questionCount: 10,
        ),
      ),
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
// R-6: "Recommended for you" — the tutoring engine's front door
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal carousel of the engine's top picks. Every card routes to a
/// real destination (no dead buttons): drills open a chapter-focused
/// session, the daily opens the challenge, the nudge opens the
/// diagnostic chooser, the rest land in the Practice Hub / setup.
class _RecommendationSection extends StatelessWidget {
  final List<StudyRecommendation> recommendations;
  final VoidCallback onOpenPractice;
  final VoidCallback onOpenDailyChallenge;
  final VoidCallback onOpenDiagnosticChooser;
  final void Function(String subject) onOpenSubject;
  final void Function(String subject, String chapter) onOpenChapterDrill;

  const _RecommendationSection({
    required this.recommendations,
    required this.onOpenPractice,
    required this.onOpenDailyChallenge,
    required this.onOpenDiagnosticChooser,
    required this.onOpenSubject,
    required this.onOpenChapterDrill,
  });

  void _open(BuildContext context, StudyRecommendation rec) {
    switch (rec.kind) {
      case RecommendationKind.weakChapterDrill:
        if (rec.subject != null && rec.chapter != null) {
          onOpenChapterDrill(rec.subject!, rec.chapter!);
        } else {
          onOpenPractice();
        }
        break;
      case RecommendationKind.dailyChallenge:
        onOpenDailyChallenge();
        break;
      case RecommendationKind.diagnosticNudge:
        onOpenDiagnosticChooser();
        break;
      case RecommendationKind.streakKeeper:
      case RecommendationKind.mistakeReview:
        onOpenPractice();
        break;
      case RecommendationKind.momentum:
        if (rec.subject != null) {
          onOpenSubject(rec.subject!);
        } else {
          onOpenPractice();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Recommended for you'),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return _RecommendationCard(
                recommendation: rec,
                onTap: () => _open(context, rec),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final StudyRecommendation recommendation;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  (IconData, Color, String) _visuals(ColorScheme scheme, ColorPalette palette) {
    switch (recommendation.kind) {
      case RecommendationKind.streakKeeper:
        return (
          Icons.local_fire_department_rounded,
          const Color(0xFFFF8A00),
          'STREAK',
        );
      case RecommendationKind.dailyChallenge:
        return (Icons.bolt_rounded, const Color(0xFFFFC300), 'DAILY');
      case RecommendationKind.diagnosticNudge:
        return (
          Icons.troubleshoot_rounded,
          const Color(0xFF8B5CF6),
          'CHECK-UP',
        );
      case RecommendationKind.weakChapterDrill:
        return (Icons.build_circle_rounded, AppColors.error, 'WEAK SPOT');
      case RecommendationKind.mistakeReview:
        return (
          Icons.history_edu_rounded,
          scheme.onSurfaceVariant,
          'REVIEW',
        );
      case RecommendationKind.momentum:
        return (Icons.rocket_launch_rounded, palette.primary, 'MOMENTUM');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = ColorPaletteController.instance.current;
    final (icon, accent, chipLabel) = _visuals(scheme, palette);

    return Material(
      key: const ValueKey('recommendation_card'),
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),
                  const Spacer(),
                  Text(
                    chipLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                recommendation.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  height: 1.25,
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
    // The ENTIRE card is tappable → Analytics tab (same destination as the
    // "Deep Analytics" link, which stays as a visual affordance). The card
    // color lives on the Material (not the Container) so the InkWell ripple
    // renders above it and the pressed state is visible.
    return Material(
      color: palette.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => MainNavScreen.switchTab(context, 2), // Analytics tab
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
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
                    CountUp(
                      value: data.xpPoints,
                      suffix: " XP · ${data.tier}",
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
                  countUpValue: totalQuestions,
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
                  countUpValue: accuracy,
                  countUpSuffix: "%",
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
                      ? "Start practicing to build your streak"
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
                onTap: () => MainNavScreen.switchTab(context, 2), // Analytics tab (was 3 before leaderboard removal)
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
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String value;
  final String label;

  /// A-10: when set, the number lands with a count-up instead of appearing.
  final int? countUpValue;
  final String countUpSuffix;

  const _ProgressStat({
    required this.value,
    required this.label,
    this.countUpValue,
    this.countUpSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final numberStyle = TextStyle(
      color: AppColors.textOnPrimary,
      fontSize: 21,
      fontWeight: FontWeight.w800,
    );
    return Column(
      children: [
        if (countUpValue != null)
          CountUp(
            value: countUpValue!,
            suffix: countUpSuffix,
            style: numberStyle,
          )
        else
          Text(
            value,
            style: numberStyle,
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
                // B-3: spaceBetween (not a Spacer) — a Spacer competes with
                // the Flexible badge for flex space 50/50, starving the green
                // pill and ellipsizing its text even when the card has room.
                // With spaceBetween the badge sizes to its content (up to the
                // full leftover width) and only shrinks when truly tight.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
