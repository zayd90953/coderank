import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../features/navigation/main_nav_screen.dart';

/// A back button that pops the current route if possible, otherwise switches
/// the bottom-nav shell to the Home tab. Use as `AppBar.leading` in screens
/// that may be reached either as a pushed route or as a tab in
/// [MainNavScreen].
class BackButtonToHome extends StatelessWidget {
  final Color? color;

  const BackButtonToHome({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          // We are a root tab in MainNavScreen — switch to home.
          MainNavScreen.switchTab(context, 0);
        }
      },
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: color ?? AppColors.text,
    );
  }
}
