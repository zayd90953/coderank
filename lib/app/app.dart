import 'package:flutter/material.dart';
import '../core/theme/color_palette.dart';
import '../features/splash/splash_screen.dart';
import '../shared/services/user_preferences_service.dart';
import 'theme.dart';

class CodeRankApp extends StatelessWidget {
  const CodeRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-tint the entire app on either prefs change (user picks a new
    // color in the picker, or first launch hydration) — both update
    // the [ColorPaletteController] notifier.
    return ListenableBuilder(
      listenable: ColorPaletteController.instance.paletteNotifier,
      builder: (context, _) {
        // Theme-mode is independent of the brand color. We still need to
        // listen to prefs for it.
        return ListenableBuilder(
          listenable: UserPreferencesService.instance.prefsNotifier,
          builder: (context, _) {
            final mode = UserPreferencesService.instance.current.themeMode;
            final palette = ColorPaletteController.instance.current;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'CodeRank',
              theme: AppTheme.buildLight(palette),
              darkTheme: AppTheme.buildDark(palette),
              themeMode: _toThemeMode(mode),
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }

  ThemeMode _toThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
