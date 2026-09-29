import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/practice/models/practice_session.dart';

class SubjectStat {
  final String subject;
  final int totalQuestions;
  final int correctAnswers;
  final int sessionsCount;

  const SubjectStat({
    required this.subject,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.sessionsCount = 0,
  });

  double get accuracy =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'sessionsCount': sessionsCount,
      };

  factory SubjectStat.fromJson(Map<String, dynamic> json) => SubjectStat(
        subject: json['subject'] as String? ?? 'General',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        sessionsCount: json['sessionsCount'] as int? ?? 0,
      );

  SubjectStat copyWith({
    int? totalQuestions,
    int? correctAnswers,
    int? sessionsCount,
  }) =>
      SubjectStat(
        subject: subject,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        sessionsCount: sessionsCount ?? this.sessionsCount,
      );
}

class SessionRecord {
  final String id;
  final String subject;
  final int correct;
  final int total;
  final double accuracy;
  final DateTime timestamp;
  final int xpGained;

  SessionRecord({
    required this.id,
    required this.subject,
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.timestamp,
    required this.xpGained,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'correct': correct,
        'total': total,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'xpGained': xpGained,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String? ?? '',
        subject: json['subject'] as String? ?? 'Practice',
        correct: json['correct'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        xpGained: json['xpGained'] as int? ?? 0,
      );
}

class UserProgressData {
  final int totalQuestions;
  final int totalCorrect;
  final int totalIncorrect;
  final int totalUnanswered;
  final int totalSessions;
  final int xpPoints;
  final int streakDays;
  final String lastActiveDate;
  final Map<String, SubjectStat> subjectStats;
  final List<SessionRecord> history;

  // ── A-3: Daily NEET Challenge ─────────────────────────────────────────
  // `lastDailyChallengeDate` is the local "YYYY-MM-DD" on which the user
  // last completed the daily challenge. Empty string = never done. The
  // daily is one-per-day; the launcher reads `lastDailyChallengeDate`
  // against today to decide whether to show the locked-state button.
  final String lastDailyChallengeDate;
  final int dailyChallengeXpEarned;

  const UserProgressData({
    this.totalQuestions = 0,
    this.totalCorrect = 0,
    this.totalIncorrect = 0,
    this.totalUnanswered = 0,
    this.totalSessions = 0,
    this.xpPoints = 0,
    this.streakDays = 0,
    this.lastActiveDate = '',
    this.subjectStats = const {},
    this.history = const [],
    this.lastDailyChallengeDate = '',
    this.dailyChallengeXpEarned = 0,
  });

  double get overallAccuracy =>
      totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

  // ── B-5: 100-question ranking gate ──────────────────────────────────
  /// Percentile and predicted-AIR estimates are meaningless noise until the
  /// user has answered a real sample of questions. Below this count the
  /// user is "Unranked": rank-style chips show no number and the
  /// Analytics hero keeps its prediction locked.
  static const int rankingMinQuestions = 100;

  /// True once [rankingMinQuestions] questions have been answered and the
  /// percentile / AIR estimates become meaningful.
  bool get isRankingUnlocked => totalQuestions >= rankingMinQuestions;

  /// Questions still needed before ranking unlocks (0 when unlocked).
  int get rankingQuestionsRemaining =>
      (rankingMinQuestions - totalQuestions).clamp(0, rankingMinQuestions);

  String get tier {
    if (xpPoints >= 5000) return "Master";
    if (xpPoints >= 3000) return "Diamond";
    if (xpPoints >= 1500) return "Platinum";
    if (xpPoints >= 700) return "Gold";
    if (xpPoints >= 300) return "Silver";
    if (xpPoints >= 100) return "Bronze";
    return "Novice";
  }

  int get tierFloorXp {
    if (xpPoints >= 5000) return 5000;
    if (xpPoints >= 3000) return 3000;
    if (xpPoints >= 1500) return 1500;
    if (xpPoints >= 700) return 700;
    if (xpPoints >= 300) return 300;
    if (xpPoints >= 100) return 100;
    return 0;
  }

  int get nextTierTargetXp {
    if (xpPoints >= 5000) return 10000;
    if (xpPoints >= 3000) return 5000;
    if (xpPoints >= 1500) return 3000;
    if (xpPoints >= 700) return 1500;
    if (xpPoints >= 300) return 700;
    if (xpPoints >= 100) return 300;
    return 100;
  }

  double get tierProgress {
    final floor = tierFloorXp;
    final ceiling = nextTierTargetXp;
    if (ceiling == floor) return 1.0;
    return ((xpPoints - floor) / (ceiling - floor)).clamp(0.0, 1.0);
  }

  /// Dynamic estimated percentile among active NEET aspirants.
  /// B-5: returns "Unranked" until 100 questions have been answered.
  String get percentile {
    if (!isRankingUnlocked) return "Unranked";
    if (overallAccuracy >= 90 && totalQuestions >= 50) return "Top 1%";
    if (overallAccuracy >= 80 && totalQuestions >= 30) return "Top 3%";
    if (overallAccuracy >= 70 && totalQuestions >= 20) return "Top 8%";
    if (overallAccuracy >= 60) return "Top 15%";
    if (overallAccuracy >= 50) return "Top 25%";
    return "Top 40%";
  }

  /// Estimated All-India Rank (AIR) based on performance & questions solved.
  /// B-5: returns "Locked" until 100 questions have been answered.
  String get predictedAir {
    if (!isRankingUnlocked) return "Locked";
    final effectiveScore = (overallAccuracy * 7.2).round(); // out of 720
    if (effectiveScore >= 680) return "AIR #340";
    if (effectiveScore >= 650) return "AIR #1,120";
    if (effectiveScore >= 600) return "AIR #3,850";
    if (effectiveScore >= 550) return "AIR #8,400";
    if (effectiveScore >= 500) return "AIR #16,200";
    return "AIR #28,000+";
  }

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'totalCorrect': totalCorrect,
        'totalIncorrect': totalIncorrect,
        'totalUnanswered': totalUnanswered,
        'totalSessions': totalSessions,
        'xpPoints': xpPoints,
        'streakDays': streakDays,
        'lastActiveDate': lastActiveDate,
        'subjectStats':
            subjectStats.map((key, value) => MapEntry(key, value.toJson())),
        'history': history.map((e) => e.toJson()).toList(),
        'lastDailyChallengeDate': lastDailyChallengeDate,
        'dailyChallengeXpEarned': dailyChallengeXpEarned,
      };

  factory UserProgressData.fromJson(Map<String, dynamic> json) {
    final subjectStatsJson = json['subjectStats'] as Map<String, dynamic>?;
    final Map<String, SubjectStat> parsedStats = {};
    if (subjectStatsJson != null) {
      subjectStatsJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedStats[key] = SubjectStat.fromJson(value);
        }
      });
    }

    final historyJson = json['history'] as List<dynamic>?;
    final List<SessionRecord> parsedHistory = [];
    if (historyJson != null) {
      for (final item in historyJson) {
        if (item is Map<String, dynamic>) {
          parsedHistory.add(SessionRecord.fromJson(item));
        }
      }
    }

    return UserProgressData(
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalIncorrect: json['totalIncorrect'] as int? ?? 0,
      totalUnanswered: json['totalUnanswered'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      xpPoints: json['xpPoints'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String? ?? '',
      subjectStats: parsedStats,
      history: parsedHistory,
      lastDailyChallengeDate:
          json['lastDailyChallengeDate'] as String? ?? '',
      dailyChallengeXpEarned: json['dailyChallengeXpEarned'] as int? ?? 0,
    );
  }
}

