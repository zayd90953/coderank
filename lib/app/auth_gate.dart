import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/color_palette.dart';
import '../features/welcome/presentation/welcome_screen.dart';
import '../features/navigation/main_nav_screen.dart';
import '../shared/services/user_progress_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // A-1 contract: dark-first. Match the splash so the auth
          // check never flashes a white screen.
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: ColorPaletteController.instance.current.primary,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // Keep the progress service aware of the authenticated UID so
          // future cloud-sync code can key reads/writes to this user.
          // A duplicate setUserId call on rebuild is harmless (idempotent).
          final uid = snapshot.data!.uid;
          if (UserProgressService.instance.userId != uid) {
            UserProgressService.instance.setUserId(uid);
          }

          // P4-REGRESSION #1: route to the shell (Home + bottom nav) instead
          // of the bare HomeScreen — otherwise the bottom nav, Rank tab, and
          // Analytics tab are unreachable after login.
          return const MainNavScreen();
        }

        // Signed out — clear the UID so future cloud-sync code stops
        // keying to a stale user.
        if (UserProgressService.instance.userId != null) {
          UserProgressService.instance.clearUserId();
        }

        return const WelcomeScreen();
      },
    );
  }
}