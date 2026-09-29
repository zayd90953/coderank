import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_progress_service.dart';
import 'weak_area_tracking_service.dart';

/// User-controlled settings and profile data that persists across launches.
///
/// Mirrors the [UserProgressService] pattern: singleton + [ValueNotifier] +
/// JSON in [SharedPreferences]. Stored at key [coderank_user_prefs_v1].
///
/// All setters are fire-and-forget [Future]s that update the notifier and
/// persist asynchronously. Every IO path is wrapped in try/catch so the
/// app still boots when the test harness uses an empty
/// [SharedPreferences.setMockInitialValues] map.
class UserPreferences {
  /// User-overridden display name. If null, the app falls back to the
  /// Firebase `displayName`, then to the literal `"NEET Aspirant"`.
  final String? displayName;

  /// One of `"avatar_1"` … `"avatar_6"`. Null = use the Google photo (if any)
  /// or the initials fallback.
  final String? avatarAssetKey;

  /// Target NEET exam year.
  final int? targetYear;

  /// Target state (raw free-text for now; see [UserPreferencesService]).
  final String? targetState;

  /// Target college (raw free-text for now; see [UserPreferencesService]).
  final String? targetCollege;

  /// `"system"` / `"light"` / `"dark"`. Defaults to `"light"` — the
  /// app ships light-first; users who want the dark look opt in via the
  /// theme picker (or by choosing "system" on a dark-mode device).
  final String themeMode;

  /// Whether the (UI-only) daily practice reminder tile is on.
  final bool dailyReminderEnabled;

  /// Default number of questions when the user starts a practice session.
  final int practiceQuestionCount;

  /// Default seconds-per-question when the user starts a practice session.
  final int practiceSecondsPerQuestion;


  const UserPreferences({
    this.displayName,
    this.avatarAssetKey,
    this.targetYear = 2026,
    this.targetState,
    this.targetCollege,
    this.themeMode = 'light',
    this.dailyReminderEnabled = true,
    this.practiceQuestionCount = 10,
    this.practiceSecondsPerQuestion = 60,
  });

  UserPreferences copyWith({
    String? displayName,
    String? avatarAssetKey,
    int? targetYear,
    String? targetState,
    String? targetCollege,
    String? themeMode,
    bool? dailyReminderEnabled,
    int? practiceQuestionCount,
    int? practiceSecondsPerQuestion,
  }) =>
      UserPreferences(
        displayName: displayName ?? this.displayName,
        avatarAssetKey: avatarAssetKey ?? this.avatarAssetKey,
        targetYear: targetYear ?? this.targetYear,
        targetState: targetState ?? this.targetState,
        targetCollege: targetCollege ?? this.targetCollege,
        themeMode: themeMode ?? this.themeMode,
        dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
        practiceQuestionCount: practiceQuestionCount ?? this.practiceQuestionCount,
        practiceSecondsPerQuestion:
            practiceSecondsPerQuestion ?? this.practiceSecondsPerQuestion,
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'avatarAssetKey': avatarAssetKey,
        'targetYear': targetYear,
        'targetState': targetState,
        'targetCollege': targetCollege,
        'themeMode': themeMode,
        'dailyReminderEnabled': dailyReminderEnabled,
        'practiceQuestionCount': practiceQuestionCount,
        'practiceSecondsPerQuestion': practiceSecondsPerQuestion,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        displayName: json['displayName'] as String?,
        avatarAssetKey: json['avatarAssetKey'] as String?,
        targetYear: json['targetYear'] as int? ?? 2026,
        targetState: json['targetState'] as String?,
        targetCollege: json['targetCollege'] as String?,
        themeMode: json['themeMode'] as String? ?? 'system',
        dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
        practiceQuestionCount: json['practiceQuestionCount'] as int? ?? 10,
        practiceSecondsPerQuestion:
            json['practiceSecondsPerQuestion'] as int? ?? 60,
      );
}

class UserPreferencesService {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  static const String _storageKey = 'coderank_user_prefs_v1';

  final ValueNotifier<UserPreferences> prefsNotifier =
      ValueNotifier<UserPreferences>(const UserPreferences());

