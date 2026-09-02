import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password.dart';
import '../../home/presentation/home_screen.dart';

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
    });

    try {
      // Sign in with Firebase
      await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Return to AuthGate
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Something went wrong.";

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = "Incorrect email or password.";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email address.";
      } else if (e.code == 'user-disabled') {
        message = "This account has been disabled.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      SizedBox(height: compact ? 16 : 32),

                      // Branding
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/branding/logo_purple.png",
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
                            color: AppColors.text,
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
                            color: AppColors.subtitle,
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
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: compact ? 14 : 15,
                        ),
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
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF8F8FA),
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
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: compact ? 14 : 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your password",
                          hintStyle: TextStyle(
                            color: AppColors.subtitle.withValues(alpha: 0.7),
                            fontSize: compact ? 14 : 15,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.subtitle,
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
                              color: AppColors.subtitle,
                              size: compact ? 21 : 23,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF8F8FA),
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
                            foregroundColor: Colors.white,
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
                              color: Colors.white,
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
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: AppColors.subtitle,
                                fontSize: compact ? 11 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE5E7EB),
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
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
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
                                  color: AppColors.text,
                                  fontSize: compact ? 14 : 16,
                                  fontWeight: FontWeight.w600,
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
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: AppColors.subtitle,
                              fontSize: compact ? 12 : 14,
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
    );
  }
}