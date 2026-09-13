import 'package:flutter/material.dart';

import '../../../shared/widgets/subject_icon_badge.dart';
import 'diagnostic_intro_screen.dart';

/// R-4: subject chooser for the diagnostic flow — a small modal bottom
/// sheet listing the three subjects, pushing the intro screen for the
/// picked one. Kept deliberately lightweight; the heavier chrome in the
/// profile sheets exists for forms, this is a 3-option picker.
Future<void> showDiagnosticSubjectChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick a subject to check up on',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A ~15 minute mixed quiz across every chapter.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              for (final subject
                  in const ['Physics', 'Chemistry', 'Biology']) ...[
                _SubjectRow(
                  subject: subject,
                  scheme: scheme,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DiagnosticIntroScreen(subject: subject),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    'Not now',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}

class _SubjectRow extends StatelessWidget {
  final String subject;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _SubjectRow({
    required this.subject,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SubjectIconBadge(subject: subject, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
