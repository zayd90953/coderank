import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../features/practice/data/question_repository.dart';
import '../../../features/practice/models/question_model.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.text,
        ),
        title: const Text(
          'Full-Length Mock Test',
          style: TextStyle(
            color: AppColors.text,
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
            const _SectionLabel(label: 'Paper Format'),
            const SizedBox(height: 10),

            _FormatCard(
              color: AppColors.physics,
              subject: 'Physics',
              questions: 45,
              marks: 180,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 10),
            _FormatCard(
              color: AppColors.chemistry,
              subject: 'Chemistry',
              questions: 45,
              marks: 180,
              icon: Icons.science_rounded,
            ),
            const SizedBox(height: 10),
            _FormatCard(
              color: AppColors.biology,
              subject: 'Biology',
              questions: 90,
              marks: 360,
              icon: Icons.biotech_rounded,
            ),

            const SizedBox(height: 28),

            // ── Marking scheme ──
            const _SectionLabel(label: 'Marking Scheme'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEDE8F5)),
              ),
              child: Column(
                children: [
                  _MarkRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    label: 'Correct answer',
                    mark: '+4',
                  ),
                  const Divider(color: Color(0xFFF0ECF8), height: 20),
                  _MarkRow(
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    label: 'Wrong answer',
                    mark: '−1',
                  ),
                  const Divider(color: Color(0xFFF0ECF8), height: 20),
                  _MarkRow(
                    icon: Icons.remove_circle_outline_rounded,
                    color: AppColors.subtitle,
                    label: 'Unattempted',
                    mark: '0',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Rules ──
            const _SectionLabel(label: 'Exam Rules'),
            const SizedBox(height: 10),
            _RuleCard(
              rules: const [
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
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
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
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black54,
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

// ── Private helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.subtitle,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final Color color;
  final String subject;
  final int questions;
  final int marks;
  final IconData icon;

  const _FormatCard({
    required this.color,
    required this.subject,
    required this.questions,
    required this.marks,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8F5)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text('$questions Questions',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.subtitle)),
              ],
            ),
          ),
          Text(
            '$marks Marks',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String mark;

  const _MarkRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.mark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.text))),
        Text(
          mark,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final List<String> rules;
  const _RuleCard({required this.rules});

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules
            .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.subtitle,
                                  height: 1.4))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
