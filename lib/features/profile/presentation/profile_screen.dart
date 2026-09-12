import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/firebase_user_util.dart';
import '../../../shared/services/user_preferences_service.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../auth/presentation/google_sign_in_flow.dart';
import '../../navigation/main_nav_screen.dart';
import '../../welcome/presentation/welcome_screen.dart';
import 'sheets/avatar_picker_sheet.dart';
import 'sheets/edit_name_sheet.dart';
import 'sheets/target_picker_sheet.dart';
import 'sheets/theme_picker_sheet.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ── Auth flows (kept here so they stay co-located with their UI) ─────────

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text("Sign Out",
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        content: Text(
          "Are you sure you want to sign out of CodeRank? Your study progress is safely saved.",
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Sign Out",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // P1-2: Switch Account flow for Google users. Signs them out of both
  // Google and Firebase, then re-triggers the shared linking-aware
  // Google flow (picker is forced every time). A picker cancel routes
  // to Welcome — the user was just signed out, so a silent no-op would
  // strand them on a Profile with no user behind it.
  Future<void> _switchGoogleAccount(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    await signInWithGoogleFlow(
      context,
      onSignedIn: () async {
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false,
        );
      },
      onCancelled: () async {
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      },
    );
  }

  // ── Change Email / Change Password (email/password users only) ──────
  //
  // Both flows follow the same shape:
  //   1. Re-auth dialog: ask the user for their current password and
  //      call [AuthService.reauthenticateWithPassword]. The dialog uses
  //      `StatefulBuilder` so error messages can re-render inline with
  //      the red-border `errorText` pattern.
  //   2. Update dialog: collect the new value (email or new password) and
  //      call the relevant `AuthService.updateEmail` / `updatePassword`.
  //   3. Success snackbar (or, for email, an extra "check your inbox"
  //      hint because we use verifyBeforeUpdateEmail).
  //
  // Google users skip this entirely: they have no password and email
  // changes for Google accounts are managed at accounts.google.com.

  /// Shows the re-auth dialog. Returns `true` on success, `false` if the
  /// user cancelled or auth failed.
  Future<bool> _showReauthDialog(BuildContext context) async {
    final palette = ColorPaletteController.instance.current;
    final passwordController = TextEditingController();
    String? passwordError;
    bool isAuthenticating = false;
    bool? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            title: Text("Confirm It's You",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter your current password to continue.",
                  style: TextStyle(
                      fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (passwordError != null) {
                      setLocalState(() => passwordError = null);
                    }
                  },
                  onSubmitted: (_) => _attemptReauth(
                    context,
                    ctx,
                    passwordController,
                    (err) => setLocalState(() => passwordError = err),
                    () => setLocalState(() => isAuthenticating = true),
                    () => setLocalState(() => isAuthenticating = false),
                    (ok) {
                      setLocalState(() {
                        isAuthenticating = false;
                        result = ok;
                      });
                      if (ok) Navigator.of(ctx).pop();
                    },
                  ),
                  decoration: InputDecoration(
                    errorText: passwordError,
                    labelText: 'Current password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isAuthenticating
                    ? null
                    : () {
                        result = false;
                        Navigator.of(ctx).pop();
                      },
                child: Text("Cancel",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: isAuthenticating
                    ? null
                    : () => _attemptReauth(
                          context,
                          ctx,
                          passwordController,
                          (err) => setLocalState(() => passwordError = err),
                          () => setLocalState(() => isAuthenticating = true),
                          () => setLocalState(() => isAuthenticating = false),
                          (ok) {
                            setLocalState(() {
                              isAuthenticating = false;
                              result = ok;
                            });
                            if (ok) Navigator.of(ctx).pop();
                          },
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isAuthenticating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Text("Continue"),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  /// Runs the reauth, calling the supplied callbacks to drive the
  /// dialog's local state.
  void _attemptReauth(
    BuildContext context,
    BuildContext dialogContext,
    TextEditingController passwordController,
    void Function(String?) setError,
    VoidCallback onStart,
    VoidCallback onEnd,
    void Function(bool) finish,
  ) async {
    final password = passwordController.text;
    if (password.isEmpty) {
      setError('Please enter your current password.');
      return;
    }
    onStart();
    try {
      await AuthService.instance.reauthenticateWithPassword(password);
      finish(true);
    } on FirebaseAuthException catch (e) {
      onEnd();
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setError('Incorrect password.');
      } else if (e.code == 'too-many-requests') {
        setError('Too many attempts. Try again later.');
      } else {
        setError('Could not verify your password. Try again.');
      }
    } catch (_) {
      onEnd();
      setError('Could not verify your password. Try again.');
    }
  }

  Future<void> _changeEmail(BuildContext context) async {
    final reauthed = await _showReauthDialog(context);
    if (!reauthed || !context.mounted) return;

    final palette = ColorPaletteController.instance.current;
    final newEmailController = TextEditingController();
    String? emailError;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            title: Text("Change Email",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We'll send a verification link to the new address. Your email won't change until you tap the link.",
                  style: TextStyle(
                      fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  onChanged: (_) {
                    if (emailError != null) {
                      setLocalState(() => emailError = null);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: emailError,
                    labelText: 'New email address',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isSaving ? null : () => Navigator.of(ctx).pop(),
                child: Text("Cancel",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newEmail = newEmailController.text.trim();
                        if (newEmail.isEmpty || !newEmail.contains('@')) {
                          setLocalState(() =>
                              emailError = 'Please enter a valid email.');
                          return;
                        }
                        setLocalState(() => isSaving = true);
                        try {
                          await AuthService.instance.updateEmail(newEmail);
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Verification link sent to $newEmail.",
                              ),
                              backgroundColor: palette.primary,
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          setLocalState(() => isSaving = false);
                          if (e.code == 'email-already-in-use') {
                            setLocalState(() =>
                                emailError = 'That email is already in use.');
                          } else if (e.code == 'invalid-email') {
                            setLocalState(() =>
                                emailError = 'Please enter a valid email.');
                          } else if (e.code == 'requires-recent-login') {
                            setLocalState(() => isSaving = false);
                            Navigator.of(ctx).pop();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please try again and enter your password promptly.",
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else {
                            setLocalState(() =>
                                emailError = 'Could not update email.');
                          }
                        } catch (_) {
                          setLocalState(() => isSaving = false);
                          setLocalState(
                              () => emailError = 'Could not update email.');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Text("Send Link"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final reauthed = await _showReauthDialog(context);
    if (!reauthed || !context.mounted) return;

    final palette = ColorPaletteController.instance.current;
    final currentPwd = TextEditingController();
    final newPwd = TextEditingController();
    final confirmPwd = TextEditingController();
    String? newPwdError;
    String? confirmPwdError;
    bool isSaving = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            title: Text("Change Password",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pick a new password. It must be at least 6 characters.",
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: newPwd,
                    obscureText: obscureNew,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (newPwdError != null) {
                        setLocalState(() => newPwdError = null);
                      }
                    },
                    decoration: InputDecoration(
                      errorText: newPwdError,
                      labelText: 'New password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setLocalState(
                            () => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPwd,
                    obscureText: obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (confirmPwdError != null) {
                        setLocalState(() => confirmPwdError = null);
                      }
                    },
                    decoration: InputDecoration(
                      errorText: confirmPwdError,
                      labelText: 'Confirm new password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setLocalState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSaving ? null : () => Navigator.of(ctx).pop(),
                child: Text("Cancel",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final np = newPwd.text;
                        final cp = confirmPwd.text;
                        if (np.length < 6) {
                          setLocalState(() => newPwdError =
                              'Password must be at least 6 characters.');
                          return;
                        }
                        if (np != cp) {
                          setLocalState(() =>
                              confirmPwdError = 'Passwords do not match.');
                          return;
                        }
                        setLocalState(() => isSaving = true);
                        try {
                          await AuthService.instance.updatePassword(np);
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  "Your password has been updated."),
                              backgroundColor: palette.primary,
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          setLocalState(() => isSaving = false);
                          if (e.code == 'weak-password') {
                            setLocalState(() =>
                                newPwdError = 'Please choose a stronger password.');
                          } else if (e.code == 'requires-recent-login') {
                            setLocalState(() => isSaving = false);
                            Navigator.of(ctx).pop();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please try again and enter your password promptly.",
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else {
                            setLocalState(() =>
                                newPwdError = 'Could not update password.');
                          }
                        } catch (_) {
                          setLocalState(() => isSaving = false);
                          setLocalState(() =>
                              newPwdError = 'Could not update password.');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Text("Update"),
              ),
            ],
          ),
        );
      },
    );
    // `currentPwd` is unused (the reauth dialog captured the password
    // earlier); suppress the unused-local warning.
    currentPwd.dispose();
  }

  void _confirmReset(BuildContext context, ColorPalette palette) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("Reset Progress?",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          "This will reset all your solved questions, XP, and subject accuracies back to zero. This cannot be undone.",
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await UserPreferencesService.instance.resetProgress();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Study progress has been reset."),
                    backgroundColor: palette.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Reset All"),
          ),
        ],
      ),
    );
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  ({String name, String email, String? photoUrl, bool isGoogleUser})
      _identity() {
    final user = firebaseCurrentUserOrNull();
    final prefs = UserPreferencesService.instance.current;
    final custom = prefs.displayName?.trim();
    final fbName = user?.displayName?.trim();
    final name = (custom != null && custom.isNotEmpty)
        ? custom
        : (fbName != null && fbName.isNotEmpty)
            ? fbName
            : "NEET Aspirant";
    return (
      name: name,
      email: user?.email ?? "student@coderank.ai",
      photoUrl: user?.photoURL,
      isGoogleUser: user?.providerData
              .any((p) => p.providerId == 'google.com') ??
          false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final id = _identity();

    return ValueListenableBuilder<UserPreferences>(
      valueListenable: UserPreferencesService.instance.prefsNotifier,
      builder: (context, prefs, _) {
        return ValueListenableBuilder<UserProgressData>(
          valueListenable: UserProgressService.instance.progressNotifier,
          builder: (context, data, _) {
            return ValueListenableBuilder<ColorPalette>(
              valueListenable: ColorPaletteController.instance.paletteNotifier,
              builder: (context, palette, _) {
                return Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: const BackButtonToHome(),
                    title: Text("Student Profile",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    centerTitle: true,
                  ),
                  body: SingleChildScrollView(
                    primary: true,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Column(
                      children: [
                        _HeaderCard(
                          name: id.name,
                          email: id.email,
                          photoUrl: id.photoUrl,
                          assetKey: prefs.avatarAssetKey,
                          tier: data.tier,
                          targetYear: prefs.targetYear,
                          targetState: prefs.targetState,
                          targetCollege: prefs.targetCollege,
                          palette: palette,
                          onAvatarTap: () => showAvatarPickerSheet(context),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.quiz_rounded,
                                value: "${data.totalQuestions}",
                                label: "Questions",
                                color: AppColors.physics,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.track_changes_rounded,
                                value: "${data.overallAccuracy.round()}%",
                                label: "Accuracy",
                                color: AppColors.chemistry,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.bolt_rounded,
                                value: "${data.xpPoints}",
                                label: "Total XP",
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Account ──
                        SettingsSection(
                          label: "Account",
                          children: [
                            _IdentityRow(
                              name: id.name,
                              email: id.email,
                              photoUrl: id.photoUrl,
                              assetKey: prefs.avatarAssetKey,
                              palette: palette,
                            ),
                            SettingsTile(
                              icon: Icons.edit_rounded,
                              title: "Edit Name",
                              subtitle: "How others see you in the app",
                              palette: palette,
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => showEditNameSheet(context,
                                  initial: id.name),
                            ),
                            // Change Email / Change Password only show
                            // for email/password users. Google users have
                            // no password and manage their email at
                            // accounts.google.com.
                            if (!id.isGoogleUser) ...[
                              SettingsTile(
                                icon: Icons.alternate_email_rounded,
                                title: "Change Email",
                                subtitle: "Update the email on your account",
                                palette: palette,
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                onTap: () => _changeEmail(context),
                              ),
                              SettingsTile(
                                icon: Icons.password_rounded,
                                title: "Change Password",
                                subtitle: "Choose a new password",
                                palette: palette,
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                onTap: () => _changePassword(context),
                              ),
                            ],
                            // Switch Account only shows for Google users.
                            // Signing out + immediately re-triggering the
                            // Google sign-in flow forces the account picker
                            // (AuthService.signInWithGoogle also calls
                            // GoogleSignIn.disconnect() defensively).
                            if (id.isGoogleUser) ...[
                              SettingsTile(
                                icon: Icons.switch_account_rounded,
                                title: "Switch Account",
                                subtitle:
                                    "Sign out and pick a different Google account",
                                palette: palette,
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                onTap: () => _switchGoogleAccount(context),
                              ),
                            ],
                            SettingsTile(
                              icon: Icons.logout_rounded,
                              title: "Sign Out",
                              subtitle: "Return to the welcome screen",
                              textColor: AppColors.error,
                              iconColor: AppColors.error,
                              palette: palette,
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _confirmSignOut(context),
                            ),
                            // P1-2: explicit note about the known account
                            // separation gap. This isn't a bug — it's a
                            // limitation we surface to the user until
                            // account linking is implemented.
                            if (!id.isGoogleUser) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 10, 16, 4),
                                child: Text(
                                  "This account uses email and password. "
                                  "Email/password and Google sign-in currently "
                                  "create separate accounts, so your progress "
                                  "won't carry over if you switch to Google "
                                  "sign-in later.",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── App ──
                        SettingsSection(
                          label: "App",
                          children: [
                            SettingsTile(
                              icon: Icons.palette_rounded,
                              title: "Theme",
                              subtitle: _themeLabel(prefs.themeMode),
                              palette: palette,
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => showThemePickerSheet(context),
                            ),
                            SwitchSettingsTile(
                              icon: Icons.notifications_active_rounded,
                              title: "Daily Practice Reminder",
                              subtitle: "9:00 AM Daily NEET Challenge",
                              value: prefs.dailyReminderEnabled,
                              palette: palette,
                              onChanged: (v) => UserPreferencesService.instance
                                  .setDailyReminder(v),
                            ),
                            SettingsTile(
                              icon: Icons.tune_rounded,
                              title: "Practice Defaults",
                              subtitle:
                                  "${prefs.practiceQuestionCount} questions • ${prefs.practiceSecondsPerQuestion}s per question",
                              palette: palette,
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onTap: () =>
                                  _showPracticeDefaultsDialog(context, prefs),
                            ),
                            SettingsTile(
                              icon: Icons.refresh_rounded,
                              title: "Reset Study Progress",
                              subtitle:
                                  "Clear questions and reset rank to test fresh",
                              textColor: AppColors.error,
                              iconColor: AppColors.error,
                              palette: palette,
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _confirmReset(context, palette),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── About ──
                        SettingsSection(
                          label: "About",
                          children: [
                            SettingsTile(
                              icon: Icons.info_outline_rounded,
                              title: "Version",
                              subtitle: "CodeRank release info",
                              palette: palette,
                              trailing: Text(
                                "v1.0.0",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.favorite_rounded,
                              title: "About CodeRank",
                              subtitle: "A smart learning platform for NEET aspirants",
                              palette: palette,
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _showAboutDialog(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Text(
                          "CodeRank v1.0.0 • Made for Ambitious NEET Aspirants",
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _themeLabel(String value) {
    switch (value) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System default';
    }
  }

  void _showPracticeDefaultsDialog(
      BuildContext context, UserPreferences prefs) {
    final countController =
        TextEditingController(text: '${prefs.practiceQuestionCount}');
    final secondsController =
        TextEditingController(text: '${prefs.practiceSecondsPerQuestion}');
    final palette = ColorPaletteController.instance.current;

    // Use a ValueNotifier so the dialog body (which is built once inside
    // showDialog's builder) can still re-render with the latest errors.
    String? countError;
    String? secondsError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            title: Text("Practice Defaults",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (countError != null) {
                      setLocalState(() => countError = null);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: countError,
                    labelText: 'Questions per session',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secondsController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (secondsError != null) {
                      setLocalState(() => secondsError = null);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: secondsError,
                    labelText: 'Seconds per question',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancel",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final count = int.tryParse(countController.text.trim());
                  final seconds =
                      int.tryParse(secondsController.text.trim());

                  setLocalState(() {
                    countError = (count == null || count <= 0)
                        ? "Enter a positive number."
                        : null;
                    secondsError = (seconds == null || seconds <= 0)
                        ? "Enter a positive number."
                        : null;
                  });

                  if (countError != null || secondsError != null) return;

                  await UserPreferencesService.instance.setPracticeDefaults(
                    count: count!,
                    seconds: seconds!,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("About CodeRank",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          "CodeRank is a smart NEET prep companion built for ambitious students. "
          "Practice topic-wise, take mock tests, and climb the daily leaderboard "
          "as you build the consistency that cracks NEET.",
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Header card
// ──────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final String? assetKey;
  final String tier;
  final int? targetYear;
  final String? targetState;
  final String? targetCollege;
  final ColorPalette palette;
  final VoidCallback onAvatarTap;

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.assetKey,
    required this.tier,
    required this.targetYear,
    required this.targetState,
    required this.targetCollege,
    required this.palette,
    required this.onAvatarTap,
  });

  String _formatTarget() {
    final parts = <String>[];
    if (targetYear != null) parts.add('NEET $targetYear');
    if (targetCollege != null && targetCollege!.isNotEmpty) {
      parts.add(targetCollege!);
    } else if (targetState != null && targetState!.isNotEmpty) {
      parts.add(targetState!);
    }
    if (parts.isEmpty) return 'Tap to set your target';
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final hasFullTarget = targetCollege != null && targetCollege!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: ProfileAvatar(
                    displayName: name,
                    googlePhotoUrl: photoUrl,
                    assetKey: assetKey,
                    palette: palette,
                    radius: 40,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 3),
          Text(email,
              style:
                  TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => showTargetPickerSheet(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: palette.primarySubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_rounded,
                      size: 16, color: palette.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Target: ${_formatTarget()}",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasFullTarget
                            ? palette.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_rounded,
                      size: 12, color: palette.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Identity row inside the Account section
// ──────────────────────────────────────────

class _IdentityRow extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final String? assetKey;
  final ColorPalette palette;

  const _IdentityRow({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.assetKey,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: ProfileAvatar(
              displayName: name,
              googlePhotoUrl: photoUrl,
              assetKey: assetKey,
              palette: palette,
              radius: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(email,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// A settings tile with a trailing Switch.
// ──────────────────────────────────────────

class SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;
  final ColorPalette palette;

  const SwitchSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.palette,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = palette.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: iconColor ?? primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: primary,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Stat card
// ──────────────────────────────────────────

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ProfileStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