  UserPreferences get current => prefsNotifier.value;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        prefsNotifier.value = UserPreferences.fromJson(decoded);
      } else {
        // Seed defaults and persist so subsequent reads are stable.
        const defaults = UserPreferences();
        prefsNotifier.value = defaults;
        await _persist(defaults);
      }
    } catch (e) {
      debugPrint('Error initializing UserPreferencesService: $e');
      // Keep the in-memory defaults; do not rethrow.
    }
  }

  Future<void> _persist(UserPreferences p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(p.toJson()));
    } catch (e) {
      debugPrint('Error persisting UserPreferences: $e');
    }
  }

  // ── Mutators ──────────────────────────────────────────────────────────────

  /// Writes the display name EXACTLY as given — passing null or blank
  /// clears it. Deliberately does NOT use [UserPreferences.copyWith], whose
  /// `??` fallback can never null a field (same defect [setTarget] works
  /// around); clearing must revert the UI to the auth-profile name.
  Future<void> setDisplayName(String? value) async {
    final trimmed = value?.trim();
    final cur = current;
    final next = UserPreferences(
      displayName: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      // Preserve every other field exactly.
      avatarAssetKey: cur.avatarAssetKey,
      targetYear: cur.targetYear,
      targetState: cur.targetState,
      targetCollege: cur.targetCollege,
      themeMode: cur.themeMode,
      dailyReminderEnabled: cur.dailyReminderEnabled,
      practiceQuestionCount: cur.practiceQuestionCount,
      practiceSecondsPerQuestion: cur.practiceSecondsPerQuestion,
    );
    prefsNotifier.value = next;
    await _persist(next);
  }

  Future<void> setAvatarAssetKey(String? key) async {
    final next = current.copyWith(avatarAssetKey: key);
    prefsNotifier.value = next;
    await _persist(next);
  }

  /// Writes the target fields EXACTLY as given — passing null clears a
  /// field. Deliberately does NOT use [UserPreferences.copyWith], whose
  /// `??` fallback can never null a field; the target picker's
  /// "— Not set —" clear option depends on being able to erase a value.
  Future<void> setTarget({
    int? year,
    String? state,
    String? college,
  }) async {
    final cur = current;
    final next = UserPreferences(
      // Preserve identity & app-level prefs.
      displayName: cur.displayName,
      avatarAssetKey: cur.avatarAssetKey,
      themeMode: cur.themeMode,
      dailyReminderEnabled: cur.dailyReminderEnabled,
      practiceQuestionCount: cur.practiceQuestionCount,
      practiceSecondsPerQuestion: cur.practiceSecondsPerQuestion,
      // Target fields written exactly as provided.
      targetYear: year,
      targetState: state,
      targetCollege: college,
    );
    prefsNotifier.value = next;
    await _persist(next);
  }

  Future<void> setThemeMode(String mode) async {
    if (mode != 'system' && mode != 'light' && mode != 'dark') {
      mode = 'system';
    }
    final next = current.copyWith(themeMode: mode);
    prefsNotifier.value = next;
    await _persist(next);
  }

  Future<void> setDailyReminder(bool enabled) async {
    final next = current.copyWith(dailyReminderEnabled: enabled);
    prefsNotifier.value = next;
    await _persist(next);
  }

  Future<void> setPracticeDefaults({
    required int count,
    required int seconds,
  }) async {
    final next = current.copyWith(
      practiceQuestionCount: count,
      practiceSecondsPerQuestion: seconds,
    );
    prefsNotifier.value = next;
    await _persist(next);
  }

  /// Resets study progress AND target fields, but PRESERVES the user's
  /// app-level preferences (theme / reminder / practice defaults / name /
  /// avatar). Delegates the actual stats reset to [UserProgressService].
  Future<void> resetProgress() async {
    await UserProgressService.instance.resetProgress();
    // R-3: weak-area mastery resets with the rest of study progress.
    await WeakAreaTrackingService.instance.reset();
    final next = UserPreferences(
      // Preserve identity & app-level prefs.
      displayName: current.displayName,
      avatarAssetKey: current.avatarAssetKey,
      themeMode: current.themeMode,
      dailyReminderEnabled: current.dailyReminderEnabled,
      practiceQuestionCount: current.practiceQuestionCount,
      practiceSecondsPerQuestion: current.practiceSecondsPerQuestion,
      // Reset target fields to factory defaults.
      targetYear: 2026,
      targetState: null,
      targetCollege: null,
    );
    prefsNotifier.value = next;
    await _persist(next);
  }
}
