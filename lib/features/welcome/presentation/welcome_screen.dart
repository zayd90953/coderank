import 'package:flutter/material.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/widgets/exit_confirmation_scope.dart';
import '../../auth/presentation/google_sign_in_flow.dart';
import '../../auth/presentation/signin_screen.dart';

/// Delegates to the shared linking-aware Google flow (see
/// [signInWithGoogleFlow]): success → MainNavScreen, picker cancel →
/// silent no-op, `account-exists-with-different-credential` →
/// one-tap account linking.
Future<void> _signInWithGoogle(BuildContext context) =>
    signInWithGoogleFlow(context);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 900;
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: ExitConfirmationScope(
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
                        "assets/branding/logo_green.png",
                        width: compact ? 190 : 250,
                      ),

                      Text(
                        "CodeRank",
                        style: TextStyle(
                          fontSize: compact ? 26 : 30,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
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
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
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
                          fontSize: 14,
                          color: onSurfaceVariant,
                          height: 1.45,
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
                          onPressed: () => _signInWithGoogle(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
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
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
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
                              Flexible(
                                child: Text(
                                  "Continue with Google",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                            side: BorderSide(
                              color: palette.primary,
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
                                color: palette.primary,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  "Continue with Email",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontSize: compact ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                          Flexible(
                            child: Text(
                              "Already have an account?",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurfaceVariant,
                                fontSize: compact ? 12 : 14,
                              ),
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
                                color: palette.primary,
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
        ),
    );
  }
}
