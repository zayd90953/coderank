import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a question figure for every runner (practice, mock, daily,
/// diagnostic).
///
/// [diagramId] is the asset basename without extension (the QuestionModel
/// convention). The bundled folder may hold either an SVG (the merged
/// demo bank, e.g. `D0001.svg`) or a PNG (legacy bank convention) for the
/// same id, so SVG is tried first, then PNG, then a soft "figure
/// unavailable" box — a missing asset must never crash a live question.
///
/// The SVGs carry their own white rounded card, so they work on both light
/// and dark backgrounds without tinting.
class QuestionDiagram extends StatelessWidget {
  final String? diagramId;

  const QuestionDiagram({super.key, required this.diagramId});

  @override
  Widget build(BuildContext context) {
    if (diagramId == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainer,
        padding: const EdgeInsets.all(12),
        child: SvgPicture.asset(
          'assets/practice/diagrams/$diagramId.svg',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Image.asset(
            'assets/practice/diagrams/$diagramId.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Figure unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
