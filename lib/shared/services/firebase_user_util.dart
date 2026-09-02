import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Returns the Firebase [User] for the default app, or `null` if Firebase has
/// not been initialized yet.
///
/// Screens should use this instead of `FirebaseAuth.instance.currentUser`
/// directly so they render a sensible default (no user) during early app
/// startup, widget tests, and screenshots/tooling that pump the widget tree
/// without `Firebase.initializeApp`. Falling back to `null` is safe: the
/// callers only use the user for optional display data (name/avatar).
User? firebaseCurrentUserOrNull() {
  if (!Firebase.apps.isNotEmpty) return null;
  try {
    return FirebaseAuth.instance.currentUser;
  } catch (_) {
    return null;
  }
}