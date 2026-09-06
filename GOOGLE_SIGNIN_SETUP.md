# Google Sign-In Setup Guide (P1-2)

Real Google Sign-In is now wired in code (`google_sign_in: ^6.2.1` in `pubspec.yaml`, `AuthService.signInWithGoogle()` in `lib/shared/services/auth_service.dart`, all three Google buttons call it, profile screen has a "Switch Account" tile and a note about account separation). The code is ready to ship, but it will not run end-to-end until the project's `google-services.json` contains a valid Android OAuth client.

This file explains what is already in place, what to verify, and how to fix the most common breakage.

---

## TL;DR — what is required to make Google Sign-In work

1. A Firebase project with **Authentication → Sign-in method → Google** enabled and a project support email set.
2. The Android app's **SHA-1 fingerprint registered** in Firebase (Project settings → Your apps → Android app → Add fingerprint).
3. `android/app/google-services.json` containing the Android OAuth client (i.e. `oauth_client` is non-empty).
4. `google-services` Gradle plugin applied in `android/app/build.gradle.kts` (already done).
5. A real device or emulator with Google Play Services (the emulator image must be a "Google APIs" image, not the bare AOSP one).

When all 5 are true, `AuthService.signInWithGoogle()` opens the Google account picker, returns a `GoogleSignInAccount`, exchanges it for a Firebase credential, and signs the user in.

---

## What is already done in this repo

These are confirmed in the working tree as of 2026-09-03:

- `pubspec.yaml` lists `google_sign_in: ^6.2.1` and `firebase_auth: ^6.5.7`. `flutter pub get` resolves cleanly.
- `android/app/build.gradle.kts` has `id("com.google.gms.google-services")` and `applicationId = "com.example.coderank"`.
- `android/app/src/main/AndroidManifest.xml` does **not** need a special `intent-filter` for Google Sign-In — the `google_sign_in` plugin opens the system account chooser via Play Services.
- `lib/shared/services/auth_service.dart` has:
  - `signInWithGoogle()` — calls `GoogleSignIn.disconnect()` first to force the picker, then `signIn()`, then `GoogleAuthProvider.credential(...)` → `_auth.signInWithCredential(...)`.
  - `signOut()` — also calls `GoogleSignIn.signOut()` if the current user is a Google user, so the next sign-in shows the picker again.
  - `GoogleSignInCancelled` — sentinel exception the UI catches silently when the user dismisses the picker.
- All three Google buttons (Welcome / Sign-In / Sign-Up) call a real `_signInWithGoogle(...)` helper. On success, they route to `MainNavScreen` via `pushAndRemoveUntil`. On picker cancel, silent no-op. On other errors, an error dialog.
- Profile screen Account section has:
  - A "Switch Account" tile (Google users only) that signs out + re-triggers `signInWithGoogle()` so the picker is shown.
  - A short note under the Sign Out tile for email/password users explaining that the two providers create separate accounts and progress doesn't carry over.

---

## Verify the existing Firebase console setup

Open https://console.firebase.google.com/, select the project **coderank-6e6eb** (`project_number: 99386983070`, `project_id: coderank-6e6eb` — both visible in `android/app/google-services.json`).

### 1. Authentication → Sign-in method → Google

- The "Google" row should show **Enabled**.
- The **Project support email** field should be set to an email you can read. If it is empty, sign-in will fail with `operation-not-allowed` (the user-facing message we already map to a friendly error dialog).
- The **Project public-facing name** should be **CodeRank** (it is by default for an Android app with that label; if you changed it, sign-in still works, the picker just shows a different name).

If Google is **not** enabled, click it, toggle Enable, save the support email, and Save.

### 2. Project settings → Your apps → Android app

The Android app entry should match:

| Field              | Expected value          |
| ------------------ | ----------------------- |
| Package name       | `com.example.coderank`  |
| App nickname       | (any — informational)   |
| Debug signing cert | SHA-1 of your debug key |

#### Re-add the SHA-1 if anything has changed

The most common reason Google Sign-In stops working after a long absence is that the SHA-1 in Firebase no longer matches the SHA-1 of the key Flutter is signing with. Re-add it:

1. From the project root, run:
   ```bash
   cd android
   ./gradlew signInReport
   ```
   On Windows use `gradlew.bat signInReport`. The output is a long JSON blob — copy the `SHA1` value out of the `debug` variant.
2. In the Firebase console, Project settings → Your apps → Android app → Add fingerprint, paste the SHA-1, save.
3. If you also build a release APK and want Google Sign-In to work in release builds, repeat for the **release** SHA-1. (Debug is enough for the dev loop.)

If you are using a different machine than the one that originally registered the SHA-1, the debug keystore will produce a different SHA-1. Re-add it.

### 3. `android/app/google-services.json` — the missing OAuth client

Open `android/app/google-services.json` and look at the `oauth_client` array. The committed file currently has:

```json
"oauth_client": []
```

That empty array is the single most common cause of `PlatformException(sign_in_failed, ...)` on Android. To fix it, download a fresh `google-services.json` from the Firebase console:

