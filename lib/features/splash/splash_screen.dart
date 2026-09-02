import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/auth_gate.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/theme/color_palette.dart';
import '../onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _onboardingCompletedKey =
      'onboarding_completed';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    _navigateFromSplash();
  }

  Future<void> _navigateFromSplash() async {
    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    final prefs =
    await SharedPreferences.getInstance();

    final onboardingCompleted =
        prefs.getBool(_onboardingCompletedKey) ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => onboardingCompleted
            ? const AuthGate()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the active brand color once. The splash is short-lived and
    // we don't expect a palette change to happen during it, so a direct
    // read is enough (no need to wire a ValueListenableBuilder here).
    final palette = ColorPaletteController.instance.current;
    return Scaffold(
      backgroundColor: palette.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: const Offset(0, -35),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/branding/splash_logo.png",
                  width: 300,
                ),

                const SizedBox(height: 16),

                Text(
                  "CodeRank",
                  style: AppTextStyles.title,
                ),

                const SizedBox(height: 6),

                Text(
                  "Practice. Improve. Rank Higher.",
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}