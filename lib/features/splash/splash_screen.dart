import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/auth_gate.dart';
import '../../core/theme/color_palette.dart';
import '../onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _onboardingCompletedKey =
      'onboarding_completed';

  // Entrance choreography (runs once, ~1.8s).
  late final AnimationController _controller;
  // Gentle bubble float (loops forever while the splash is up).
  late final AnimationController _floatController;

  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // Logo pops in with a playful bounce…
    _logoScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );

    // …then the wordmark slides up, then the tagline follows.
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
    );
    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
    );
    _taglineOffset = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
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
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the active brand color once. The splash is short-lived and
    // we don't expect a palette change to happen during it, so a direct
    // read is enough (no need to wire a ValueListenableBuilder here).
    final palette = ColorPaletteController.instance.current;
    final bgTop = palette.primary;
    final bgBottom = Color.lerp(palette.primary, Colors.black, 0.28)!;
    final float = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    );

    return Scaffold(
      backgroundColor: bgTop,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // ── Floating confetti bubbles ────────────────────────────
            _FloatingBubble(
              float: float,
              size: 90,
              left: 28,
              top: 90,
              opacity: 0.10,
            ),
            _FloatingBubble(
              float: float,
              size: 46,
              left: 74,
              top: 220,
              opacity: 0.14,
            ),
            _FloatingBubble(
              float: float,
              size: 120,
              left: 260,
              top: 130,
              opacity: 0.08,
            ),
            _FloatingBubble(
              float: float,
              size: 56,
              left: 300,
              top: 330,
              opacity: 0.12,
            ),
            _FloatingBubble(
              float: float,
              size: 34,
              left: 40,
              top: 420,
              opacity: 0.10,
            ),

            // ── Center stage ─────────────────────────────────────────
            Center(
              child: Transform.translate(
                offset: const Offset(0, -32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo bounces in.
                    ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        "assets/branding/splash_logo.png",
                        width: 250,
                      ),
                    ),
                    const SizedBox(height: 26),
                    // Wordmark.
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleOffset,
                        child: Text(
                          "CodeRank",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline.
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: SlideTransition(
                        position: _taglineOffset,
                        child: Text(
                          "Practice. Improve. Rank Higher.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tiny footer hint ─────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: FadeTransition(
                opacity: _taglineOpacity,
                child: Text(
                  "Let's make today count 🚀",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A translucent bubble that gently bobs up and down. Shares the splash's
/// single float controller so all bubbles drift in sync — calm and subtle.
class _FloatingBubble extends StatelessWidget {
  final Animation<double> float;
  final double size;
  final double left;
  final double top;
  final double opacity;

  const _FloatingBubble({
    required this.float,
    required this.size,
    required this.left,
    required this.top,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: float,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -22 * float.value),
          child: child,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}