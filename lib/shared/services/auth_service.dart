import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  /// App-wide singleton. Tests can swap the underlying [FirebaseAuth]
  /// via [AuthService.forTesting] to inject a [MockFirebaseAuth] (or any
  /// other fake) so the widget tree under test doesn't reach for the
  /// real Firebase default app.
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService();

  /// Reset to a real-Firebase-backed instance. Called from `main()`
  /// after `Firebase.initializeApp`.
  static void resetForProduction() {
    _instance = AuthService();
  }

  /// Test-only entry point: build an [AuthService] backed by the given
  /// [FirebaseAuth] (typically a `MockFirebaseAuth`) without going
  /// through `FirebaseAuth.instance`.
  factory AuthService.forTesting(FirebaseAuth auth) = AuthService._;

  final FirebaseAuth Function() _authFactory;
  FirebaseAuth? _authCached;

  /// Resolve the underlying [FirebaseAuth] lazily so constructing an
  /// [AuthService] doesn't crash in widget tests where Firebase has
  /// not been initialized. The first real auth call still needs
  /// `Firebase.initializeApp` to have run.
  FirebaseAuth get _auth => _authCached ??= _authFactory();

  AuthService() : _authFactory = _defaultFactory;
  AuthService._(FirebaseAuth auth) : _authFactory = (() => auth);

  static FirebaseAuth _defaultFactory() => FirebaseAuth.instance;

  // Create account
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Current user
  User? get currentUser => _auth.currentUser;
}
