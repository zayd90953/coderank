import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.text,
        ),
        title: Text(
          '${widget.subject} Practice',
          style: const TextStyle(
            color: AppColors.text,
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
            const Text(
              'Set up your practice',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Choose how you want to practice ${widget.subject}.',
              style: TextStyle(
                color: AppColors.subtitle,
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
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your practice',
                          style: TextStyle(
                            color: AppColors.text,
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
                            color: AppColors.subtitle,
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
                  Navigator.pushReplacement(
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
                  backgroundColor: AppColors.primary,
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
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 21,
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
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
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : const Color(0xFFE7E3F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.primary
                : AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}