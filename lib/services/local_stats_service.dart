import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/local_stats.dart';

/// Keys for SharedPreferences
class LocalStatsKeys {
  static const String guestId = 'guest_id';
  static const String guestStats = 'guest_stats';
  static const String isGuestMode = 'is_guest_mode';
}

/// Provider for LocalStatsService
final localStatsServiceProvider = Provider<LocalStatsService>((ref) {
  return LocalStatsService();
});

/// Service for managing guest user stats stored locally
class LocalStatsService {
  static const _uuid = Uuid();

  /// Get or create a unique guest ID for this device
  Future<String> getOrCreateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    var guestId = prefs.getString(LocalStatsKeys.guestId);

    if (guestId == null) {
      guestId = 'guest_${_uuid.v4()}';
      await prefs.setString(LocalStatsKeys.guestId, guestId);
    }

    return guestId;
  }

  /// Check if the user has chosen guest mode
  Future<bool> isGuestModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(LocalStatsKeys.isGuestMode) ?? false;
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LocalStatsKeys.isGuestMode, true);
  }

  /// Disable guest mode (when user logs in)
  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LocalStatsKeys.isGuestMode, false);
  }

  /// Get the current guest stats
  Future<LocalStats> getGuestStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(LocalStatsKeys.guestStats);

    if (statsJson == null) {
      return const LocalStats();
    }

    return LocalStats.fromJson(statsJson);
  }

  /// Save guest stats
  Future<void> saveGuestStats(LocalStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalStatsKeys.guestStats, stats.toJson());
  }

  /// Update guest stats after answering a question
  Future<LocalStats> updateGuestStats({
    required String questionId,
    required String sectionKey,
    required bool isCorrect,
    String? skill,
    int xpEarned = 0,
  }) async {
    var stats = await getGuestStats();

    // Skip if already answered this question
    if (stats.answeredQuestionIds.contains(questionId)) {
      return stats;
    }

    // Update basic stats
    final newTotal = stats.totalQuestionsAnswered + 1;
    final newCorrect = stats.totalCorrect + (isCorrect ? 1 : 0);
    final newXp = stats.totalXp + xpEarned;
    final newLevel = LocalStats.levelFromXp(newXp);

    // Update answered questions
    final newAnsweredIds = Set<String>.from(stats.answeredQuestionIds)..add(questionId);

    // Update section accuracy
    final newSectionAccuracy = Map<String, double>.from(stats.sectionAccuracy);
    final currentSectionCorrect = (newSectionAccuracy[sectionKey] ?? 0.0) *
        stats.answeredQuestionIds.length;
    final sectionQuestionCount = stats.answeredQuestionIds.length + 1;
    newSectionAccuracy[sectionKey] =
        (currentSectionCorrect + (isCorrect ? 1 : 0)) / sectionQuestionCount;

    // Update skill stats if skill is provided
    final newSkillStats = Map<String, LocalSkillStats>.from(stats.skillStats);
    if (skill != null) {
      final skillKey = '${sectionKey}_$skill';
      final currentSkillStats = stats.skillStats[skillKey] ??
          const LocalSkillStats(totalAttempts: 0, correctAnswers: 0);
      newSkillStats[skillKey] = LocalSkillStats(
        totalAttempts: currentSkillStats.totalAttempts + 1,
        correctAnswers: currentSkillStats.correctAnswers + (isCorrect ? 1 : 0),
      );
    }

    // Update accuracy streak
    int newAccuracyStreak;
    int newBestAccuracyStreak;
    if (isCorrect) {
      newAccuracyStreak = stats.currentAccuracyStreak + 1;
      newBestAccuracyStreak = newAccuracyStreak > stats.bestAccuracyStreak
          ? newAccuracyStreak
          : stats.bestAccuracyStreak;
    } else {
      newAccuracyStreak = 0;
      newBestAccuracyStreak = stats.bestAccuracyStreak;
    }

    // Update daily streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newDailyStreak = stats.dailyStreakCount;
    int newBestDailyStreak = stats.bestDailyStreak;
    DateTime newLastActiveDate = today;

    if (stats.lastActiveDate != null) {
      final lastDay = DateTime(
        stats.lastActiveDate!.year,
        stats.lastActiveDate!.month,
        stats.lastActiveDate!.day,
      );
      final difference = today.difference(lastDay).inDays;

      if (difference == 0) {
        // Same day, no change
      } else if (difference == 1) {
        // Consecutive day
        newDailyStreak++;
        if (newDailyStreak > newBestDailyStreak) {
          newBestDailyStreak = newDailyStreak;
        }
      } else {
        // Streak broken
        newDailyStreak = 1;
      }
    } else {
      // First activity
      newDailyStreak = 1;
    }

    stats = stats.copyWith(
      totalQuestionsAnswered: newTotal,
      totalCorrect: newCorrect,
      totalXp: newXp,
      level: newLevel,
      sectionAccuracy: newSectionAccuracy,
      skillStats: newSkillStats,
      currentAccuracyStreak: newAccuracyStreak,
      bestAccuracyStreak: newBestAccuracyStreak,
      dailyStreakCount: newDailyStreak,
      bestDailyStreak: newBestDailyStreak,
      lastActiveDate: newLastActiveDate,
      answeredQuestionIds: newAnsweredIds,
    );

    await saveGuestStats(stats);
    return stats;
  }

  /// Update guest battle stats
  Future<LocalStats> updateGuestBattleStats({required bool isWinner}) async {
    var stats = await getGuestStats();

    stats = stats.copyWith(
      battlesPlayed: stats.battlesPlayed + 1,
      battlesWon: stats.battlesWon + (isWinner ? 1 : 0),
    );

    await saveGuestStats(stats);
    return stats;
  }

  /// Add XP to guest stats
  Future<LocalStats> addGuestXp(int xpAmount) async {
    var stats = await getGuestStats();

    final newXp = stats.totalXp + xpAmount;
    final newLevel = LocalStats.levelFromXp(newXp);

    stats = stats.copyWith(
      totalXp: newXp,
      level: newLevel,
    );

    await saveGuestStats(stats);
    return stats;
  }

  /// Check if a question has already been answered by guest
  Future<bool> hasAnsweredQuestion(String questionId) async {
    final stats = await getGuestStats();
    return stats.answeredQuestionIds.contains(questionId);
  }

  /// Get set of answered question IDs
  Future<Set<String>> getAnsweredQuestionIds() async {
    final stats = await getGuestStats();
    return stats.answeredQuestionIds;
  }

  /// Clear all guest stats (for testing or when user requests)
  Future<void> clearGuestStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStatsKeys.guestStats);
    // Keep the guest ID for continuity
  }

  /// Export guest stats for migration to authenticated account
  Future<Map<String, dynamic>> exportGuestStatsForMigration() async {
    final stats = await getGuestStats();
    return {
      'totalQuestionsAnswered': stats.totalQuestionsAnswered,
      'totalCorrect': stats.totalCorrect,
      'totalXp': stats.totalXp,
      'level': stats.level,
      'sectionAccuracy': stats.sectionAccuracy,
      'skillStats': stats.skillStats.map((k, v) => MapEntry(k, v.toMap())),
      'battlesPlayed': stats.battlesPlayed,
      'battlesWon': stats.battlesWon,
      'dailyStreakCount': stats.dailyStreakCount,
      'lastActiveDate': stats.lastActiveDate?.toIso8601String(),
      'bestDailyStreak': stats.bestDailyStreak,
      'currentAccuracyStreak': stats.currentAccuracyStreak,
      'bestAccuracyStreak': stats.bestAccuracyStreak,
      'answeredQuestionIds': stats.answeredQuestionIds.toList(),
    };
  }
}
