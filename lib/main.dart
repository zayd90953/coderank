import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/theme/color_palette.dart';
import 'firebase_options.dart';
import 'shared/services/user_preferences_service.dart';
import 'shared/services/user_progress_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await UserProgressService.instance.initialize();
  await UserPreferencesService.instance.initialize();
  // Make the active color palette reflect the persisted choice before
  // the first frame so the app boots in the user's selected color.
  ColorPaletteController.instance.hydrateFromPrefs();
  runApp(const CodeRankApp());
}