import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/exit_confirmation_scope.dart';
import '../../navigation/main_nav_screen.dart';

/// P1-2: real Google Sign-In from the sign-up screen. On success,
/// routes to [MainNavScreen] (same as email sign-in). On picker
/// cancel, silent no-op. On any other error, an error dialog.
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
      return "An account already exists with this email using a different sign-in method. Please sign in with email and password instead.";
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate fields
    setState(() {
      _nameError = name.isEmpty ? "Please enter your name." : null;
      _emailError = email.isEmpty ? "Please enter your email." : null;
      _passwordError = password.isEmpty
          ? "Please create a password."
          : (password.length < 6
              ? "Password must be at least 6 characters."
              : null);
      _confirmPasswordError = confirmPassword.isEmpty
          ? "Please confirm your password."
          : (password != confirmPassword
              ? "Passwords do not match."
              : null);
    });

    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create Firebase account
      await _authService.signUp(
        email: email,
        password: password,
      );

      // Save user's name
      final user = _authService.currentUser;
      await user?.updateDisplayName(name);
      await user?.reload();

      if (!mounted) return;
      // Return to AuthGate
      Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // Route server errors to the appropriate field's red border.
      setState(() {
        if (e.code == 'email-already-in-use') {
          _emailError = "An account already exists with this email.";
          _passwordError = null;
        } else if (e.code == 'invalid-email') {
          _emailError = "Please enter a valid email address.";
          _passwordError = null;
        } else if (e.code == 'weak-password') {
          _emailError = null;
          _passwordError = "Please choose a stronger password.";
        } else {
          _passwordError = "Something went wrong. Please try again.";
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to create account. Please try again."),
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      SizedBox(height: compact ? 8 : 20),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: onSurface,
                          size: compact ? 20 : 22,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 28),

                      // Branding
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/branding/logo_green.png",
                              width: compact ? 85 : 105,
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
                      SizedBox(height: compact ? 18 : 30),

                      // Heading
                      Center(
                        child: Text(
                          "Create Your Account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 26 : 30,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          "Join CodeRank and start your\njourney to NEET success.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            color: onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 30),

                      // Full name
                      Text(
                        "Full Name",
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                        style: TextStyle(color: onSurface),
                        decoration: InputDecoration(
                          errorText: _nameError,
                          hintText: "Enter your full name",
                          hintStyle: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: compact ? 14 : 15,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: onSurfaceVariant,
                            size: compact ? 21 : 23,
                          ),
                          filled: true,
                          fillColor: surfaceContainerHighest,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: compact ? 13 : 16,
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
                      SizedBox(height: compact ? 12 : 18),

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
                        style: TextStyle(color: onSurface),
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
                            vertical: compact ? 13 : 16,
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
                      SizedBox(height: compact ? 12 : 18),

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
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        style: TextStyle(color: onSurface),
                        decoration: InputDecoration(
                          errorText: _passwordError,
                          hintText: "Create a password",
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
                            vertical: compact ? 13 : 16,
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
                      SizedBox(height: compact ? 12 : 18),

                      // Confirm password
                      Text(
                        "Confirm Password",
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_confirmPasswordError != null) {
                            setState(() => _confirmPasswordError = null);
                          }
                        },
                        style: TextStyle(color: onSurface),
                        decoration: InputDecoration(
                          errorText: _confirmPasswordError,
                          hintText: "Confirm your password",
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
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
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
                            vertical: compact ? 13 : 16,
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
                      SizedBox(height: compact ? 16 : 24),

                      // Create account
                      SizedBox(
                        width: double.infinity,
                        height: compact ? 54 : 58,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createAccount,
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
                            "Create Account",
                            style: TextStyle(
                              fontSize: compact ? 16 : 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 26),

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
                      SizedBox(height: compact ? 18 : 26),

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
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: compact ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 20),

                      // Sign in
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: compact ? 12 : 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Sign In",
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