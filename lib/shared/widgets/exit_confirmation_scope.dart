import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/app_colors.dart';
import '../../core/theme/color_palette.dart';

/// A [PopScope] wrapper that intercepts the device back gesture/button on
/// any screen that has no route to pop (auth flow, splash, etc.) and shows
/// a confirmation dialog before exiting the app.
///
/// Why this exists:
///   The app has several screens reached via the root navigator (Welcome,
///   SignIn, SignUp, ForgotPassword, Splash). Pressing the device back
///   button on any of them would otherwise exit the app silently. The
///   [MainNavScreen] already has its own exit dialog; this widget is the
///   equivalent for the rest of the app.
class ExitConfirmationScope extends StatelessWidget {
  final Widget child;

  const ExitConfirmationScope({super.key, required this.child});

  /// Show the exit confirmation dialog. Returns `true` if the user
  /// confirmed, `false` otherwise.
  static Future<bool> show(BuildContext context) async {
    final palette = ColorPaletteController.instance.current;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: palette.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              "Exit CodeRank?",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to close the app?",
          style: TextStyle(fontSize: 14, color: AppColors.subtitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.subtitle),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Exit",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (result == true) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await show(context);
      },
      child: child,
    );
  }
}
