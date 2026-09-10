import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import 'mock_test_quick_screen.dart';
import 'mock_test_screen.dart';

/// A-4: lightweight chooser between the two mock-test modes.
///
/// Routed to from the Home "Mock Test" card. The two modes share a
/// runner, results screen, and XP path — the only differences are
/// question count, duration, and the landing-screen framing. Showing
/// them side-by-side here keeps the Home card simple (one tap) while
/// still giving the user the choice of length.
class MockTestChooserScreen extends StatelessWidget {
  const MockTestChooserScreen({super.key});

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
          'Mock Test',
          style: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHOOSE A LENGTH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: onSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              palette: palette,
              gradientColors: const [Color(0xFF1E1B4B), Color(0xFF312E81)],
              shadowColor: const Color(0xFF1E1B4B),
              icon: Icons.timer_rounded,
              iconColor: const Color(0xFFFFD166),
              title: 'Full-Length Mock Test',
              subtitle:
                  '180 Questions  •  3 Hours  •  720 Marks\nThe real NEET exam, end to end.',
              badge: 'EXAM MODE',
              onTap: () => _openFull(context),
            ),
            const SizedBox(height: 14),
            _ModeCard(
              palette: palette,
              gradientColors: [Color(0xFFFF6B35), Color(0xFFFF8A3D)],
              shadowColor: const Color(0xFFFF6B35),
              icon: Icons.bolt_rounded,
              iconColor: Theme.of(context).colorScheme.surfaceContainer,
              title: 'Quick Mock Test',
              subtitle:
                  '45 Questions  •  2 Hours  •  180 Marks\nA fast warm-up or last-minute revision.',
              badge: 'WARM-UP',
              onTap: () => _openQuick(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openFull(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MockTestScreen()),
    );
  }

  void _openQuick(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MockTestQuickScreen()),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final ColorPalette palette;
  final List<Color> gradientColors;
  final Color shadowColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _ModeCard({
    required this.palette,
    required this.gradientColors,
    required this.shadowColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: outline),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: palette.primarySubtle,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceVariant,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Start',
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: palette.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
