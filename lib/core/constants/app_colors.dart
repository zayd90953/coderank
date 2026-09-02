import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors — moved to ColorPalette (see core/theme/color_palette.dart).
  // The active brand color is user-switchable; read from ColorPaletteController.
  static const Color accent = Color(0xFFFF6B00);
  static const Color accentYellow = Color(0xFFFFB800);

  // Base Neutrals
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF8F7FD);
  static const Color cardSurface = Colors.white;
  static const Color border = Color(0xFFEDE8F5);
  static const Color borderLight = Color(0xFFF4F0FA);

  // Typography
  static const Color text = Color(0xFF191824);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Subject Palettes
  static const Color physics = Color(0xFF0284C7);
  static const Color physicsLight = Color(0xFFE0F2FE);
  static const Color chemistry = Color(0xFF059669);
  static const Color chemistryLight = Color(0xFFD1FAE5);
  static const Color biology = Color(0xFF8B5CF6);
  static const Color biologyLight = Color(0xFFEDE9FE);

  // Gradients
  // primaryGradient + heroCardGradient moved to ColorPalette (see core/theme/color_palette.dart).

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient physicsGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chemistryGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient biologyGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireStreakGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
