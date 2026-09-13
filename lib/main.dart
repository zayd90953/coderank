import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/theme/color_palette.dart';
import 'firebase_options.dart';
import 'shared/services/user_preferences_service.dart';
import 'shared/services/user_progress_service.dart';
import 'shared/services/weak_area_tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await UserProgressService.instance.initialize();
  // R-3: load per-chapter mastery tracking before the first frame so the
  // recommendation-first home (R-6) and analytics read real state.
  await WeakAreaTrackingService.instance.initialize();
  await UserPreferencesService.instance.initialize();
  // Make the active color palette reflect the persisted choice before
  // the first frame so the app boots in the user's selected color.
  ColorPaletteController.instance.hydrateFromPrefs();
  runApp(const CodeRankApp());
}