import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // ── Google Sign-In instance (P1-2) ───────────────────────────────────
  //
  // `google_sign_in` 6.x picks up the Android OAuth client from
  // `google-services.json` automatically — no serverClientId is required
  // on Android. If the project's `google-services.json` is missing the
  // OAuth client (an empty `oauth_client: []`), sign-in will throw
  // `PlatformException(sign_in_failed, ...)`.
  GoogleSignIn? _googleSignInCached;
  GoogleSignIn get _googleSignIn => _googleSignInCached ??= GoogleSignIn();

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

  // ── Google Sign-In (P1-2) ───────────────────────────────────────────
  //
  // Flow:
  //   1. `disconnect()` first — clears any cached account on this
  //      device so the Google account picker is shown every time.
  //      (signOut() only clears the auth session; the picker would
  //      silently reuse the last account otherwise.)
  //   2. `signIn()` — opens the picker, returns a `GoogleSignInAccount`.
  //   3. Build a Firebase `GoogleAuthProvider.credential` from the
  //      account's `idToken` and `accessToken`.
  //   4. Hand it to Firebase via `signInWithCredential`.
  //
  // If the chosen Google account maps to an email that already has an
  // email/password account, Firebase rejects with
  // `account-exists-with-different-credential`. The exception carries
  // both the email (`e.email`) and the pending Google credential
  // (`e.credential`) — the UI layer catches this and offers one-tap
  // linking via [linkGoogleToPasswordAccount], so the same email is ONE
  // account across both providers.
  Future<UserCredential> signInWithGoogle() async {
    // 1) Force the picker.
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // disconnect() throws if no user was previously signed in —
      // safe to ignore.
    }

    // 2) Trigger the picker.
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      // User cancelled the picker.
      throw const GoogleSignInCancelled();
    }

    // 3) Build the Firebase credential.
    final GoogleSignInAuthentication auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    // 4) Hand off to Firebase.
    return await _auth.signInWithCredential(credential);
  }

  /// Account linking: signs in to the existing email/password account
  /// and attaches the pending Google credential to it, so the same
  /// email is a single Firebase account usable via either provider.
  ///
  /// Called from the UI when [signInWithGoogle] fails with
  /// `account-exists-with-different-credential`. If the password is
  /// wrong, the underlying `signInWithEmailAndPassword` throws
  /// `wrong-password` / `invalid-credential` and the user can retry.
  /// If Google is already linked (edge case), the link step is skipped.
  Future<UserCredential> linkGoogleToPasswordAccount({
    required String email,
    required String password,
    required AuthCredential googleCredential,
  }) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = userCred.user;
    if (user != null &&
        !user.providerData.any((p) => p.providerId == 'google.com')) {
      await user.linkWithCredential(googleCredential);
    }
    return userCred;
  }

  // Sign out — covers both email/password and Google accounts.
  // For Google, also `signOut()` from the `google_sign_in` plugin so the
  // picker shows every other account on next sign-in. We deliberately do
  // NOT call `disconnect()` here because that would force re-consent
  // and clear the user's saved choice unnecessarily.
  Future<void> signOut() async {
    final current = _auth.currentUser;
    final isGoogleUser = current?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;
    if (isGoogleUser) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // signOut() can throw if no Google account is linked; ignore.
      }
    }
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Full account deletion (store-review requirement).
  ///
  /// Order matters: the `deleteUserData` callable wipes the server-side
  /// data and deletes the Auth record while the user is still signed in —
  /// after `user.delete()` alone, Firestore data would survive with no
  /// authenticated caller able to remove it.
  ///
  /// Throws the underlying [FirebaseFunctionsException] / [FirebaseAuthException]
  /// on failure; callers should surface a retry, not a partial delete.
  Future<void> deleteAccount() async {
    await FirebaseFunctions.instance.httpsCallable('deleteUserData').call();
    // Belt-and-braces: the callable already deleted the Auth record; this
    // no-ops if so, and covers local-only (emulator/offline) auth backends.
    await _auth.currentUser?.delete();
  }

  // ── Sensitive updates (P1-2 / P4-6) ─────────────────────────────────
  // Firebase requires a recent sign-in for `updateEmail` / `updatePassword`.
  // If the last sign-in is older than ~5 minutes, the call throws
  // `requires-recent-login`. The UI must collect the user's current
  // password and call [reauthenticateWithPassword] first.

  /// Re-authenticates the current email/password user with their current
  /// password. Throws if the user is not signed in or signed in via a
  /// provider that doesn't have a password (e.g. Google).
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Updates the current user's email. Caller is responsible for having
  /// re-authenticated recently.
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  /// Updates the current user's password. Caller is responsible for
  /// having re-authenticated recently.
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }
    await user.updatePassword(newPassword);
  }

  // Current user
  User? get currentUser => _auth.currentUser;
}

/// Sentinel exception thrown when the user dismisses the Google account
/// picker without choosing an account. Callers should treat this as a
/// no-op (don't show an error toast).
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
  @override
  String toString() => 'GoogleSignInCancelled';
}
