import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/exit_confirmation_scope.dart';
import '../../auth/presentation/signin_screen.dart';
import '../../navigation/main_nav_screen.dart';

/// Triggers the real Google Sign-In flow. On success navigates to
/// [MainNavScreen]. On the user cancelling the account picker, this
/// is a silent no-op. On any other error, shows an error dialog.
///
/// P1-2 wiring: replaces the previous "Coming Soon" placeholder. The
/// account picker is forced every time via
/// [GoogleSignIn.disconnect] inside [AuthService.signInWithGoogle]
/// (see AuthService for why).
Future<void> _signInWithGoogle(BuildContext context) async {
  try {
    await AuthService.instance.signInWithGoogle();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (route) => false,
    );
  } on GoogleSignInCancelled {
    // User dismissed the picker — silent no-op.
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    await _showGoogleErrorDialog(
      context,
      _googleErrorMessage(e),
    );
  } catch (e) {
    if (!context.mounted) return;
    await _showGoogleErrorDialog(
      context,
      "Google sign-in failed. Please try again.",
    );
  }
}

String _googleErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'account-exists-with-different-credential':
      return "An account already exists with this email using a different sign-in method. Please use email and password instead.";
    case 'invalid-credential':
    case 'invalid-verification-code':
    case 'invalid-verification-id':
      return "Google sign-in failed because the credential is invalid. Please try again.";
    case 'network-request-failed':
      return "Network error. Please check your connection and try again.";
    case 'operation-not-allowed':
      return "Google sign-in is not enabled for this project. Please contact support.";
    default:
      return "Google sign-in failed. Please try again.";
  }
}

Future<void> _showGoogleErrorDialog(
    BuildContext context, String message) async {
  final palette = ColorPaletteController.instance.current;
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
  final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
  final schemeError = Theme.of(context).colorScheme.error;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: schemeError, size: 24),
          const SizedBox(width: 10),
          Text(
            "Sign-In Failed",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
            fontSize: 14, color: onSurfaceVariant, height: 1.4),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "OK",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

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
