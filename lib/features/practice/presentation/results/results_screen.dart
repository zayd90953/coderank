import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/utils/app_haptics.dart';
import '../../../../shared/widgets/back_button_to_home.dart';
import '../../models/practice_session.dart';
import '../question/question_screen.dart';
import '../practice_screen.dart';

class ResultsScreen extends StatelessWidget {
  final PracticeSession session;

  /// XP earned from this session as reported by
  /// [UserProgressService.recordSession]. Shown as a reward chip when
  /// > 0 (regular practice previously showed nothing — progress was
  /// never recorded for this flow).
  final int xpEarned;

  /// A-9: non-null when this session promoted the user to a new tier —
  /// a full-screen celebration plays before the stats are revealed.
  final String? tierUp;

  /// The setup the session was started with, echoed back into
  /// "Practice Again" so the retry reruns the same configuration
  /// (count / difficulty / time limit) instead of falling back to
  /// the bare 10-question defaults.
  final int questionCount;
  final String difficulty;
  final int? timeLimit;

  /// R-8: how many answered questions blew past 1.5x their expected
  /// pace. Zero/null renders nothing — only a meaningful pattern (2+)
  /// earns a gentle nudge on the results screen.
  final int? slowAnswerCount;

  const ResultsScreen({
    super.key,
    required this.session,
    this.xpEarned = 0,
    this.tierUp,
    this.questionCount = 10,
    this.difficulty = 'Mixed',
    this.timeLimit = 60,
    this.slowAnswerCount,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = session.accuracy.round();
    final palette = ColorPaletteController.instance.current;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          "Results",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // A-9: Stack so the tier-up celebration can cover the stats.
      body: Stack(
        children: [
          SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // A-9: trophy pops in with a spring.
              _PopsIn(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: palette.primary,
                    size: 44,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // A-9: headline fades up after the trophy lands.
              _FadesUp(
                delay: const Duration(milliseconds: 250),
                child: Text(
                  "Practice Complete!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Great work! Here's how you performed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              // R-8: gentle pacing nudge when slow answers form a pattern.
              if ((slowAnswerCount ?? 0) >= 2) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "$slowAnswerCount answers took longer than expected — try pacing yourself.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 30),

              if (xpEarned > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: palette.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+$xpEarned XP earned",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      session.subject,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${session.correctAnswers} / ${session.totalQuestions}",
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Score",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.check_circle_rounded,
                            value: "${session.correctAnswers}",
                            label: "Correct",
                            iconColor: AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.cancel_rounded,
                            value: "${session.incorrectAnswers}",
                            label: "Incorrect",
                            iconColor: AppColors.error,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.percent_rounded,
                            value: "$percentage%",
                            label: "Accuracy",
                            iconColor: palette.primary,
                          ),
                        ),
                      ],
                    ),

                    if (session.unansweredQuestions > 0) ...[
                      const SizedBox(height: 20),
                      _StatItem(
                        icon: Icons.hourglass_empty_rounded,
                        value: "${session.unansweredQuestions}",
                        label: "Unanswered",
                        iconColor: AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // P4-REGRESSION #3: use push (not pushReplacement) so
                    // device back has a route to pop to.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestionScreen(
                          subject: session.subject,
                          questionCount: questionCount,
                          difficulty: difficulty,
                          timeLimit: timeLimit,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Practice Again",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PracticeScreen(),
                      ),
                          (route) => route.isFirst,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primary,
                    side: BorderSide(
                      color: palette.primary,
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Back to Practice",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
          ),

          // A-9: tier-up celebration — covers the stats until dismissed.
          if (tierUp != null) _TierUpOverlay(tier: tierUp!),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── A-9 micro-interaction widgets ──────────────────────────────────────

/// A-9: pops its child in with a spring (trophy on the results screen).
class _PopsIn extends StatefulWidget {
  final Widget child;

  const _PopsIn({required this.child});

  @override
  State<_PopsIn> createState() => _PopsInState();
}

class _PopsInState extends State<_PopsIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    // A-10: the reward moment gets a physical beat, in sync with the pop.
    AppHaptics.celebrate();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      ),
      child: widget.child,
    );
  }
}

/// A-9: fades its child up into place after an optional delay.
class _FadesUp extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadesUp({required this.child, this.delay = Duration.zero});

  @override
  State<_FadesUp> createState() => _FadesUpState();
}

class _FadesUpState extends State<_FadesUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// A-9: full-screen tier-up moment — brand-gradient badge, the new tier
/// in huge type, one "Keep going" action. Covers the results until used.
class _TierUpOverlay extends StatefulWidget {
  final String tier;

  const _TierUpOverlay({required this.tier});

  @override
  State<_TierUpOverlay> createState() => _TierUpOverlayState();
}

class _TierUpOverlayState extends State<_TierUpOverlay>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final palette = ColorPaletteController.instance.current;
    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.3, end: 1.0).animate(
                CurvedAnimation(parent: _c, curve: Curves.elasticOut),
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: palette.heroCardGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'TIER UP!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.tier,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => setState(() => _dismissed = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 34,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Keep going',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}