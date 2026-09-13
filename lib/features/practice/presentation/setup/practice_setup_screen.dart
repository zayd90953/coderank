import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '../../../../shared/widgets/back_button_to_home.dart';
import '../../../../shared/widgets/subject_icon_badge.dart';
import '../question/question_screen.dart';

/// A-7: Practice setup — purpose first, parameters second.
///
/// The old flow presented three same-looking chip groups (count /
/// difficulty / time-per-question) and a summary card that restated
/// them — a form to fill out before every session. The redesigned flow
/// leads with three [PracticeGoal] presets that cover the common
/// intents (quick revision, exam drill, untimed deep dive); the
/// parameter chips move into an opt-in "Fine-tune" panel for custom
/// sessions. Every old capability is kept: the same chip options, the
/// saved Practice Defaults hydration, and the live summary preview.
class PracticeSetupScreen extends StatefulWidget {
  final String subject;

  const PracticeSetupScreen({
    super.key,
    required this.subject,
  });

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

/// A-7: a named intent that expands to concrete session parameters.
class PracticeGoal {
  final String title;
  final String subtitle;
  final IconData icon;
  final int questions;
  final String difficulty;
  final int? timePerQuestion;

  const PracticeGoal({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.questions,
    required this.difficulty,
    required this.timePerQuestion,
  });
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  // ── Session parameters (source of truth passed to QuestionScreen) ──
  int selectedQuestions = 10;
  String selectedDifficulty = 'Mixed';
  int? selectedTime = 60;

  // A-7: which goal card is selected; null = custom (fine-tuned) setup.
  int? selectedGoal;

  // A-7: whether the fine-tune panel is expanded.
  bool fineTuneOpen = false;

  final List<int> questionCounts = [10, 20, 50, 100];
  final List<String> difficulties = [
    'Easy',
    'Medium',
    'Hard',
    'Mixed',
  ];
  final List<int?> timeOptions = [30, 60, 90, null];

