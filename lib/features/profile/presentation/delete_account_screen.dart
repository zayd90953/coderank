import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/user_preferences_service.dart';
import '../../welcome/presentation/welcome_screen.dart';

/// A-12: full account deletion.
///
/// One typed confirmation ("DELETE"), a plain-English summary of what is
/// erased, then: server wipe (callable) → local wipe → Welcome. This
/// screen is deliberately pessimistic — every failure leaves the user
/// signed in with a retry, never half-deleted.
class DeleteAccountScreen extends StatefulWidget {
  /// Test seams (R-4 `questionsOverride` pattern): production passes none
  /// and uses the real Firebase callable path. `onDeleteRequested` replaces
  /// [AuthService.deleteAccount]; `onWiped` replaces the post-wipe local
  /// clear + navigation so widget tests run with zero Firebase setup.
  final Future<void> Function()? onDeleteRequested;
  final VoidCallback? onWiped;

  const DeleteAccountScreen({super.key, this.onDeleteRequested, this.onWiped});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  bool get _isSuccessPath => widget.onDeleteRequested != null;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _confirmed =>
      _confirmController.text.trim().toUpperCase() == 'DELETE';

  Future<void> _delete() async {
    if (!_confirmed || _isDeleting) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    if (_isSuccessPath) {
      // Test path: the injected callable plays the server step. A throw
      // exercises the failure branch, success falls through to the wipe.
      try {
        await widget.onDeleteRequested!();
      } catch (_) {
        setState(() {
          _isDeleting = false;
          _error = 'Could not delete your account. Try again.';
        });
        return;
      }
      await UserPreferencesService.instance.clearAllLocalData();
      if (!mounted) return;
      widget.onWiped!();
      return;
    }

    try {
      // 1 ── Server: wipes users/{uid} and deletes the Auth record.
      await AuthService.instance.deleteAccount();
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _isDeleting = false;
        _error = 'Could not delete your account (${e.code}). Try again.';
      });
      return;
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isDeleting = false;
        _error = e.code == 'too-many-requests'
            ? 'Too many attempts. Try again later.'
            : 'Could not delete your account. Try again.';
      });
      return;
    } catch (_) {
      setState(() {
        _isDeleting = false;
        _error = 'Could not delete your account. Try again.';
      });
      return;
    }

    // 2 ── Local: nothing of this account may survive on the device.
    await UserPreferencesService.instance.clearAllLocalData();

    if (!mounted) return;
    // 3 ── Out. AuthGate would route here anyway once the auth stream
    //      fires, but an explicit push keeps the exit deterministic.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              'This cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Deleting your account permanently removes:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _DeleteItem('Your profile, name and avatar'),
            _DeleteItem('All XP, streaks, tiers and leaderboard standing'),
            _DeleteItem('Every practice, mock and daily-challenge record'),
            _DeleteItem('Your sign-in — this email cannot log in again'),
            const SizedBox(height: 24),
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Type DELETE to confirm',
                labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmed && !_isDeleting ? _delete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: AppColors.error.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Permanently Delete Everything',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Keep my account',
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteItem extends StatelessWidget {
  final String text;

  const _DeleteItem(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.close_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                color: scheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
