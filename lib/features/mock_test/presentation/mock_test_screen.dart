import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../features/practice/data/question_repository.dart';
import '../../../features/practice/models/question_model.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import 'mock_test_format_widgets.dart';
import 'mock_test_question_screen.dart';

/// Landing / setup screen for the Full-Length NEET Mock Test.
///
/// Shows the paper format (180 Qs, 3 hrs, NEET marking) and lets the student
/// start the exam. Loads the question bank in the background before launching
/// the actual [MockTestQuestionScreen].
class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _startExam() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = QuestionRepository();
      final List<QuestionModel> questions = await repo.getMockTestQuestions(
        physicsCount: 45,
        chemCount: 45,
        bioCount: 90,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MockTestQuestionScreen(
            questions: questions,
            durationSeconds: 10800, // 3 hours
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load questions. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;
    final error = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          'Full-Length Mock Test',
          style: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.timer_rounded,
                      color: Color(0xFFFFD166),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'NEET Full Paper',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      // The hero sits on a fixed dark-indigo gradient —
                      // white text is correct in both light and dark mode.
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '180 Questions  •  3 Hours  •  720 Marks',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Format breakdown ──
            const SectionLabel(label: 'Paper Format'),
            const SizedBox(height: 10),

            const FormatCard(
              color: AppColors.physics,
              subject: 'Physics',
              questions: 45,
              marks: 180,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 10),
            const FormatCard(
              color: AppColors.chemistry,
              subject: 'Chemistry',
              questions: 45,
              marks: 180,
              icon: Icons.science_rounded,
            ),
            const SizedBox(height: 10),
            const FormatCard(
              color: AppColors.biology,
              subject: 'Biology',
              questions: 90,
              marks: 360,
              icon: Icons.biotech_rounded,
            ),

            const SizedBox(height: 28),

            // ── Marking scheme ──
            const SectionLabel(label: 'Marking Scheme'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outline),
              ),
              child: Column(
                children: [
                  MarkRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    label: 'Correct answer',
                    mark: '+4',
                  ),
                  Divider(color: outline, height: 20),
                  MarkRow(
                    icon: Icons.cancel_rounded,
                    color: error,
                    label: 'Wrong answer',
                    mark: '−1',
                  ),
                  Divider(color: outline, height: 20),
                  MarkRow(
                    icon: Icons.remove_circle_outline_rounded,
                    color: onSurfaceVariant,
                    label: 'Unattempted',
                    mark: '0',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Rules ──
            const SectionLabel(label: 'Exam Rules'),
            const SizedBox(height: 10),
            const RuleCard(
              rules: [
                'Once started, the timer cannot be paused.',
                'You can move between questions and change answers freely.',
                'Mark questions for review using the flag button.',
                'The exam auto-submits when 3 hours are up.',
                'Answers are NOT revealed during the exam — only in results.',
              ],
            ),

            const SizedBox(height: 32),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: error, fontSize: 13),
                ),
              ),

            // ── Start button ──
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor:
                      const Color(0xFFFFB800).withValues(alpha: 0.5),
                  disabledForegroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        '🚀  Start Full-Length Mock Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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

// Private helpers live in `mock_test_format_widgets.dart` so the
// Quick Mock Test landing screen can share them.
