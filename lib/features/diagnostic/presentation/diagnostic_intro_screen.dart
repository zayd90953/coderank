import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../../../shared/services/weak_area_tracking_service.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../../shared/widgets/subject_icon_badge.dart';
import '../data/diagnostic_test_builder.dart';
import 'diagnostic_question_screen.dart';

/// R-4: diagnostic test — intro screen.
///
/// Explains what the diagnostic does, previews the coverage (chapter count
/// and question count), and hands off to the runner. Empty-bank edge case
/// renders a friendly dead-end rather than a broken flow.
class DiagnosticIntroScreen extends StatefulWidget {
  final String subject;

  const DiagnosticIntroScreen({super.key, required this.subject});

  @override
  State<DiagnosticIntroScreen> createState() => _DiagnosticIntroScreenState();
}

class _DiagnosticIntroScreenState extends State<DiagnosticIntroScreen> {
  bool _isLoading = true;
  int _chapterCount = 0;
  int _questionCount = 0;
  String? _lastDiagnosticDate;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    // Preview-only draw: deterministic seed so the counts are stable
    // across rebuilds; the runner does its own (unseeded) draw so a
    // retake sees different questions.
    final preview = await DiagnosticTestBuilder.buildSet(
      widget.subject,
      seed: 42,
    );
    if (!mounted) return;
    setState(() {
      _questionCount = preview.length;
      _chapterCount = preview.map((q) => q.chapter).toSet().length;
      _lastDiagnosticDate =
          WeakAreaTrackingService.instance.diagnosticDateFor(widget.subject);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = ColorPaletteController.instance.current;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          'Diagnostic Test',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SubjectIconBadge(subject: widget.subject, size: 84),
                    const SizedBox(height: 20),
                    Text(
                      '${widget.subject} Check-up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A short mixed quiz sweeping broadly across the chapters of ${widget.subject}, so CodeRank can map what you know and what needs work. Your accuracy stays private — only your chapter strengths are recorded.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              value: '$_questionCount',
                              label: 'Questions',
                              color: scheme.onSurface,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: scheme.outline,
                          ),
                          Expanded(
                            child: _Stat(
                              value: '$_chapterCount',
                              label: 'Chapters',
                              color: scheme.onSurface,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: scheme.outline,
                          ),
                          Expanded(
                            child: _Stat(
                              value: '~${(_questionCount * 0.75).round()}',
                              label: 'Minutes',
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_lastDiagnosticDate != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: palette.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last taken $_lastDiagnosticDate — retaking refreshes your map',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (_questionCount == 0)
                      Text(
                        'No questions available for this subject yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: palette.heroCardGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Start check-up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiagnosticQuestionScreen(
                                    subject: widget.subject,
                                  ),
                                ),
                              );
                            },
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