1. Project settings → Your apps → Android app (`com.example.coderank`).
2. Click **Download google-services.json**.
3. Replace `android/app/google-services.json` with the downloaded file.
4. Verify the new file has at least one entry in `oauth_client` for your package name. It will look like:
   ```json
   "oauth_client": [
     {
       "client_id": "99386983070-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com",
       "client_type": 1,
       "android_info": {
         "package_name": "com.example.coderank",
         "certificate_hash": "aabbccddeeff00112233445566778899aabbccdd"
       }
     }
   ]
   ```
5. `flutter clean && flutter pub get`, then rebuild. (A hot restart is not enough — Gradle caches the old file.)

#### Do you need a Web client ID?

`google_sign_in` 6.x on Android picks up the Android OAuth client automatically from `google-services.json`. **You do not need to pass `GoogleSignIn(serverClientId: ...)` on Android.** The only case where a Web client ID matters is iOS or Web sign-in, which this app does not target. If you later add iOS, see the "iOS setup" section below.

---

## Testing on a real device

The Google account picker is part of Google Play Services. It will not work on a stock AOSP emulator image. Use either:

- A **physical Android device** with a Google account signed in.
- An **emulator with Google Play** (Android Studio → Virtual Device → New → choose a system image tagged "Google Play", not "Google APIs" alone).

To test:

1. `flutter run` (debug) on the device/emulator.
2. Tap **Continue with Google** on the Welcome screen.
3. The system account picker should appear. Pick an account.
4. If the account is brand new to CodeRank, a new Firebase user is created and the app navigates to `MainNavScreen`.
5. If the account is the same one you used last time, the picker still appears (because `signInWithGoogle()` calls `disconnect()` first), so a different account can be chosen.

To verify "Switch Account" from the profile:

1. Sign in with a Google account.
2. Open the profile (tap the avatar in the home header).
3. Tap **Switch Account** in the Account section.
4. The app signs you out, then re-opens the picker. Pick a different account — the app navigates to `MainNavScreen` as the new user.

To verify the "email/password vs Google" account separation:

1. Sign up with email/password for a brand-new email (e.g. `test1@example.com`).
2. Sign out.
3. Try to sign in with Google using an account whose email is `test1@example.com`.
4. Firebase returns `account-exists-with-different-credential`. Our UI catches this and shows a friendly error dialog: *"An account already exists with this email using a different sign-in method."*

---

## What is NOT done yet (flagged gaps)

These are real product gaps, not bugs. The code does the best it can and surfaces the limitations to the user; the underlying Firebase plumbing still needs to be done to fully solve them.

### 1. Account linking (same email, two providers)

Today, signing up with `alice@example.com` (email/password) and later signing in with Google as `alice@example.com` creates **two separate Firebase users**. Our sign-in flow detects this (`account-exists-with-different-credential`) and rejects the Google sign-in, telling the user to use email/password. There is no way yet to merge the two accounts.

To fix this properly, the next pass should:

- Catch `account-exists-with-different-credential` at sign-in time, look up the existing email/password user's `EmailAuthProvider` credential, and call `currentUser.linkWithCredential(credential)` after the user re-authenticates with their password. This is a UX-heavy flow (a "Link your account" dialog) and is deliberately deferred to a follow-up P1-2 task.

### 2. iOS setup (not in scope)

This app is Android-only. If iOS is added later, the same `google_sign_in` flow needs:

- `ios/Runner/Info.plist` with `CFBundleURLTypes` for the reversed client ID.
- A `GoogleService-Info.plist` from the Firebase console.
- `GoogleSignIn(clientId: ...)` set to the iOS client ID.

### 3. Forgot password for Google users

Google users have no password, so the "Forgot Password" link on the sign-in screen doesn't apply to them. The current behaviour — the link is always tappable from the sign-in screen — is fine, but the user will be told "No account found with that email" if they enter their Google email. A nicer touch would be to detect "this is a Google account" and route them to the "Sign in with Google" button instead. Deferred.

---

## Quick verification checklist

When you've done the Firebase console work and replaced `google-services.json`, this is the minimum check:

- [ ] `flutter pub get` succeeds.
- [ ] `flutter analyze` is clean.
- [ ] `flutter run` on a real device or a Google-Play emulator image.
- [ ] Welcome screen → "Continue with Google" → system picker appears.
- [ ] After picking an account, the app lands on `MainNavScreen` with the bottom nav.
- [ ] Profile screen shows the signed-in email. For Google users, "Switch Account" is visible.
- [ ] Sign out, then sign in with Google again — the picker is shown (not silently reusing the last account).
- [ ] Sign in with email/password, try to "Continue with Google" with the same email — the friendly error dialog appears.

If any of these fail, the most likely culprits in order are:

1. `google-services.json` `oauth_client` is still empty — re-download from Firebase.
2. SHA-1 mismatch — re-run `./gradlew signInReport` and add the new SHA-1 to the Firebase Android app.
3. You're on a non-Google-Play emulator — switch images.
4. Google sign-in is disabled in Firebase Authentication → Sign-in method — re-enable.
