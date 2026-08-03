import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.45,
          1.0,
          curve: Curves.easeIn,
        ),
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      // TODO:
      // Navigate to onboarding screen.
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.primary,

      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Transform.scale(
                  scale: _logoScale.value,
                  child: Image.asset(
                    "assets/branding/splash_logo.png",
                    width: 120,
                  ),
                ),

                const SizedBox(height: 28),

                Opacity(
                  opacity: _textOpacity.value,
                  child: Column(
                    children: [

                      Text(
                        "CodeRank",
                        style: AppTextStyles.title,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Practice. Improve. Rank Higher.",
                        style: AppTextStyles.subtitle,
                      ),

                    ],
                  ),
                ),

              ],
            );

          },
        ),
      ),
    );
  }
}