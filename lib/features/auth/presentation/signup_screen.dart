import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';

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
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters.")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
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

      String message = "Something went wrong.";

      if (e.code == 'email-already-in-use') {
        message = "An account already exists with this email.";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email address.";
      } else if (e.code == 'weak-password') {
        message = "Please choose a stronger password.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                          color: AppColors.text,
                          size: compact ? 20 : 22,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 28),

                      // Branding
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/branding/logo_purple.png",
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
                            color: AppColors.text,
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
                            color: AppColors.subtitle,
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
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: "Enter your full name",
                          hintStyle: TextStyle(
                            color: AppColors.subtitle.withValues(alpha: 0.7),
                            fontSize: compact ? 14 : 15,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.subtitle,
                            size: compact ? 21 : 23,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8FA),
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
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: "Create a password",
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
                          fillColor: const Color(0xFFF8F8FA),
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
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Confirm your password",
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
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.subtitle,
                              size: compact ? 21 : 23,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8FA),
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
                      SizedBox(height: compact ? 18 : 26),

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
                      SizedBox(height: compact ? 12 : 20),

                      // Sign in
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: AppColors.subtitle,
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
    );
  }
}