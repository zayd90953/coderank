import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../navigation/main_nav_screen.dart';
import '../../../shared/services/auth_service.dart';

/// Shared Google Sign-In flow used by every Google button in the app
/// (welcome, sign-in, sign-up, profile "Switch Account").
///
/// Success → [MainNavScreen] (or [fallbackRoute] result when provided).
/// Picker cancel → silent no-op (or the fallback).
/// `account-exists-with-different-credential` → offers account linking:
/// the user enters the password of the existing email/password account
/// and the Google credential is attached to it, so the same email is
/// ONE account across both providers.
///
/// [onSignedIn] lets call sites run extra post-success work (e.g. the
/// profile screen pops back instead of pushing MainNavScreen again).
/// [onCancelled] runs when the user dismisses the picker (the profile
/// screen's Switch Account signs out first, so a cancel must route to
/// Welcome instead of silently stranding the user).
Future<void> signInWithGoogleFlow(
  BuildContext context, {
  Future<void> Function()? onSignedIn,
  Future<void> Function()? onCancelled,
}) async {
  try {
    await AuthService.instance.signInWithGoogle();
    if (!context.mounted) return;
    await _handleGoogleSuccess(context, onSignedIn);
  } on GoogleSignInCancelled {
    // User dismissed the picker.
    if (onCancelled != null) {
      await onCancelled();
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'account-exists-with-different-credential' &&
        e.email != null &&
        e.credential != null) {
      if (!context.mounted) return;
      await _offerAccountLinking(
        context,
        email: e.email!,
        googleCredential: e.credential!,
        onSignedIn: onSignedIn,
      );
    } else {
      if (!context.mounted) return;
      await _showGoogleErrorDialog(context, _googleErrorMessage(e));
    }
  } catch (_) {
    if (!context.mounted) return;
    await _showGoogleErrorDialog(
      context,
      "Google sign-in failed. Please try again.",
    );
  }
}

Future<void> _handleGoogleSuccess(
  BuildContext context,
  Future<void> Function()? onSignedIn,
) async {
  if (onSignedIn != null) {
    await onSignedIn();
    return;
  }
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainNavScreen()),
    (route) => false,
  );
}

// ── Account linking ──────────────────────────────────────────────────

Future<void> _offerAccountLinking(
  BuildContext context, {
  required String email,
  required AuthCredential googleCredential,
  Future<void> Function()? onSignedIn,
}) async {
  final linked = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LinkAccountDialog(email: email),
  );
  if (linked != true || !context.mounted) return;

  // Password supplied — attempt the sign-in + link.
  try {
    await AuthService.instance.linkGoogleToPasswordAccount(
      email: email,
      password: _LinkAccountDialog.lastPassword,
      googleCredential: googleCredential,
    );
    if (!context.mounted) return;
    await _handleGoogleSuccess(context, onSignedIn);
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    await _showGoogleErrorDialog(context, _linkErrorMessage(e));
  } catch (_) {
    if (!context.mounted) return;
    await _showGoogleErrorDialog(
      context,
      "Could not link your Google account. Please try again.",
    );
  }
}

String _linkErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
    case 'user-not-found':
      return "Incorrect password. Please try again.";
    case 'too-many-requests':
      return "Too many attempts. Please wait a moment and try again.";
    case 'network-request-failed':
      return "Network error. Please check your connection and try again.";
    case 'credential-already-in-use':
      return "This Google account is already linked to another account.";
    default:
      return "Could not link your Google account. Please try again.";
  }
}

String _googleErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'account-exists-with-different-credential':
      return "An account already exists with this email using a different "
          "sign-in method. Please use email and password instead.";
    case 'invalid-credential':
    case 'invalid-verification-code':
    case 'invalid-verification-id':
      return "Google sign-in failed because the credential is invalid. "
          "Please try again.";
    case 'network-request-failed':
      return "Network error. Please check your connection and try again.";
    case 'operation-not-allowed':
      return "Google sign-in is not enabled for this project. "
          "Please contact support.";
    default:
      return "Google sign-in failed. Please try again.";
  }
}

// ── Link-account dialog ──────────────────────────────────────────────

/// Collects the password of the existing email/password account so the
/// pending Google credential can be linked to it. The typed password is
/// handed to the flow via the static [lastPassword] (consumed right
/// after the dialog closes — not persisted anywhere).
class _LinkAccountDialog extends StatefulWidget {
  final String email;

  const _LinkAccountDialog({required this.email});

  /// Password typed into the most recent instance of this dialog.
  static String lastPassword = '';

  @override
  State<_LinkAccountDialog> createState() => _LinkAccountDialogState();
}

class _LinkAccountDialogState extends State<_LinkAccountDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    _LinkAccountDialog.lastPassword = _controller.text;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = ColorPaletteController.instance.current;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Icon(Icons.link_rounded, color: palette.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Link your accounts",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "An account for $widget.email already exists with a password. "
            "Enter that password to link Google sign-in to it — then you "
            "can sign in with either method.",
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: "Password",
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurfaceVariant,
          ),
          child: const Text(
            "Not now",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Link account",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Error dialog (shared, theme-aware) ───────────────────────────────

Future<void> _showGoogleErrorDialog(
  BuildContext context,
  String message,
) async {
  final scheme = Theme.of(context).colorScheme;
  final palette = ColorPaletteController.instance.current;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error, size: 24),
          const SizedBox(width: 10),
          Text(
            "Sign-In Failed",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "OK",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
