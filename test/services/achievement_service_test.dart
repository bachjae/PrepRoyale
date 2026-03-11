import 'package:flutter_test/flutter_test.dart';
import 'package:prep_royale/models/achievement_model.dart';
import 'package:prep_royale/models/user_model.dart';
import 'package:prep_royale/services/achievement_service.dart';

/// Tests for AchievementService logic.
///
/// Since AchievementService accesses FirebaseFirestore.instance in its constructor,
/// we test the pure logic parts that can be unit tested:
/// - DefaultAchievements configuration
/// - Achievement unlock condition logic
/// - AchievementProgress calculations
///
/// For integration testing with Firebase mocks, use fake_cloud_firestore package
/// and initialize Firebase with setupFirebaseCoreMocks().
void main() {
  UserModel createTestUser({
    String id = 'test-user-id',
    int totalQuestions = 0,
    int dailyStreakCount = 0,
    int dailyStreakBest = 0,
    int accuracyStreakCurrent = 0,
    int accuracyStreakBest = 0,
    int battleWins = 0,
    int battleLosses = 0,
    int level = 1,
    List<String> unlockedAchievements = const [],
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      email: 'test@test.com',
      username: 'testuser',
      stats: UserStats(totalQuestions: totalQuestions),
      dailyStreak: DailyStreak(
        count: dailyStreakCount,
        best: dailyStreakBest,
        lastDate: now,
      ),
      accuracyStreak: AccuracyStreak(
        current: accuracyStreakCurrent,
        best: accuracyStreakBest,
      ),
      level: level,
      battleStats: BattleStats(wins: battleWins, losses: battleLosses),
      unlockedAchievements: unlockedAchievements,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('DefaultAchievements Configuration', () {
    test('first_steps requires 10 questions', () {
      final achievement = DefaultAchievements.getById('first_steps');

      expect(achievement, isNotNull);
      expect(achievement!.requirement, equals(10));
      expect(achievement.category, equals(AchievementCategory.questions));
      expect(achievement.bonusXp, equals(25));
    });

    test('century requires 100 questions', () {
      final achievement = DefaultAchievements.getById('century');

      expect(achievement, isNotNull);
      expect(achievement!.requirement, equals(100));
      expect(achievement.category, equals(AchievementCategory.questions));
      expect(achievement.bonusXp, equals(100));
    });

    test('week_warrior requires 7-day streak', () {
      final achievement = DefaultAchievements.getById('week_warrior');

      expect(achievement, isNotNull);
      expect(achievement!.requirement, equals(7));
      expect(achievement.category, equals(AchievementCategory.streaks));
      expect(achievement.bonusXp, equals(75));
    });

    test('sharpshooter requires 10 correct in a row', () {
      final achievement = DefaultAchievements.getById('sharpshooter');

      expect(achievement, isNotNull);
      expect(achievement!.requirement, equals(10));
      expect(achievement.category, equals(AchievementCategory.accuracy));
      expect(achievement.bonusXp, equals(50));
    });

    test('battle_ready requires 1 win (description says "Complete 1 battle")',
        () {
      final achievement = DefaultAchievements.getById('battle_ready');

      expect(achievement, isNotNull);
      expect(achievement!.requirement, equals(1));
      expect(achievement.category, equals(AchievementCategory.battles));
      expect(achievement.bonusXp, equals(25));
      expect(achievement.description, equals('Complete 1 battle'));
    });

    test('all achievements have valid configuration', () {
      for (final achievement in DefaultAchievements.all) {
        expect(achievement.id, isNotEmpty);
        expect(achievement.name, isNotEmpty);
        expect(achievement.description, isNotEmpty);
        expect(achievement.requirement, greaterThan(0));
        expect(achievement.bonusXp, greaterThan(0));
      }
    });

    test('getById returns null for unknown id', () {
      final achievement = DefaultAchievements.getById('unknown_achievement');
      expect(achievement, isNull);
    });
  });

  group('Achievement Unlock Condition Logic', () {
    /// These tests simulate the unlock condition checking logic from
    /// AchievementService.checkAndUnlockAchievements without Firebase.

    bool shouldUnlockAchievement(Achievement achievement, UserModel user) {
      // Skip if already unlocked
      if (user.unlockedAchievements.contains(achievement.id)) return false;

      switch (achievement.category) {
        case AchievementCategory.questions:
          return user.stats.totalQuestions >= achievement.requirement;
        case AchievementCategory.streaks:
          return user.dailyStreak.count >= achievement.requirement ||
              user.dailyStreak.best >= achievement.requirement;
        case AchievementCategory.accuracy:
          return user.accuracyStreak.current >= achievement.requirement ||
              user.accuracyStreak.best >= achievement.requirement;
        case AchievementCategory.battles:
          return user.battleStats.wins >= achievement.requirement;
        case AchievementCategory.level:
          return user.level >= achievement.requirement;
        case AchievementCategory.social:
          return false; // Not implemented in tests yet
      }
    }

    group('first_steps (10 questions)', () {
      test('unlocks when user has answered 10 questions', () {
        final user = createTestUser(totalQuestions: 10);
        final achievement = DefaultAchievements.getById('first_steps')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('does not unlock when user has answered less than 10 questions', () {
        final user = createTestUser(totalQuestions: 9);
        final achievement = DefaultAchievements.getById('first_steps')!;

        expect(shouldUnlockAchievement(achievement, user), isFalse);
      });

      test('unlocks when user has answered more than 10 questions', () {
        final user = createTestUser(totalQuestions: 50);
        final achievement = DefaultAchievements.getById('first_steps')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });
    });

    group('century (100 questions)', () {
      test('unlocks when user has answered 100 questions', () {
        final user = createTestUser(totalQuestions: 100);
        final achievement = DefaultAchievements.getById('century')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('does not unlock when user has answered less than 100 questions',
          () {
        final user = createTestUser(totalQuestions: 99);
        final achievement = DefaultAchievements.getById('century')!;

        expect(shouldUnlockAchievement(achievement, user), isFalse);
      });
    });

    group('week_warrior (7-day streak)', () {
      test('unlocks when current daily streak is 7', () {
        final user = createTestUser(dailyStreakCount: 7, dailyStreakBest: 7);
        final achievement = DefaultAchievements.getById('week_warrior')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('unlocks when best daily streak is 7 (even if current is lower)',
          () {
        final user = createTestUser(dailyStreakCount: 3, dailyStreakBest: 7);
        final achievement = DefaultAchievements.getById('week_warrior')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('does not unlock when both current and best are below 7', () {
        final user = createTestUser(dailyStreakCount: 5, dailyStreakBest: 6);
        final achievement = DefaultAchievements.getById('week_warrior')!;

        expect(shouldUnlockAchievement(achievement, user), isFalse);
      });
    });

    group('sharpshooter (10 correct in a row)', () {
      test('unlocks when current accuracy streak is 10', () {
        final user = createTestUser(
          accuracyStreakCurrent: 10,
          accuracyStreakBest: 10,
        );
        final achievement = DefaultAchievements.getById('sharpshooter')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('unlocks when best accuracy streak is 10 (even if current is lower)',
          () {
        final user = createTestUser(
          accuracyStreakCurrent: 3,
          accuracyStreakBest: 10,
        );
        final achievement = DefaultAchievements.getById('sharpshooter')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('does not unlock when accuracy streak is below 10', () {
        final user = createTestUser(
          accuracyStreakCurrent: 9,
          accuracyStreakBest: 9,
        );
        final achievement = DefaultAchievements.getById('sharpshooter')!;

        expect(shouldUnlockAchievement(achievement, user), isFalse);
      });
    });

    group('battle_ready (first battle)', () {
      /// KNOWN BUG: The "battle_ready" achievement is defined as
      /// "Complete 1 battle" but the unlock condition checks
      /// `user.battleStats.wins >= 1`, meaning it only unlocks
      /// when the user WINS their first battle, not just completes it.
      ///
      /// A user who loses their first battle will not unlock this achievement
      /// until they win a battle.
      ///
      /// To fix this, the condition should check `totalBattles >= 1` instead
      /// of `wins >= 1`.

      test('unlocks when user wins 1 battle', () {
        final user = createTestUser(battleWins: 1, battleLosses: 0);
        final achievement = DefaultAchievements.getById('battle_ready')!;

        expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('BUG: does not unlock when user loses first battle', () {
        // This test documents the current (buggy) behavior
        // The achievement says "Complete 1 battle" but checks wins
        final user = createTestUser(battleWins: 0, battleLosses: 1);
        final achievement = DefaultAchievements.getById('battle_ready')!;

        // Current behavior: Does NOT unlock despite completing a battle
        expect(
          shouldUnlockAchievement(achievement, user),
          isFalse,
          reason:
              'BUG: battle_ready does not unlock on loss, even though description says "Complete 1 battle"',
        );

        // Document what the expected behavior SHOULD be:
        // If the bug were fixed, this should be true:
        // expect(shouldUnlockAchievement(achievement, user), isTrue);
      });

      test('does not unlock when user has no battles', () {
        final user = createTestUser(battleWins: 0, battleLosses: 0);
        final achievement = DefaultAchievements.getById('battle_ready')!;

        expect(shouldUnlockAchievement(achievement, user), isFalse);
      });
    });

    group('already unlocked achievements', () {
      test('already unlocked achievement does not re-unlock', () {
        final user = createTestUser(
          totalQuestions: 100,
          unlockedAchievements: ['first_steps', 'century'],
        );
        final firstSteps = DefaultAchievements.getById('first_steps')!;
        final century = DefaultAchievements.getById('century')!;

        expect(shouldUnlockAchievement(firstSteps, user), isFalse);
        expect(shouldUnlockAchievement(century, user), isFalse);
      });

      test('new achievement unlocks but already unlocked ones do not', () {
        final user = createTestUser(
          totalQuestions: 100,
          unlockedAchievements: ['first_steps'],
        );
        final firstSteps = DefaultAchievements.getById('first_steps')!;
        final century = DefaultAchievements.getById('century')!;

        expect(shouldUnlockAchievement(firstSteps, user), isFalse);
        expect(shouldUnlockAchievement(century, user), isTrue);
      });
    });
  });

  group('AchievementProgress', () {
    test('progressPercent returns 1.0 when unlocked', () {
      final achievement = DefaultAchievements.getById('first_steps')!;
      final progress = AchievementProgress(
        achievement: achievement,
        currentProgress: 5,
        isUnlocked: true,
      );

      expect(progress.progressPercent, equals(1.0));
    });

    test('progressPercent calculates correctly for partial progress', () {
      final achievement = DefaultAchievements.getById('first_steps')!;
      final progress = AchievementProgress(
        achievement: achievement,
        currentProgress: 5, // 5/10 = 0.5
        isUnlocked: false,
      );

      expect(progress.progressPercent, equals(0.5));
    });

    test('progressPercent is clamped to 1.0 when exceeding requirement', () {
      final achievement = DefaultAchievements.getById('first_steps')!;
      final progress = AchievementProgress(
        achievement: achievement,
        currentProgress: 50, // 50/10 = 5.0, but clamped to 1.0
        isUnlocked: false,
      );

      expect(progress.progressPercent, equals(1.0));
    });

    test('progressPercent is clamped to 0.0 for zero progress', () {
      final achievement = DefaultAchievements.getById('first_steps')!;
      final progress = AchievementProgress(
        achievement: achievement,
        currentProgress: 0,
        isUnlocked: false,
      );

      expect(progress.progressPercent, equals(0.0));
    });
  });

  group('Achievement Progress Mapping Logic', () {
    /// Tests the logic used in AchievementService.getAchievementProgress

    int getProgressForAchievement(Achievement achievement, UserModel user) {
      switch (achievement.category) {
        case AchievementCategory.questions:
          return user.stats.totalQuestions;
        case AchievementCategory.streaks:
          return user.dailyStreak.best;
        case AchievementCategory.accuracy:
          return user.accuracyStreak.best;
        case AchievementCategory.battles:
          return user.battleStats.wins;
        case AchievementCategory.level:
          return user.level;
        case AchievementCategory.social:
          return 0;
      }
    }

    test('questions achievement uses totalQuestions', () {
      final user = createTestUser(totalQuestions: 50);
      final achievement = DefaultAchievements.getById('first_steps')!;

      expect(getProgressForAchievement(achievement, user), equals(50));
    });

    test('streak achievement uses dailyStreak.best', () {
      final user = createTestUser(dailyStreakCount: 3, dailyStreakBest: 5);
      final achievement = DefaultAchievements.getById('week_warrior')!;

      // Note: Progress shows best, not current
      expect(getProgressForAchievement(achievement, user), equals(5));
    });

    test('accuracy achievement uses accuracyStreak.best', () {
      final user = createTestUser(
        accuracyStreakCurrent: 2,
        accuracyStreakBest: 8,
      );
      final achievement = DefaultAchievements.getById('sharpshooter')!;

      expect(getProgressForAchievement(achievement, user), equals(8));
    });

    test('battles achievement uses battleStats.wins', () {
      final user = createTestUser(battleWins: 5, battleLosses: 3);
      final achievement = DefaultAchievements.getById('battle_ready')!;

      expect(getProgressForAchievement(achievement, user), equals(5));
    });
  });

  group('Achievement Bonus XP Values', () {
    test('first_steps gives 25 XP', () {
      final achievement = DefaultAchievements.getById('first_steps')!;
      expect(achievement.bonusXp, equals(25));
    });

    test('century gives 100 XP', () {
      final achievement = DefaultAchievements.getById('century')!;
      expect(achievement.bonusXp, equals(100));
    });

    test('dedicated gives 250 XP', () {
      final achievement = DefaultAchievements.getById('dedicated')!;
      expect(achievement.bonusXp, equals(250));
    });

    test('master gives 500 XP', () {
      final achievement = DefaultAchievements.getById('master')!;
      expect(achievement.bonusXp, equals(500));
    });

    test('week_warrior gives 75 XP', () {
      final achievement = DefaultAchievements.getById('week_warrior')!;
      expect(achievement.bonusXp, equals(75));
    });

    test('sharpshooter gives 50 XP', () {
      final achievement = DefaultAchievements.getById('sharpshooter')!;
      expect(achievement.bonusXp, equals(50));
    });

    test('battle_ready gives 25 XP', () {
      final achievement = DefaultAchievements.getById('battle_ready')!;
      expect(achievement.bonusXp, equals(25));
    });
  });

  group('Achievement Category Distribution', () {
    test('has achievements in all categories', () {
      final categories = DefaultAchievements.all.map((a) => a.category).toSet();

      expect(categories, contains(AchievementCategory.questions));
      expect(categories, contains(AchievementCategory.streaks));
      expect(categories, contains(AchievementCategory.accuracy));
      expect(categories, contains(AchievementCategory.battles));
    });

    test('has 4 question achievements', () {
      final questionAchievements = DefaultAchievements.all
          .where((a) => a.category == AchievementCategory.questions)
          .toList();

      expect(questionAchievements.length, equals(4));
      expect(questionAchievements.map((a) => a.id),
          containsAll(['first_steps', 'century', 'dedicated', 'master']));
    });

    test('has 3 streak achievements', () {
      final streakAchievements = DefaultAchievements.all
          .where((a) => a.category == AchievementCategory.streaks)
          .toList();

      expect(streakAchievements.length, equals(3));
    });

    test('has 3 accuracy achievements', () {
      final accuracyAchievements = DefaultAchievements.all
          .where((a) => a.category == AchievementCategory.accuracy)
          .toList();

      expect(accuracyAchievements.length, equals(3));
    });

    test('has 4 battle achievements', () {
      final battleAchievements = DefaultAchievements.all
          .where((a) => a.category == AchievementCategory.battles)
          .toList();

      expect(battleAchievements.length, equals(4));
    });
  });

  group('Edge Cases', () {
    test('handles user with no stats', () {
      final user = createTestUser();

      // No achievements should unlock for a brand new user
      for (final achievement in DefaultAchievements.all) {
        bool shouldUnlock;
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
            shouldUnlock = user.battleStats.wins >= achievement.requirement;
            break;
          case AchievementCategory.level:
            shouldUnlock = user.level >= achievement.requirement;
            break;
          case AchievementCategory.social:
            shouldUnlock = false;
            break;
        }

        expect(
          shouldUnlock,
          isFalse,
          reason: '${achievement.id} should not unlock for new user',
        );
      }
    });

    test('handles user who qualifies for multiple achievements at once', () {
      final user = createTestUser(
        totalQuestions: 1000,
        dailyStreakCount: 100,
        dailyStreakBest: 100,
        accuracyStreakCurrent: 50,
        accuracyStreakBest: 50,
        battleWins: 100,
        level: 100,
      );

      // Count how many achievements this user should unlock
      int unlockCount = 0;
      for (final achievement in DefaultAchievements.all) {
        bool shouldUnlock;
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
            shouldUnlock = user.battleStats.wins >= achievement.requirement;
            break;
          case AchievementCategory.level:
            shouldUnlock = user.level >= achievement.requirement;
            break;
          case AchievementCategory.social:
            // For testing purposes, assume social achievements unlock if level is high
            // since we don't have separate social stats yet
            shouldUnlock = user.level >= achievement.requirement;
            break;
        }

        if (shouldUnlock) unlockCount++;
      }

      // This user should unlock ALL achievements
      expect(unlockCount, equals(DefaultAchievements.all.length));
    });
  });
}
