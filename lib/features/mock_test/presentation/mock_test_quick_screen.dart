import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../../features/practice/data/question_repository.dart';
import 'mock_test_format_widgets.dart';
import 'mock_test_question_screen.dart';

/// Landing / setup screen for a **Quick Timed Mock Test**.
///
/// This is a shorter 45-question exam (15 Qs per subject, 2 hours) compared
/// to the Full NEET Paper (180 Qs, 3 hours). A perfect warm-up or last-minute
/// revision mode.
class MockTestQuickScreen extends StatefulWidget {
  const MockTestQuickScreen({super.key});

  @override
  State<MockTestQuickScreen> createState() => _MockTestQuickScreenState();
}

class _MockTestQuickScreenState extends State<MockTestQuickScreen> {
  bool _isLoading = false;
  String? _error;

  static const int _quickQuestionCount = 45; // 15 per subject
  static const int _quickDurationSeconds = 7200; // 2 hours

  Future<void> _startQuickExam() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = QuestionRepository();
      final questions = await repo.getMockTestQuestions(
        physicsCount: 15,
        chemCount: 15,
        bioCount: 15,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MockTestQuestionScreen(
            questions: questions,
            durationSeconds: _quickDurationSeconds,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: const Text(
          'Quick Mock Test',
          style: TextStyle(
            color: AppColors.textPrimary,
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
            // Hero: Quick Mock Test branding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                // A-4: Quick test gets a warm orange "warm-up" feel so it
                // doesn't look identical to the Full-Length indigo card.
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8A3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.32),
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
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.surface,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Quick Mock Test',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_quickQuestionCount Questions • 2 Hours',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.surface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // A-4: give Quick the same "Paper Format" breakdown as the
            // Full-Length test so the user can see the subject split and
            // marking scheme before they start. Mirrors the cards on
            // mock_test_screen.dart.
            const SectionLabel(label: 'Paper Format'),
            const SizedBox(height: 10),
            const FormatCard(
              color: AppColors.physics,
              subject: 'Physics',
              questions: 15,
              marks: 60,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 10),
            const FormatCard(
              color: AppColors.chemistry,
              subject: 'Chemistry',
              questions: 15,
              marks: 60,
              icon: Icons.science_rounded,
            ),
            const SizedBox(height: 10),
            const FormatCard(
              color: AppColors.biology,
              subject: 'Biology',
              questions: 15,
              marks: 60,
              icon: Icons.biotech_rounded,
            ),

            const SizedBox(height: 28),

            const SectionLabel(label: 'Marking Scheme'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  MarkRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    label: 'Correct answer',
                    mark: '+4',
                  ),
                  Divider(color: AppColors.border, height: 20),
                  MarkRow(
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    label: 'Wrong answer',
                    mark: '−1',
                  ),
                  Divider(color: AppColors.border, height: 20),
                  MarkRow(
                    icon: Icons.remove_circle_outline_rounded,
                    color: AppColors.textSecondary,
                    label: 'Unattempted',
                    mark: '0',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startQuickExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor:
                      const Color(0xFFFFB800).withValues(alpha: 0.5),
                  disabledForegroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                        '🚀  Start Quick Mock Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}