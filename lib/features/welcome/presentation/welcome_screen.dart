import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/presentation/signin_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      // ─────────────────────────────
                      // TOP / LOGO
                      // ─────────────────────────────

                      SizedBox(height: compact ? 55 : 60),

                      Image.asset(
                        "assets/branding/logo_purple.png",
                        width: compact ? 190 : 250,
                      ),

                      Text(
                        "CodeRank",
                        style: TextStyle(
                          fontSize: compact ? 26 : 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),

                      // Space between brand and heading
                      SizedBox(height: compact ? 38 : 70),

                      // ─────────────────────────────
                      // HEADING
                      // ─────────────────────────────

                      Text(
                        "Your Journey to\nNEET Success Starts Here",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 27 : 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: compact ? 12 : 14),

                      // ─────────────────────────────
                      // SUBTITLE
                      // ─────────────────────────────

                      Text(
                        "Your AI-powered companion for NEET preparation.\nPractice smarter, analyze your performance,\nand rank higher.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          color: const Color(0xFF6B7280),
                          height: compact ? 1.45 : 1.6,
                        ),
                      ),

                      // Space before authentication buttons
                      SizedBox(height: compact ? 32 : 70),

                      // ─────────────────────────────
                      // GOOGLE BUTTON
                      // ─────────────────────────────

                      SizedBox(
                        width: double.infinity,
                        height: compact ? 56 : 60,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: compact ? 36 : 39,
                                height: compact ? 36 : 39,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    "assets/icons/google_logo.png",
                                    width: compact ? 25 : 27,
                                    height: compact ? 25 : 27,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  fontSize: compact ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: compact ? 16 : 30),

                      // ─────────────────────────────
                      // EMAIL BUTTON
                      // ─────────────────────────────

                      SizedBox(
                        width: double.infinity,
                        height: compact ? 54 : 58,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: compact ? 25 : 28,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Continue with Email",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: compact ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: compact ? 10 : 28),

                      // ─────────────────────────────
                      // SIGN IN
                      // ─────────────────────────────

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: compact ? 12 : 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: compact ? 12 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: compact ? 10 : 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}