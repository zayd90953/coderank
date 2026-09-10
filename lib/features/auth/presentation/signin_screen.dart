import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/exit_confirmation_scope.dart';
import 'signup_screen.dart';
import 'forgot_password.dart';
import '../../navigation/main_nav_screen.dart';

/// P1-2: real Google Sign-In from the sign-in screen. On success,
/// routes to [MainNavScreen]. On picker cancel, silent no-op. On any
/// other error, an error dialog.
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
    await _showGoogleErrorDialog(context, _googleErrorMessage(e));
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

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate fields
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email and password."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    try {
      // Sign in with Firebase
      await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // P4-REGRESSION #1: route to the shell so the bottom nav and other
      // tabs are present after sign-in.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String fieldMessage = "Something went wrong.";

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        fieldMessage = "Incorrect email or password.";
      } else if (e.code == 'invalid-email') {
        fieldMessage = "Please enter a valid email address.";
      } else if (e.code == 'user-disabled') {
        fieldMessage = "This account has been disabled.";
      }

      // Surface the error inline on the relevant field with a red border +
      // error text, instead of a grey SnackBar.
      setState(() {
        if (e.code == 'invalid-email') {
          _emailError = fieldMessage;
          _passwordError = null;
        } else {
          // For credential errors, mark both fields red so the user can
          // correct either; but most commonly the password is wrong, so
          // we surface the message under the password field.
          _emailError = null;
          _passwordError = fieldMessage;
        }
      });
    } catch (e) {
      if (!mounted) return;

      // Unknown error — fall back to a SnackBar so it isn't silently lost.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to sign in. Please try again."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 900;
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final surfaceContainerHighest =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final outline = Theme.of(context).colorScheme.outline;

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
                          color: onSurface,
                          size: compact ? 20 : 22,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 32),

                      // Branding
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/branding/logo_green.png",
                              width: compact ? 90 : 110,
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
                      SizedBox(height: compact ? 20 : 34),

                      // Heading
                      Center(
                        child: Text(
                          "Welcome Back!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 27 : 30,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          "Sign in to continue your\nCodeRank journey.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            color: onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 34),

                      // Email
                      Text(
                        "Email",
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        style: TextStyle(
                          color: onSurface,
                          fontSize: compact ? 14 : 15,
                        ),
                        decoration: InputDecoration(
                          errorText: _emailError,
                          hintText: "Enter your email",
                          hintStyle: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: compact ? 14 : 15,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: onSurfaceVariant,
                            size: compact ? 21 : 23,
                          ),
                          filled: true,
                          fillColor: surfaceContainerHighest,
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
                      SizedBox(height: compact ? 14 : 22),

                      // Password
                      Text(
                        "Password",
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        style: TextStyle(
                          color: onSurface,
                          fontSize: compact ? 14 : 15,
                        ),
                        decoration: InputDecoration(
                          errorText: _passwordError,
                          hintText: "Enter your password",
                          hintStyle: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: compact ? 14 : 15,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: onSurfaceVariant,
                            size: compact ? 21 : 23,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: onSurfaceVariant,
                              size: compact ? 21 : 23,
                            ),
                          ),
                          filled: true,
                          fillColor: surfaceContainerHighest,
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

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(
                              top: 6,
                              left: 8,
                              right: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: compact ? 12 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 26),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: compact ? 54 : 58,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            disabledBackgroundColor:
                            palette.primary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                              : Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: compact ? 16 : 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 28),

                      // OR divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: outline,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: onSurfaceVariant,
                                fontSize: compact ? 11 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: outline,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 18 : 28),

                      // Google button
                      SizedBox(
                        width: double.infinity,
                        height: compact ? 52 : 56,
                        child: OutlinedButton(
                          onPressed: () => _signInWithGoogle(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: outline,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/icons/google_logo.png",
                                width: compact ? 22 : 24,
                                height: compact ? 22 : 24,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  "Continue with Google",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: onSurface,
                                    fontSize: compact ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 24),

                      // Sign up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              "Don't have an account?",
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
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: palette.primary,
                                fontSize: compact ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 6 : 20),
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