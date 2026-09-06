import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../features/welcome/presentation/welcome_screen.dart';
import '../features/navigation/main_nav_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // P4-REGRESSION #1: route to the shell (Home + bottom nav) instead
          // of the bare HomeScreen — otherwise the bottom nav, Rank tab, and
          // Analytics tab are unreachable after login.
          return const MainNavScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}