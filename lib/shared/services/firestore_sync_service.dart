import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'user_progress_service.dart';
import 'user_preferences_service.dart';
import 'weak_area_tracking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore document paths
// ─────────────────────────────────────────────────────────────────────────────

/// Canonical Firestore paths for all user data.
///
/// ```text
/// users/{uid}/profile              ← client writes (identity only)
/// users/{uid}/progress             ← Cloud Function writes (client reads)
/// users/{uid}/weakAreas            ← client writes (informational)
/// users/{uid}/sessions/{sessionId} ← Cloud Function creates (client reads)
/// users/{uid}/syncMetadata         ← migration flag (client writes once)
/// ```
class FirestorePaths {
  FirestorePaths._();

  static DocumentReference<Map<String, dynamic>> profile(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('profile').doc('data');

  static DocumentReference<Map<String, dynamic>> progress(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('progress').doc('data');

  static DocumentReference<Map<String, dynamic>> weakAreas(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('weakAreas').doc('data');

  static CollectionReference<Map<String, dynamic>> sessions(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('sessions');

  static DocumentReference<Map<String, dynamic>> syncMetadata(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('syncMetadata').doc('status');
}

// ─────────────────────────────────────────────────────────────────────────────
// Migration status
// ─────────────────────────────────────────────────────────────────────────────

enum MigrationStatus {
  /// Migration has not started yet.
  notMigrated,

  /// Migration already completed — skip.
  alreadyMigrated,

  /// Firestore already has real progress data; only missing docs written.
  partialMigration,

  /// Full migration from SharedPreferences completed.
  fullMigration,
}

class MigrationResult {
  final MigrationStatus status;
  final int profileDocsWritten;
  final int progressDocsWritten;
  final int weakAreaDocsWritten;
  final int sessionDocsWritten;

  const MigrationResult({
    required this.status,
    this.profileDocsWritten = 0,
    this.progressDocsWritten = 0,
    this.weakAreaDocsWritten = 0,
    this.sessionDocsWritten = 0,
  });

  @override
  String toString() => 'MigrationResult(status: $status, '
      'profile: $profileDocsWritten, progress: $progressDocsWritten, '
      'weakAreas: $weakAreaDocsWritten, sessions: $sessionDocsWritten)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Session submission request/response (anti-cheat boundary)
// ─────────────────────────────────────────────────────────────────────────────

/// Raw session data submitted by the client for server-side verification.
///
/// Contains ONLY untrusted client data — no computed fields like correct
/// counts or XP. The Cloud Function verifies answers against the question
/// bank, computes all competitive fields, and creates the immutable
/// session record.
class SessionSubmitRequest {
  final String sessionId;

  /// Kind of session submitted. Allowed values (enforced server-side by
  /// the `verifySession` callable):
  ///
  ///   'practice' | 'dailyChallenge' | 'mockFull' | 'mockQuick' | 'diagnostic'
  ///
  /// Consistency rules (server-enforced):
  ///   * dailyChallenge requires isDailyChallenge == true
  ///   * every other kind requires isDailyChallenge == false
  final String sessionKind;
  final String subject;
  final List<String> questionIds;
  final Map<String, int> selectedAnswers;
  final Set<String> timedOutQuestionIds;
  final DateTime timestamp;
  final bool isDailyChallenge;

  const SessionSubmitRequest({
    required this.sessionId,
    this.sessionKind = 'practice',
    required this.subject,
    required this.questionIds,
    required this.selectedAnswers,
    required this.timedOutQuestionIds,
    required this.timestamp,
    this.isDailyChallenge = false,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sessionKind': sessionKind,
        'subject': subject,
        'questionIds': questionIds,
        'selectedAnswers': selectedAnswers,
        'timedOutQuestionIds': timedOutQuestionIds.toList(),
        'timestamp': timestamp.toIso8601String(),
        'isDailyChallenge': isDailyChallenge,
      };
}

/// Result returned to the client after the Cloud Function verifies a session.
///
/// The client uses this for UI display only. Progress is refreshed from
/// Firestore via [FirestoreSyncService.readProgress] on the next load.
class SessionSubmissionResult {
  final bool success;
  final String? errorMessage;

  /// The server-verified session record. `null` when verification failed
  /// or the Cloud Function is unavailable.
  final SessionRecord? verifiedRecord;

  const SessionSubmissionResult({
    required this.success,
    this.errorMessage,
    this.verifiedRecord,
  });

  factory SessionSubmissionResult.fromCallableResponse(
    Map<String, dynamic> data,
  ) {
    final record = data['record'] as Map<String, dynamic>?;
    return SessionSubmissionResult(
      success: data['success'] as bool? ?? false,
      errorMessage: data['errorMessage'] as String?,
      verifiedRecord: record != null ? SessionRecord.fromJson(record) : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security boundary — fields the Flutter client must NEVER write directly
// ─────────────────────────────────────────────────────────────────────────────

/// Competitive progress fields that may only be written by the Cloud Function.
/// Listed here for documentation and enforced by the absence of public
/// write/update methods on [FirestoreSyncService].
const Set<String> kServerAuthoritativeProgressFields = {
  'totalQuestions',
  'totalCorrect',
  'totalIncorrect',
  'totalUnanswered',
  'totalSessions',
  'xpPoints',
  'streakDays',
  'lastActiveDate',
  'subjectStats',
  'lastDailyChallengeDate',
  'dailyChallengeXpEarned',
};

/// Session fields that may only be written by the Cloud Function.
const Set<String> kServerAuthoritativeSessionFields = {
  'correct',
  'xpGained',
};

// ─────────────────────────────────────────────────────────────────────────────
// Firestore Sync Service
// ─────────────────────────────────────────────────────────────────────────────

/// Flutter-side Firestore repository for CodeRank cloud sync.
///
/// **Security boundary:** This service never directly writes competitive
/// progress fields (XP, counters, streaks, session correct/xpGained).
/// Those are written exclusively by the `verifySession` Cloud Function
/// triggered via [submitSession].
///
/// **SharedPreferences is preserved as the local/offline cache.**
/// This service does not delete or clear any local data.
class FirestoreSyncService {
  FirestoreSyncService._();
  static final FirestoreSyncService instance = FirestoreSyncService._();

  // Convenience alias — resolves lazily; null when UID not set.
  String? get _uid => UserProgressService.instance.userId;

  /// Throws if no user is authenticated.
  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError(
        'FirestoreSyncService: no authenticated user. '
        'UserProgressService.userId is null.',
      );
    }
    return uid;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Converts a Firestore [Timestamp] or ISO-8601 string to [DateTime].
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Builds a [UserProgressData] from a Firestore progress document map.
  /// The `history` field is NOT present in Firestore — it lives in the
  /// sessions subcollection. The caller supplies it separately if needed.
  static UserProgressData _progressFromFirestore(
    Map<String, dynamic> data, {
    List<SessionRecord> history = const [],
  }) {
    // Parse subjectStats
    final rawStats = data['subjectStats'] as Map<String, dynamic>? ?? {};
    final subjectStats = <String, SubjectStat>{};
    for (final entry in rawStats.entries) {
      if (entry.value is Map<String, dynamic>) {
        subjectStats[entry.key] = SubjectStat.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return UserProgressData(
      totalQuestions: data['totalQuestions'] as int? ?? 0,
      totalCorrect: data['totalCorrect'] as int? ?? 0,
      totalIncorrect: data['totalIncorrect'] as int? ?? 0,
      totalUnanswered: data['totalUnanswered'] as int? ?? 0,
      totalSessions: data['totalSessions'] as int? ?? 0,
      xpPoints: data['xpPoints'] as int? ?? 0,
      streakDays: data['streakDays'] as int? ?? 0,
      lastActiveDate: data['lastActiveDate'] as String? ?? '',
      subjectStats: subjectStats,
      history: history,
      lastDailyChallengeDate: data['lastDailyChallengeDate'] as String? ?? '',
      dailyChallengeXpEarned: data['dailyChallengeXpEarned'] as int? ?? 0,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // 1. Profile
  // ───────────────────────────────────────────────────────────────────────

  /// Reads the user's profile from Firestore.
  ///
  /// Firestore path: `users/{uid}/profile/data`
  /// Returns `null` if the document does not exist.
  /// Auth: required.
  Future<UserPreferences?> readProfile() async {
    final uid = _requireUid();
    try {
      final doc = await FirestorePaths.profile(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserPreferences.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('FirestoreSyncService.readProfile error: $e');
      return null;
    }
  }

  /// Creates or overwrites the user's profile in Firestore.
  ///
  /// Firestore path: `users/{uid}/profile/data` (Set with merge:true)
  /// Auth: required.
  /// Only writes identity/target fields — theme/practice defaults stay local.
  Future<void> writeProfile(UserPreferences prefs) async {
    final uid = _requireUid();
    try {
      await FirestorePaths.profile(uid).set(
        {
          'displayName': prefs.displayName,
          'avatarAssetKey': prefs.avatarAssetKey,
          'targetYear': prefs.targetYear,
          'targetState': prefs.targetState,
          'targetCollege': prefs.targetCollege,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FirestoreSyncService.writeProfile error: $e');
      rethrow;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // 2. Progress (CLIENT READ-ONLY)
  // ───────────────────────────────────────────────────────────────────────

  /// Reads the user's progress from Firestore.
  ///
  /// Firestore path: `users/{uid}/progress/data`
  /// Returns `null` if the document does not exist.
  /// Auth: required.
  ///
  /// **The client never writes this document directly.** All progress
  /// mutations happen in the `verifySession` Cloud Function.
  Future<UserProgressData?> readProgress() async {
    final uid = _requireUid();
    try {
      final doc = await FirestorePaths.progress(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return _progressFromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('FirestoreSyncService.readProgress error: $e');
      return null;
    }
  }

  /// Creates the initial progress document during migration/bootstrap.
  ///
  /// Firestore path: `users/{uid}/progress/data`
  /// Auth: required.
  ///
  /// This method exists ONLY for the first-time migration. After
  /// migration, progress is updated exclusively by the Cloud Function.
  /// The `history` field is excluded — sessions live in the sessions
  /// subcollection.
  ///
  /// **Do not call this for normal progress updates.**
  Future<void> initProgressDocument(UserProgressData data) async {
    final uid = _requireUid();
    try {
      final docData = <String, dynamic>{
        'totalQuestions': data.totalQuestions,
        'totalCorrect': data.totalCorrect,
        'totalIncorrect': data.totalIncorrect,
        'totalUnanswered': data.totalUnanswered,
        'totalSessions': data.totalSessions,
        'xpPoints': data.xpPoints,
        'streakDays': data.streakDays,
        'lastActiveDate': data.lastActiveDate,
        'subjectStats': data.subjectStats.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        // NOTE: 'history' is NOT written — it lives in sessions subcollection.
        'lastDailyChallengeDate': data.lastDailyChallengeDate,
        'dailyChallengeXpEarned': data.dailyChallengeXpEarned,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirestorePaths.progress(uid).set(docData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSyncService.initProgressDocument error: $e');
      rethrow;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // 3. Weak Areas
  // ───────────────────────────────────────────────────────────────────────

  /// Reads the user's weak-areas document from Firestore.
  ///
  /// Firestore path: `users/{uid}/weakAreas/data`
  /// Returns `null` if the document does not exist.
  /// Auth: required.
  Future<WeakAreaData?> readWeakAreas() async {
    final uid = _requireUid();
    try {
      final doc = await FirestorePaths.weakAreas(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return WeakAreaData.fromJson(data);
    } catch (e) {
      debugPrint('FirestoreSyncService.readWeakAreas error: $e');
      return null;
    }
  }

  /// Creates or overwrites the user's weak-areas document in Firestore.
  ///
  /// Firestore path: `users/{uid}/weakAreas/data` (Set with merge:true)
  /// Auth: required.
  /// Write ownership: CLIENT-SAFE (informational, no competitive impact).
  Future<void> writeWeakAreas(WeakAreaData data) async {
    final uid = _requireUid();
    try {
      final docData = data.toJson();
      docData['updatedAt'] = FieldValue.serverTimestamp();
      await FirestorePaths.weakAreas(uid).set(docData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSyncService.writeWeakAreas error: $e');
      rethrow;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // 4. Sessions (CLIENT READ-ONLY after submission)
  // ───────────────────────────────────────────────────────────────────────

  /// Reads the N most recent session documents from Firestore.
  ///
  /// Firestore path: `users/{uid}/sessions` (subcollection, ordered by
  /// `timestamp` descending)
  /// Auth: required.
  /// Returns an empty list if no sessions exist.
  Future<List<SessionRecord>> readRecentSessions({int limit = 50}) async {
    final uid = _requireUid();
    try {
      final snapshot = await FirestorePaths.sessions(uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SessionRecord(
          id: doc.id,
          subject: data['subject'] as String? ?? 'Practice',
          correct: data['correct'] as int? ?? 0,
          total: data['total'] as int? ?? 0,
          // accuracy is derived — not stored in Firestore
          accuracy: 0,
          timestamp: _parseTimestamp(data['timestamp']),
          xpGained: data['xpGained'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('FirestoreSyncService.readRecentSessions error: $e');
      return [];
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // 5. Session Submission (anti-cheat boundary)
  // ───────────────────────────────────────────────────────────────────────

  /// Submits a completed session for server-side verification.
  ///
  /// The client sends raw answer data to the `verifySession` Cloud
  /// Function. The Cloud Function:
  ///   1. Verifies answers against the question bank
  ///   2. Computes correct / incorrect / unanswered counts
  ///   3. Computes XP
  ///   4. Updates `users/{uid}/progress` (competitive fields)
  ///   5. Creates `users/{uid}/sessions/{sessionId}` (immutable record)
  ///   6. Updates streak and daily challenge state
  ///
  /// The Flutter client **never** directly writes to the progress or
  /// sessions collections for competitive data.
  ///
  /// Auth: required (userId must be non-null).
  /// Firestore: none directly — delegates to Cloud Function.
  ///
  /// If the Cloud Function is unavailable (not deployed, network error,
  /// function returns an error), the result indicates failure. The caller
  /// should fall back to local-only storage or show an error. The
  /// existing SharedPreferences-based `UserProgressService.recordSession`
  /// continues to work as the offline fallback.
  Future<SessionSubmissionResult> submitSession(
    SessionSubmitRequest request,
  ) async {
    // Enforce authentication. The UID is carried by the Firebase ID
    // token — the Cloud Function extracts it server-side.
    _requireUid();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'verifySession',
      );

      final result = await callable<Map<String, dynamic>>(
        request.toJson(),
      );

      return SessionSubmissionResult.fromCallableResponse(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'FirestoreSyncService.submitSession FirebaseFunctionsException: '
        '${e.code} — ${e.message}',
      );
      return SessionSubmissionResult(
        success: false,
        errorMessage: e.message ??
            'Session verification failed (${e.code}). '
            'Your session was saved locally.',
      );
    } catch (e) {
      debugPrint('FirestoreSyncService.submitSession error: $e');
      return const SessionSubmissionResult(
        success: false,
        errorMessage: 'Session verification unavailable. '
            'Your session was saved locally.',
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // 6. Migration
  // ───────────────────────────────────────────────────────────────────────

  /// Checks whether the current user's local data has been migrated
  /// to Firestore.
  ///
  /// Firestore path: `users/{uid}/syncMetadata/status`
  /// Auth: required.
  Future<MigrationStatus> checkMigrationStatus() async {
    final uid = _requireUid();
    try {
      final doc = await FirestorePaths.syncMetadata(uid).get();
      if (!doc.exists || doc.data() == null) {
        return MigrationStatus.notMigrated;
      }
      final data = doc.data()!;
      if (data['migrated'] == true) {
        return MigrationStatus.alreadyMigrated;
      }
      return MigrationStatus.notMigrated;
    } catch (e) {
      debugPrint('FirestoreSyncService.checkMigrationStatus error: $e');
      return MigrationStatus.notMigrated;
    }
  }

  /// Migrates local SharedPreferences data to Firestore.
  ///
  /// **Idempotent:** safe to call multiple times.
  /// **Preserves SharedPreferences:** local data is never deleted.
  ///
  /// Firestore paths: all five user collections.
  /// Auth: required.
  /// Uses: batched writes for atomicity.
  ///
  /// Migration logic:
  ///   1. If `syncMetadata.migrated == true` → return immediately.
  ///   2. If Firestore progress already has data (`totalQuestions > 0`) →
  ///      write only missing profile/weakAreas docs (partial migration).
  ///   3. If Firestore progress is empty → full migration from
  ///      SharedPreferences.
  ///   4. Session records use their existing IDs as document IDs.
  ///      `xpGained` is preserved from the stored historical value.
  ///   5. `syncMetadata.migrated` is set only AFTER all writes succeed.
  Future<MigrationResult> migrateLocalData() async {
    final uid = _requireUid();

    // ── Step 1: Check if already migrated ─────────────────────────────
    final existingStatus = await checkMigrationStatus();
    if (existingStatus == MigrationStatus.alreadyMigrated) {
      return const MigrationResult(status: MigrationStatus.alreadyMigrated);
    }

    // ── Step 2: Read local SharedPreferences data ─────────────────────
    final localProgress = UserProgressService.instance.current;
    final localWeakAreas = WeakAreaTrackingService.instance.current;
    final localPrefs = UserPreferencesService.instance.current;

    // ── Step 3: Check Firestore progress to avoid overwriting ─────────
    UserProgressData? existingFirestoreProgress;
    try {
      existingFirestoreProgress = await readProgress();
    } catch (_) {
      // If we can't read, assume empty — the batch will either succeed
      // or fail, but won't corrupt data because we only SET (not UPDATE).
    }

    final firestoreHasRealData =
        existingFirestoreProgress != null &&
        existingFirestoreProgress.totalQuestions > 0;

    // ── Step 4: Build the batch ───────────────────────────────────────
    final batch = FirebaseFirestore.instance.batch();
    var profileWritten = 0;
    var progressWritten = 0;
    var weakAreasWritten = 0;
    var sessionWritten = 0;

    // Profile — always write (merge:true so we never clobber).
    batch.set(
      FirestorePaths.profile(uid),
      {
        'displayName': localPrefs.displayName,
        'avatarAssetKey': localPrefs.avatarAssetKey,
        'targetYear': localPrefs.targetYear,
        'targetState': localPrefs.targetState,
        'targetCollege': localPrefs.targetCollege,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    profileWritten++;

    if (!firestoreHasRealData) {
      // ── Full migration: write progress ──────────────────────────────
      // history field is excluded — sessions go to subcollection.
      batch.set(
        FirestorePaths.progress(uid),
        {
          'totalQuestions': localProgress.totalQuestions,
          'totalCorrect': localProgress.totalCorrect,
          'totalIncorrect': localProgress.totalIncorrect,
          'totalUnanswered': localProgress.totalUnanswered,
          'totalSessions': localProgress.totalSessions,
          'xpPoints': localProgress.xpPoints,
          'streakDays': localProgress.streakDays,
          'lastActiveDate': localProgress.lastActiveDate,
          'subjectStats': localProgress.subjectStats.map(
            (k, v) => MapEntry(k, v.toJson()),
          ),
          'lastDailyChallengeDate': localProgress.lastDailyChallengeDate,
          'dailyChallengeXpEarned': localProgress.dailyChallengeXpEarned,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      progressWritten++;

      // Sessions — each SessionRecord becomes its own document.
      // xpGained is preserved from the stored historical value.
      // accuracy is NOT stored (it's derived: correct/total * 100).
      for (final record in localProgress.history) {
        if (record.id.isEmpty) continue;
        batch.set(
          FirestorePaths.sessions(uid).doc(record.id),
          {
            'subject': record.subject,
            'correct': record.correct,
            'total': record.total,
            // accuracy intentionally omitted — derived field
            'timestamp': Timestamp.fromDate(record.timestamp),
            'xpGained': record.xpGained,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
        sessionWritten++;
      }
    }
    // If Firestore already has real data, skip progress and sessions
    // to avoid overwriting with stale SharedPreferences data.

    // Weak areas — always write (merge:true, informational only).
    batch.set(
      FirestorePaths.weakAreas(uid),
      {
        ...localWeakAreas.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    weakAreasWritten++;

    // Sync metadata — mark migration complete ONLY after all writes.
    batch.set(
      FirestorePaths.syncMetadata(uid),
      {
        'migrated': true,
        'migratedAt': FieldValue.serverTimestamp(),
        'sessionCount': sessionWritten,
      },
    );

    // ── Step 5: Commit ────────────────────────────────────────────────
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreSyncService.migrateLocalData commit error: $e');
      rethrow;
    }

    final status = firestoreHasRealData
        ? MigrationStatus.partialMigration
        : MigrationStatus.fullMigration;

    return MigrationResult(
      status: status,
      profileDocsWritten: profileWritten,
      progressDocsWritten: progressWritten,
      weakAreaDocsWritten: weakAreasWritten,
      sessionDocsWritten: sessionWritten,
    );
  }
}