  /// A-7: the three presets shown as goal cards. All parameter values
  /// come from the existing option vocabulary — a goal simply picks a
  /// coherent combination so the user doesn't have to.
  static const List<PracticeGoal> goals = [
    PracticeGoal(
      title: 'Quick Revision',
      subtitle: 'A short, sharp warm-up',
      icon: Icons.bolt_rounded,
      questions: 10,
      difficulty: 'Mixed',
      timePerQuestion: 60,
    ),
    PracticeGoal(
      title: 'Exam Drill',
      subtitle: 'A hard, timed grind',
      icon: Icons.fitness_center_rounded,
      questions: 50,
      difficulty: 'Hard',
      timePerQuestion: 60,
    ),
    PracticeGoal(
      title: 'Deep Dive',
      subtitle: 'Untimed concept building',
      icon: Icons.psychology_rounded,
      questions: 20,
      difficulty: 'Medium',
      timePerQuestion: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Hydrate the chips from the user's saved Practice Defaults
    // (Profile → App → Practice Defaults). If the saved values exactly
    // match a goal preset, that goal is preselected; otherwise the
    // screen opens in custom mode with the fine-tune panel expanded so
    // the effective setup is visible.
    final defaults = UserPreferencesService.instance.current;
    selectedQuestions = defaults.practiceQuestionCount;
    selectedTime = defaults.practiceSecondsPerQuestion;

    final match = goals.indexWhere(
      (g) =>
          g.questions == selectedQuestions &&
          g.difficulty == selectedDifficulty &&
          g.timePerQuestion == selectedTime,
    );
    if (match != -1) {
      selectedGoal = match;
    } else {
      fineTuneOpen = true;
    }
  }

  void _applyGoal(int index) {
    final goal = goals[index];
    setState(() {
      selectedGoal = index;
      selectedQuestions = goal.questions;
      selectedDifficulty = goal.difficulty;
      selectedTime = goal.timePerQuestion;
    });
  }

  void _customize() {
    // Any manual chip tap switches to custom mode (goal deselects).
    if (selectedGoal != null) {
      setState(() => selectedGoal = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          '${widget.subject} Practice',
          style: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unified subject badge — same visual system as the Home
            // grid and the Practice Hub cards (A-6 follow-up).
            SubjectIconBadge(subject: widget.subject, size: 48),
            const SizedBox(height: 16),

            Text(
              'What do you feel like?',
              style: TextStyle(
                color: onSurface,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Pick a goal — or fine-tune your own set.',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // ── A-7: goal cards — the primary interaction ──────────
            ...List.generate(goals.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GoalCard(
                  goal: goals[i],
                  selected: selectedGoal == i,
                  onTap: () => _applyGoal(i),
                ),
              );
            }),

            const SizedBox(height: 12),

            // ── A-7: opt-in fine-tune panel (all original options) ──
            _FineTunePanel(
              open: fineTuneOpen,
              onToggle: () => setState(() => fineTuneOpen = !fineTuneOpen),
              questionCounts: questionCounts,
              difficulties: difficulties,
              timeOptions: timeOptions,
              selectedQuestions: selectedQuestions,
              selectedDifficulty: selectedDifficulty,
              selectedTime: selectedTime,
              onQuestions: (v) => setState(() {
                selectedQuestions = v;
                _customize();
              }),
              onDifficulty: (v) => setState(() {
                selectedDifficulty = v;
                _customize();
              }),
              onTime: (v) => setState(() {
                selectedTime = v;
                _customize();
              }),
            ),

            const SizedBox(height: 24),

            // Live summary — especially useful in custom mode, where a
            // saved default may not match any chip.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: palette.primary,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your practice',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$selectedQuestions questions • '
                              '$selectedDifficulty • '
                              '${selectedTime == null ? 'No time limit' : '$selectedTime sec/question'}',
                          style: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // P4-REGRESSION #3: use push (not pushReplacement) so the
                  // device back gesture pops to setup instead of exiting the
                  // app (setup itself has its own back path).
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionScreen(
                        subject: widget.subject,
                        questionCount: selectedQuestions,
                        difficulty: selectedDifficulty,
                        timeLimit: selectedTime,
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
                  'Start Practice',
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
    );
  }
}

// ── A-7 widgets ─────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final PracticeGoal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;

    final facts =
        '${goal.questions} Qs • ${goal.difficulty} • ${goal.timePerQuestion == null ? 'No limit' : '${goal.timePerQuestion}s/Q'}';

    return Material(
      color: selected
          ? palette.primary.withValues(alpha: 0.10)
          : surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.primary : outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? palette.primary.withValues(alpha: 0.14)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  goal.icon,
                  size: 22,
                  color: selected ? palette.primary : onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$facts — ${goal.subtitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? palette.primary : outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FineTunePanel extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  final List<int> questionCounts;
  final List<String> difficulties;
  final List<int?> timeOptions;
  final int selectedQuestions;
  final String selectedDifficulty;
  final int? selectedTime;
  final ValueChanged<int> onQuestions;
  final ValueChanged<String> onDifficulty;
  final ValueChanged<int?> onTime;

  const _FineTunePanel({
    required this.open,
    required this.onToggle,
    required this.questionCounts,
    required this.difficulties,
    required this.timeOptions,
    required this.selectedQuestions,
    required this.selectedDifficulty,
    required this.selectedTime,
    required this.onQuestions,
    required this.onDifficulty,
    required this.onTime,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outline),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Fine-tune your set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // AnimatedCrossFade instead of ExpansionTile so the panel
          // inherits no Material tile theming surprises in dark mode.
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOut,
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.quiz_rounded,
                    title: 'Number of questions',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: questionCounts.map((count) {
                      final selected = selectedQuestions == count;
                      return _ChoiceChip(
                        label: '$count',
                        selected: selected,
                        onTap: () => onQuestions(count),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.speed_rounded,
                    title: 'Difficulty',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: difficulties.map((difficulty) {
                      final selected = selectedDifficulty == difficulty;
                      return _ChoiceChip(
                        label: difficulty,
                        selected: selected,
                        onTap: () => onDifficulty(difficulty),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.timer_rounded,
                    title: 'Time per question',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: timeOptions.map((time) {
                      final selected = selectedTime == time;
                      return _ChoiceChip(
                        label: time == null ? 'No limit' : '$time sec',
                        selected: selected,
                        onTap: () => onTime(time),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(
          icon,
          color: palette.primary,
          size: 21,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceContainerHighest = Theme.of(context).colorScheme.surfaceContainerHighest;
    final outline = Theme.of(context).colorScheme.outline;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? palette.primary.withValues(alpha: 0.10)
              : surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? palette.primary
                : outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? palette.primary
                : onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
