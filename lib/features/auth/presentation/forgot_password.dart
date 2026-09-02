import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 900;
    final palette = ColorPaletteController.instance.current;

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      SizedBox(height: compact ? 8 : 20),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.text,
                          size: compact ? 20 : 22,
                        ),
                      ),
                      SizedBox(height: compact ? 28 : 45),

                      // Branding
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/branding/logo_purple.png",
                              width: compact ? 95 : 115,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "CodeRank",
                              style: TextStyle(
                                fontSize: compact ? 22 : 25,
                                fontWeight: FontWeight.bold,
                                color: palette.primary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 34 : 50),

                      // Heading
                      Center(
                        child: Text(
                          "Forgot Password?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 27 : 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Enter the email associated with your\nCodeRank account and we'll send you\na reset link.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            color: AppColors.subtitle,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 32 : 45),

                      // Email
                      Text(
                        "Email",
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          hintStyle: TextStyle(
                            color: AppColors.subtitle.withValues(alpha: 0.7),
                            fontSize: compact ? 14 : 15,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.subtitle,
                            size: compact ? 21 : 23,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8FA),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: compact ? 14 : 17,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: palette.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 24 : 32),

                      // Send reset link
                      SizedBox(
                        width: double.infinity,
                        height: compact ? 54 : 58,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Send Reset Link",
                            style: TextStyle(
                              fontSize: compact ? 16 : 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 28),

                      // Back to sign in
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: palette.primary,
                            size: compact ? 17 : 19,
                          ),
                          label: Text(
                            "Back to Sign In",
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: compact ? 13 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 20),
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