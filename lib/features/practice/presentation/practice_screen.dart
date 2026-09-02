import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import 'setup/practice_setup_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
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
        title: const Text(
          "Practice",
          style: TextStyle(
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
              "What do you want to practice?",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose a subject and start solving questions.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 28),

            // Physics
            _SubjectCard(
              icon: Icons.bolt_rounded,
              title: "Physics",
              subtitle: "Practice Physics questions",
              palette: palette,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PracticeSetupScreen(
                      subject: "Physics",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Chemistry
            _SubjectCard(
              icon: Icons.science_rounded,
              title: "Chemistry",
              subtitle: "Practice Chemistry questions",
              palette: palette,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PracticeSetupScreen(
                      subject: "Chemistry",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Biology
            _SubjectCard(
              icon: Icons.biotech_rounded,
              title: "Biology",
              subtitle: "Practice Biology questions",
              palette: palette,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PracticeSetupScreen(
                      subject: "Biology",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorPalette palette;

  const _SubjectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE7E3F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: palette.primary,
                size: 29,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: AppColors.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}