class UserProgressService {
  UserProgressService._();
  static final UserProgressService instance = UserProgressService._();

  static const String _storageKey = 'coderank_user_progress_v1';

  final ValueNotifier<UserProgressData> progressNotifier =
      ValueNotifier<UserProgressData>(const UserProgressData());

  UserProgressData get current => progressNotifier.value;

  // ── Firebase UID lifecycle ──────────────────────────────────────────
  // Nullable — null when no user is signed in or Firebase is not yet
  // initialized.  Safe to read from any isolate; mutations are only
  // expected from the main isolate (AuthGate / initialize).
  String? _userId;

  /// The currently authenticated Firebase Auth UID, or `null` when
  /// signed out.
  String? get userId => _userId;

  /// Called by [AuthGate] when [authStateChanges] emits an authenticated
  /// [User], and once during [initialize] from the cached session.
  void setUserId(String uid) => _userId = uid;

  /// Called by [AuthGate] when the user signs out.
  void clearUserId() => _userId = null;

  Future<void> initialize() async {
    // ── Hydrate UID from any previously cached Firebase session ──────
    // Safe to call when Firebase is not initialized (tests, early boot):
    // the catch block below swallows the error.
    if (Firebase.apps.isNotEmpty) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) _userId = uid;
      } catch (_) {
        // Firebase not ready yet or not signed in — UID stays null.
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        var data = UserProgressData.fromJson(decoded);
        // AUD-2: the streak counts consecutive days with at least one
        // COMPLETED SESSION — opening the app neither extends nor resets
        // it. App-open only expires a streak that is already dead (last
        // practiced before yesterday); see `_expireStreakIfStale`.
        data = _expireStreakIfStale(data);
        progressNotifier.value = data;
      } else {
        // Brand-new user: no streak, nothing practiced yet.
        final initialData = UserProgressData(
          subjectStats: const {
            'Physics': SubjectStat(subject: 'Physics'),
            'Chemistry': SubjectStat(subject: 'Chemistry'),
            'Biology': SubjectStat(subject: 'Biology'),
          },
        );
        progressNotifier.value = initialData;
        await _persist(initialData);
      }
    } catch (e) {
      debugPrint('Error initializing UserProgressService: $e');
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String _yesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
  }

  /// AUD-2: A streak only survives while the user keeps practicing.
  /// `lastActiveDate` is the last day a session was completed, so:
  ///   * practiced today or yesterday → streak still alive (it dies at
  ///     midnight if today goes unpracticed — the usual grace window),
  ///   * last practiced earlier      → streak is dead, expire to 0.
  /// No XP is ever awarded here — opening the app earns nothing.
  UserProgressData _expireStreakIfStale(UserProgressData data) {
    final last = data.lastActiveDate;
    if (last.isEmpty ||
        last == _todayString() ||
        last == _yesterdayString()) {
      return data;
    }
    // Streak is dead.
    return UserProgressData(
      totalQuestions: data.totalQuestions,
      totalCorrect: data.totalCorrect,
      totalIncorrect: data.totalIncorrect,
      totalUnanswered: data.totalUnanswered,
      totalSessions: data.totalSessions,
      xpPoints: data.xpPoints,
      streakDays: 0,
      lastActiveDate: data.lastActiveDate,
      subjectStats: data.subjectStats,
      history: data.history,
      lastDailyChallengeDate: data.lastDailyChallengeDate,
      dailyChallengeXpEarned: data.dailyChallengeXpEarned,
    );
  }

  Future<int> recordSession(PracticeSession session) async {
    final currentData = progressNotifier.value;

    // ── Streak engine (AUD-2) ────────────────────────────────────────
    // A day counts toward the streak when at least one session is
    // completed on it. Practicing on consecutive days extends the
    // streak; any gap restarts it at 1. The +50 "open the app" bonus
    // is gone — the daily challenge (+50) is the recurring reward.
    final today = _todayString();
    int newStreak = currentData.streakDays;
    String newLastActive = currentData.lastActiveDate;
    if (currentData.lastActiveDate != today) {
      newStreak =
          currentData.lastActiveDate == _yesterdayString()
              ? currentData.streakDays + 1
              : 1;
      newLastActive = today;
    }

    // Calculate XP earned in this session
    // +15 XP for each correct answer
    // +5 XP for each completed question attempt
    // +30 bonus XP for high accuracy (>= 80%)
    int sessionXp = (session.correctAnswers * 15) + (session.completedQuestions.length * 5);
    if (session.accuracy >= 80 && session.totalQuestions >= 5) {
      sessionXp += 30;
    }

    final newTotalQuestions = currentData.totalQuestions + session.completedQuestions.length;
    final newTotalCorrect = currentData.totalCorrect + session.correctAnswers;
    final newTotalIncorrect = currentData.totalIncorrect + session.incorrectAnswers;
    final newTotalUnanswered = currentData.totalUnanswered + session.unansweredQuestions;
    final newTotalSessions = currentData.totalSessions + 1;
    final newXp = currentData.xpPoints + sessionXp;

    // Update Subject Stats
    final updatedSubjectStats = Map<String, SubjectStat>.from(currentData.subjectStats);
    final subjectKey = session.subject.trim();
    final existingSubStat = updatedSubjectStats[subjectKey] ?? SubjectStat(subject: subjectKey);

    updatedSubjectStats[subjectKey] = existingSubStat.copyWith(
      totalQuestions: existingSubStat.totalQuestions + session.completedQuestions.length,
      correctAnswers: existingSubStat.correctAnswers + session.correctAnswers,
      sessionsCount: existingSubStat.sessionsCount + 1,
    );

    // Create session record
    final record = SessionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: session.subject,
      correct: session.correctAnswers,
      total: session.totalQuestions,
      accuracy: session.accuracy,
      timestamp: DateTime.now(),
      xpGained: sessionXp,
    );

    final updatedHistory = [record, ...currentData.history];
    if (updatedHistory.length > 50) {
      updatedHistory.removeLast();
    }

    final updatedData = UserProgressData(
      totalQuestions: newTotalQuestions,
      totalCorrect: newTotalCorrect,
      totalIncorrect: newTotalIncorrect,
      totalUnanswered: newTotalUnanswered,
      totalSessions: newTotalSessions,
      xpPoints: newXp,
      streakDays: newStreak,
      lastActiveDate: newLastActive,
      subjectStats: updatedSubjectStats,
      history: updatedHistory,
      lastDailyChallengeDate: currentData.lastDailyChallengeDate,
      dailyChallengeXpEarned: currentData.dailyChallengeXpEarned,
    );

    progressNotifier.value = updatedData;
    await _persist(updatedData);

    return sessionXp;
  }

  Future<void> addXp(int bonusXp) async {
    final currentData = progressNotifier.value;
    final updatedData = UserProgressData(
      totalQuestions: currentData.totalQuestions,
      totalCorrect: currentData.totalCorrect,
      totalIncorrect: currentData.totalIncorrect,
      totalUnanswered: currentData.totalUnanswered,
      totalSessions: currentData.totalSessions,
      xpPoints: currentData.xpPoints + bonusXp,
      streakDays: currentData.streakDays,
      lastActiveDate: currentData.lastActiveDate,
      subjectStats: currentData.subjectStats,
      history: currentData.history,
      lastDailyChallengeDate: currentData.lastDailyChallengeDate,
      dailyChallengeXpEarned: currentData.dailyChallengeXpEarned,
    );
    progressNotifier.value = updatedData;
    await _persist(updatedData);
  }

  Future<void> resetProgress() async {
    final clearedData = UserProgressData(
      streakDays: 0,
      lastActiveDate: '',
      subjectStats: const {
        'Physics': SubjectStat(subject: 'Physics'),
        'Chemistry': SubjectStat(subject: 'Chemistry'),
        'Biology': SubjectStat(subject: 'Biology'),
      },
    );
    progressNotifier.value = clearedData;
    await _persist(clearedData);
  }

  // ── A-3: Daily NEET Challenge ─────────────────────────────────────────

  /// True iff the user has completed today's daily challenge.
  bool dailyChallengeCompletedToday() {
    final today = _todayString();
    return progressNotifier.value.lastDailyChallengeDate == today;
  }

  /// Stamp today's date as "daily challenge completed" and accumulate the
  /// XP earned from the daily into the all-time total. Call this AFTER
  /// `recordSession` (which records the 10-question session XP) and AFTER
  /// `addXp(50)` (which awards the +50 completion bonus). The [xpEarned]
  /// arg here is the sum of those two — we add it to the
  /// `dailyChallengeXpEarned` running total.
  Future<void> markDailyChallengeCompleted({required int xpEarned}) async {
    final currentData = progressNotifier.value;
    final updatedData = UserProgressData(
      totalQuestions: currentData.totalQuestions,
      totalCorrect: currentData.totalCorrect,
      totalIncorrect: currentData.totalIncorrect,
      totalUnanswered: currentData.totalUnanswered,
      totalSessions: currentData.totalSessions,
      xpPoints: currentData.xpPoints,
      streakDays: currentData.streakDays,
      lastActiveDate: currentData.lastActiveDate,
      subjectStats: currentData.subjectStats,
      history: currentData.history,
      lastDailyChallengeDate: _todayString(),
      dailyChallengeXpEarned:
          currentData.dailyChallengeXpEarned + xpEarned,
    );
    progressNotifier.value = updatedData;
    await _persist(updatedData);
  }

  Future<void> _persist(UserProgressData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving UserProgress: $e');
    }
  }
}
