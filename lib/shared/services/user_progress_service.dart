import 'dart:convert';
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
    this.streakDays = 1,
    this.lastActiveDate = '',
    this.subjectStats = const {},
    this.history = const [],
    this.lastDailyChallengeDate = '',
    this.dailyChallengeXpEarned = 0,
  });

  double get overallAccuracy =>
      totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

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

  /// Dynamic estimated percentile among active NEET aspirants
  String get percentile {
    if (totalQuestions == 0) return "Unranked";
    if (overallAccuracy >= 90 && totalQuestions >= 50) return "Top 1%";
    if (overallAccuracy >= 80 && totalQuestions >= 30) return "Top 3%";
    if (overallAccuracy >= 70 && totalQuestions >= 20) return "Top 8%";
    if (overallAccuracy >= 60) return "Top 15%";
    if (overallAccuracy >= 50) return "Top 25%";
    return "Top 40%";
  }

  /// Estimated All-India Rank (AIR) based on performance & questions solved
  String get predictedAir {
    if (totalQuestions == 0) return "—";
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
      streakDays: json['streakDays'] as int? ?? 1,
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

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        var data = UserProgressData.fromJson(decoded);
        data = _checkStreak(data);
        progressNotifier.value = data;
      } else {
        // Initialize with default starting state & streak
        final nowStr = _todayString();
        final initialData = UserProgressData(
          lastActiveDate: nowStr,
          streakDays: 1,
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

  UserProgressData _checkStreak(UserProgressData data) {
    final today = _todayString();
    if (data.lastActiveDate == today) {
      return data;
    }

    if (data.lastActiveDate.isEmpty) {
      return UserProgressData(
        totalQuestions: data.totalQuestions,
        totalCorrect: data.totalCorrect,
        totalIncorrect: data.totalIncorrect,
        totalUnanswered: data.totalUnanswered,
        totalSessions: data.totalSessions,
        xpPoints: data.xpPoints,
        streakDays: 1,
        lastActiveDate: today,
        subjectStats: data.subjectStats,
        history: data.history,
        lastDailyChallengeDate: data.lastDailyChallengeDate,
        dailyChallengeXpEarned: data.dailyChallengeXpEarned,
      );
    }

    final lastDate = DateTime.tryParse(data.lastActiveDate);
    if (lastDate != null) {
      final now = DateTime.now();
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      int newStreak = data.streakDays;
      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1; // Streak reset
      }

      return UserProgressData(
        totalQuestions: data.totalQuestions,
        totalCorrect: data.totalCorrect,
        totalIncorrect: data.totalIncorrect,
        totalUnanswered: data.totalUnanswered,
        totalSessions: data.totalSessions,
        xpPoints: data.xpPoints + (difference == 1 ? 50 : 0), // Streak bonus
        streakDays: newStreak,
        lastActiveDate: today,
        subjectStats: data.subjectStats,
        history: data.history,
        lastDailyChallengeDate: data.lastDailyChallengeDate,
        dailyChallengeXpEarned: data.dailyChallengeXpEarned,
      );
    }

    return data;
  }

  Future<int> recordSession(PracticeSession session) async {
    final currentData = progressNotifier.value;

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
      streakDays: currentData.streakDays,
      lastActiveDate: _todayString(),
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
    final today = _todayString();
    final clearedData = UserProgressData(
      streakDays: 1,
      lastActiveDate: today,
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
