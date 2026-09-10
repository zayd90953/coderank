import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';

/// Shared UI bits used by both the Full-Length and the Quick mock test
/// landing screens. Extracted so neither screen has to fork the layout.
///
/// These are all small, dependency-free presentation widgets — they
/// just paint the same paper-format / marking-scheme / rules UI that
/// the two screens share.

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }
}

class FormatCard extends StatelessWidget {
  final Color color;
  final String subject;
  final int questions;
  final int marks;
  final IconData icon;

  const FormatCard({
    super.key,
    required this.color,
    required this.subject,
    required this.questions,
    required this.marks,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outline),
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
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$questions Questions',
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurfaceVariant,
                  ),
                ),
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

class MarkRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String mark;

  const MarkRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.mark,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: onSurface,
            ),
          ),
        ),
        Text(
          mark,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class RuleCard extends StatelessWidget {
  final List<String> rules;
  const RuleCard({super.key, required this.rules});

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•  ',
                      style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
