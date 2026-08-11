import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import 'auth_gate.dart';
import 'theme.dart';

class CodeRankApp extends StatelessWidget {
  const CodeRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeRank',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}