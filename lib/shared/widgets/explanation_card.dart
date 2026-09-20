import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../utils/numeric_display_formatter.dart';

/// R-7: the post-answer explanation card.
///
/// Upgrade over the old single colored text blob:
///   * A clear verdict header (Correct / Not quite / Time's up) instead of
///     the verdict being welded onto the front of the explanation text.
///   * The teacher-style explanation ("why the right answer is right").
///   * NEW — the misconception callout: when the question carries
///     schema-format `common_wrong_reasoning` (R-1) and the user picked a
///     wrong lettered option that has an entry, a distinct amber box
///     explains the likely thinking behind THAT wrong pick — teaching the
///     error, not just the fact. App-format questions (no tagging) simply
///     never show the callout.
class ExplanationCard extends StatelessWidget {
  /// The user's picked index; null means they timed out.
  final int? selectedOptionIndex;

  /// 0-based index of the right option.
  final int correctOptionIndex;

  /// Teacher-style explanation of the correct answer.
  final String explanation;

  /// Schema-format misconception map: option letter ("A"…"D") → sentence.
  /// Null/absent letters simply skip the callout.
  final Map<String, String>? commonWrongReasoning;

  const ExplanationCard({
    super.key,
    required this.selectedOptionIndex,
    required this.correctOptionIndex,
    required this.explanation,
    this.commonWrongReasoning,
  });

  bool get _isCorrect => selectedOptionIndex == correctOptionIndex;
  bool get _isTimeout => selectedOptionIndex == null;

  /// The letter of the user's wrong pick ("A"–"D"), or null.
  String? get _chosenWrongLetter {
    if (selectedOptionIndex == null || _isCorrect) return null;
    final index = selectedOptionIndex!;
    if (index < 0 || index > 25) return null;
    return String.fromCharCode(65 + index);
  }

  String? get _misconception {
    final letter = _chosenWrongLetter;
    if (letter == null || commonWrongReasoning == null) return null;
    return commonWrongReasoning![letter];
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = _isCorrect;
    final verdictColor = isCorrect ? AppColors.success : AppColors.error;
    final verdictText = isCorrect
        ? 'Correct'
        : _isTimeout
            ? "Time's up"
            : 'Not quite';

    final misconception = _misconception;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: verdictColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verdictColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Verdict header ──
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : _isTimeout
                        ? Icons.timer_off_rounded
                        : Icons.cancel_rounded,
                color: verdictColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                verdictText,
                style: TextStyle(
                  color: verdictColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Teacher explanation (why the right answer is right) ──
          Text(
            formatNumericDisplay(explanation),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),

          // ── R-7: the misconception callout ──
          if (misconception != null && misconception.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology_alt_rounded,
                        color: AppColors.warning,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'WHY $_chosenWrongLetter TEMPTS YOU',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    // Schema entries are third-person misconception
                    // phrases ("confuses mitosis with meiosis — ..."),
                    // so they're rendered as-is, no "You ..." prefix.
                    _misconception!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
