import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/onboarding_data.dart';
import '../../welcome/presentation/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _onboardingCompletedKey =
      'onboarding_completed';

  final PageController _pageController = PageController();

  int currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _onboardingCompletedKey,
      true,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = onboardingData[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                    ),
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Image.asset(
                            item.image,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 30),

                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Color(0xFF5F00FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Row(
                    children: List.generate(
                      onboardingData.length,
                          (index) => AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 250),
                        margin:
                        const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        width:
                        currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentPage == index
                              ? const Color(0xFF5F00FF)
                              : Colors.grey.shade300,
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF5F00FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 28,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (currentPage <
                            onboardingData.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(
                              milliseconds: 350,
                            ),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Text(
                        currentPage ==
                            onboardingData.length - 1
                            ? "Get Started"
                            : "Next",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}