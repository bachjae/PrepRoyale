import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(ref);
});

class AchievementService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AchievementService(this._ref);

  CollectionReference get _achievementsRef =>
      _firestore.collection('achievements');

  // Seed default achievements to Firestore
  Future<void> seedAchievements() async {
    final batch = _firestore.batch();

    for (final achievement in DefaultAchievements.all) {
      final docRef = _achievementsRef.doc(achievement.id);
      batch.set(docRef, achievement.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  // Get all achievements
  Future<List<Achievement>> getAllAchievements() async {
    final query = await _achievementsRef.get();
    if (query.docs.isEmpty) {
      // Seed if empty
      await seedAchievements();
      return DefaultAchievements.all;
    }
    return query.docs.map((doc) => Achievement.fromFirestore(doc)).toList();
  }

  // Check and unlock achievements based on user stats
  Future<List<Achievement>> checkAndUnlockAchievements(UserModel user) async {
    final unlockedNow = <Achievement>[];
    final firebaseService = _ref.read(firebaseServiceProvider);

    for (final achievement in DefaultAchievements.all) {
      // Skip if already unlocked
      if (user.unlockedAchievements.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.category) {
        case AchievementCategory.questions:
          shouldUnlock = user.stats.totalQuestions >= achievement.requirement;
          break;
        case AchievementCategory.streaks:
          shouldUnlock = user.dailyStreak.count >= achievement.requirement ||
              user.dailyStreak.best >= achievement.requirement;
          break;
        case AchievementCategory.accuracy:
          shouldUnlock =
              user.accuracyStreak.current >= achievement.requirement ||
                  user.accuracyStreak.best >= achievement.requirement;
          break;
        case AchievementCategory.battles:
          // "battle_ready" achievement requires completing battles, not winning
          if (achievement.id == 'battle_ready') {
            shouldUnlock =
                user.battleStats.totalBattles >= achievement.requirement;
          } else {
            shouldUnlock = user.battleStats.wins >= achievement.requirement;
          }
          break;
        case AchievementCategory.level:
          shouldUnlock = user.level >= achievement.requirement;
          break;
        case AchievementCategory.social:
          // We don't have a direct field for friends count in stats yet,
          // so we'll need to check the local list if available or skip for now.
          // For now, let's assume it's tracked in a hypothetical meta field
          // or just implement the check later when we have a friends count.
          // (Actually, we can check user.unlockedAchievements for clues or add a field)
          // For simplicity, let's just make it always false until stats are updated.
          shouldUnlock = false;
          break;
      }

      if (shouldUnlock) {
        await firebaseService.unlockAchievement(user.id, achievement.id);
        await firebaseService.addXp(user.id, achievement.bonusXp);
        unlockedNow.add(achievement);
      }
    }

    return unlockedNow;
  }

  // Get user's achievement progress
  Map<String, AchievementProgress> getAchievementProgress(UserModel user) {
    final progress = <String, AchievementProgress>{};

    for (final achievement in DefaultAchievements.all) {
      int current = 0;

      switch (achievement.category) {
        case AchievementCategory.questions:
          current = user.stats.totalQuestions;
          break;
        case AchievementCategory.streaks:
          current = user.dailyStreak.best;
          break;
        case AchievementCategory.accuracy:
          current = user.accuracyStreak.best;
          break;
        case AchievementCategory.battles:
          current = user.battleStats.wins;
          break;
        case AchievementCategory.level:
          current = user.level;
          break;
        case AchievementCategory.social:
          current = 0; // Placeholder until we have friends count in UserModel
          break;
      }

      progress[achievement.id] = AchievementProgress(
        achievement: achievement,
        currentProgress: current,
        isUnlocked: user.unlockedAchievements.contains(achievement.id),
      );
    }

    return progress;
  }
}

class AchievementProgress {
  final Achievement achievement;
  final int currentProgress;
  final bool isUnlocked;

  AchievementProgress({
    required this.achievement,
    required this.currentProgress,
    required this.isUnlocked,
  });

  double get progressPercent {
    if (isUnlocked) return 1.0;
    return (currentProgress / achievement.requirement).clamp(0.0, 1.0);
  }
}
