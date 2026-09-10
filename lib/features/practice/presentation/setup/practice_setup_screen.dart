import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '../../../../shared/widgets/back_button_to_home.dart';
import '../question/question_screen.dart';

class PracticeSetupScreen extends StatefulWidget {
  final String subject;

  const PracticeSetupScreen({
    super.key,
    required this.subject,
  });

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  int selectedQuestions = 10;
  String selectedDifficulty = 'Mixed';
  int? selectedTime = 60;

  final List<int> questionCounts = [10, 20, 50, 100];
  final List<String> difficulties = [
    'Easy',
    'Medium',
    'Hard',
    'Mixed',
  ];
  final List<int?> timeOptions = [30, 60, 90, null];

  @override
  void initState() {
    super.initState();
    // Hydrate the chips from the user's saved Practice Defaults
    // (Profile → App → Practice Defaults). Those prefs were persisted
    // but never read before — the screen always opened at 10 Q / 60s.
    // If the saved count/seconds don't match a chip option, no chip is
    // preselected — the summary card still shows the effective choice.
    final defaults = UserPreferencesService.instance.current;
    selectedQuestions = defaults.practiceQuestionCount;
    selectedTime = defaults.practiceSecondsPerQuestion;
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
            Text(
              'Set up your practice',
              style: TextStyle(
                color: onSurface,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Choose how you want to practice ${widget.subject}.',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

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
                  onTap: () {
                    setState(() {
                      selectedQuestions = count;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

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
                  onTap: () {
                    setState(() {
                      selectedDifficulty = difficulty;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

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
                  onTap: () {
                    setState(() {
                      selectedTime = time;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

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
        Text(
          title,
          style: TextStyle(
            color: onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
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