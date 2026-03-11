import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Local skill stats for guest mode (mirrors SkillStats from user_model.dart)
class LocalSkillStats extends Equatable {
  final int totalAttempts;
  final int correctAnswers;

  const LocalSkillStats({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
  });

  double get accuracy => totalAttempts == 0 ? 0.0 : correctAnswers / totalAttempts;

  factory LocalSkillStats.fromMap(Map<String, dynamic> map) {
    return LocalSkillStats(
      totalAttempts: map['totalAttempts'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAttempts': totalAttempts,
      'correctAnswers': correctAnswers,
    };
  }

  LocalSkillStats copyWith({
    int? totalAttempts,
    int? correctAnswers,
  }) {
    return LocalSkillStats(
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
    );
  }

  @override
  List<Object?> get props => [totalAttempts, correctAnswers];
}

/// Local stats stored on device for guest users
class LocalStats extends Equatable {
  final int totalQuestionsAnswered;
  final int totalCorrect;
  final int totalXp;
  final int level;
  final Map<String, double> sectionAccuracy; // e.g., {'SAT_Math': 0.85}
  final Map<String, LocalSkillStats> skillStats; // e.g., {'SAT_Math_LinearEquations': LocalSkillStats}
  final int dailyStreakCount;
  final DateTime? lastActiveDate;
  final int bestDailyStreak;
  final int currentAccuracyStreak;
  final int bestAccuracyStreak;
  final int battlesPlayed;
  final int battlesWon;
  final Set<String> answeredQuestionIds;

  const LocalStats({
    this.totalQuestionsAnswered = 0,
    this.totalCorrect = 0,
    this.totalXp = 0,
    this.level = 1,
    this.sectionAccuracy = const {},
    this.skillStats = const {},
    this.dailyStreakCount = 0,
    this.lastActiveDate,
    this.bestDailyStreak = 0,
    this.currentAccuracyStreak = 0,
    this.bestAccuracyStreak = 0,
    this.battlesPlayed = 0,
    this.battlesWon = 0,
    this.answeredQuestionIds = const {},
  });

  double get overallAccuracy =>
      totalQuestionsAnswered == 0 ? 0.0 : totalCorrect / totalQuestionsAnswered;

  /// Calculate XP required for a level (same formula as authenticated users)
  static int xpForLevel(int level) => 100 * level * level;

  /// Calculate level from total XP
  static int levelFromXp(int totalXp) {
    int level = 1;
    while (totalXp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  factory LocalStats.fromJson(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return LocalStats.fromMap(map);
    } catch (e) {
      return const LocalStats();
    }
  }

  factory LocalStats.fromMap(Map<String, dynamic> map) {
    final skillStatsMap = <String, LocalSkillStats>{};
    if (map['skillStats'] != null) {
      final rawSkillStats = map['skillStats'] as Map<String, dynamic>;
      for (final entry in rawSkillStats.entries) {
        skillStatsMap[entry.key] = LocalSkillStats.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    return LocalStats(
      totalQuestionsAnswered: map['totalQuestionsAnswered'] ?? 0,
      totalCorrect: map['totalCorrect'] ?? 0,
      totalXp: map['totalXp'] ?? 0,
      level: map['level'] ?? 1,
      sectionAccuracy: Map<String, double>.from(map['sectionAccuracy'] ?? {}),
      skillStats: skillStatsMap,
      dailyStreakCount: map['dailyStreakCount'] ?? 0,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.parse(map['lastActiveDate'])
          : null,
      bestDailyStreak: map['bestDailyStreak'] ?? 0,
      currentAccuracyStreak: map['currentAccuracyStreak'] ?? 0,
      bestAccuracyStreak: map['bestAccuracyStreak'] ?? 0,
      battlesPlayed: map['battlesPlayed'] ?? 0,
      battlesWon: map['battlesWon'] ?? 0,
      answeredQuestionIds: Set<String>.from(map['answeredQuestionIds'] ?? []),
    );
  }

  String toJson() {
    return json.encode(toMap());
  }

  Map<String, dynamic> toMap() {
    return {
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrect': totalCorrect,
      'totalXp': totalXp,
      'level': level,
      'sectionAccuracy': sectionAccuracy,
      'skillStats': skillStats.map((k, v) => MapEntry(k, v.toMap())),
      'dailyStreakCount': dailyStreakCount,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'bestDailyStreak': bestDailyStreak,
      'currentAccuracyStreak': currentAccuracyStreak,
      'bestAccuracyStreak': bestAccuracyStreak,
      'battlesPlayed': battlesPlayed,
      'battlesWon': battlesWon,
      'answeredQuestionIds': answeredQuestionIds.toList(),
    };
  }

  LocalStats copyWith({
    int? totalQuestionsAnswered,
    int? totalCorrect,
    int? totalXp,
    int? level,
    Map<String, double>? sectionAccuracy,
    Map<String, LocalSkillStats>? skillStats,
    int? dailyStreakCount,
    DateTime? lastActiveDate,
    int? bestDailyStreak,
    int? currentAccuracyStreak,
    int? bestAccuracyStreak,
    int? battlesPlayed,
    int? battlesWon,
    Set<String>? answeredQuestionIds,
  }) {
    return LocalStats(
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      sectionAccuracy: sectionAccuracy ?? this.sectionAccuracy,
      skillStats: skillStats ?? this.skillStats,
      dailyStreakCount: dailyStreakCount ?? this.dailyStreakCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      bestDailyStreak: bestDailyStreak ?? this.bestDailyStreak,
      currentAccuracyStreak: currentAccuracyStreak ?? this.currentAccuracyStreak,
      bestAccuracyStreak: bestAccuracyStreak ?? this.bestAccuracyStreak,
      battlesPlayed: battlesPlayed ?? this.battlesPlayed,
      battlesWon: battlesWon ?? this.battlesWon,
      answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
    );
  }

  @override
  List<Object?> get props => [
        totalQuestionsAnswered,
        totalCorrect,
        totalXp,
        level,
        sectionAccuracy,
        skillStats,
        dailyStreakCount,
        lastActiveDate,
        bestDailyStreak,
        currentAccuracyStreak,
        bestAccuracyStreak,
        battlesPlayed,
        battlesWon,
        answeredQuestionIds,
      ];
}
