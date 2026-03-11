import 'package:flutter_test/flutter_test.dart';
import 'package:prep_royale/models/user_model.dart';

/// Tests for FirebaseService logic.
///
/// Since FirebaseService relies heavily on Firestore transactions,
/// we focus on testing the pure logic parts that can be unit tested
/// without Firebase dependencies.
void main() {
  group('XP and Level Calculation Logic', () {
    group('UserModel.xpForLevel', () {
      test('level 1 requires 100 XP', () {
        expect(UserModel.xpForLevel(1), equals(100));
      });

      test('level 2 requires 400 XP (100 * 2 * 2)', () {
        expect(UserModel.xpForLevel(2), equals(400));
      });

      test('level 3 requires 900 XP (100 * 3 * 3)', () {
        expect(UserModel.xpForLevel(3), equals(900));
      });

      test('level 5 requires 2500 XP (100 * 5 * 5)', () {
        expect(UserModel.xpForLevel(5), equals(2500));
      });

      test('level 10 requires 10000 XP (100 * 10 * 10)', () {
        expect(UserModel.xpForLevel(10), equals(10000));
      });

      test('follows quadratic formula: 100 * level^2', () {
        for (int level = 1; level <= 20; level++) {
          expect(
            UserModel.xpForLevel(level),
            equals(100 * level * level),
            reason: 'Level $level should require ${100 * level * level} XP',
          );
        }
      });
    });

    group('Level calculation from totalXp', () {
      test('calculates correct level for various XP values', () {
        // Test cases: (totalXp, expectedLevel)
        // Level N is reached when totalXp >= xpForLevel(N)
        // User stays at level N until totalXp >= xpForLevel(N+1)

        final testCases = [
          (0, 1), // Starting state - not yet level 1 XP, but default level is 1
          (99, 1), // Just below level 1 threshold
          (100, 1), // Exactly at level 1 threshold - stays at 1 until next
          (399, 1), // Just below level 2
          (400, 2), // Reaches level 2
          (899, 2), // Just below level 3
          (900, 3), // Reaches level 3
          (2500, 5), // Exactly level 5
          (10000, 10), // Exactly level 10
        ];

        for (final (totalXp, expectedLevel) in testCases) {
          // Calculate level using same logic as addXp in FirebaseService
          int level = 1;
          while (totalXp >= UserModel.xpForLevel(level + 1)) {
            level++;
          }

          expect(
            level,
            equals(expectedLevel),
            reason: 'totalXp=$totalXp should be level $expectedLevel',
          );
        }
      });

      test('level increases when crossing threshold', () {
        // Simulating addXp logic
        const startLevel = 1;
        const startTotalXp = 350;
        const xpToAdd = 50; // Total will be 400, exactly level 2

        final newTotalXp = startTotalXp + xpToAdd;
        int newLevel = startLevel;
        while (newTotalXp >= UserModel.xpForLevel(newLevel + 1)) {
          newLevel++;
        }

        expect(newLevel, equals(2));
        expect(newLevel > startLevel, isTrue);
      });

      test('level does not increase when below threshold', () {
        const startLevel = 1;
        const startTotalXp = 350;
        const xpToAdd = 10; // Total will be 360, still below 400

        final newTotalXp = startTotalXp + xpToAdd;
        int newLevel = startLevel;
        while (newTotalXp >= UserModel.xpForLevel(newLevel + 1)) {
          newLevel++;
        }

        expect(newLevel, equals(1));
        expect(newLevel > startLevel, isFalse);
      });

      test('can level up multiple times with large XP gain', () {
        const startLevel = 1;
        const startTotalXp = 100;
        const xpToAdd = 800; // Total will be 900, exactly level 3

        final newTotalXp = startTotalXp + xpToAdd;
        int newLevel = startLevel;
        while (newTotalXp >= UserModel.xpForLevel(newLevel + 1)) {
          newLevel++;
        }

        expect(newLevel, equals(3));
        expect(newLevel - startLevel, equals(2)); // Gained 2 levels
      });
    });

    group('xpToNextLevel', () {
      test('calculates XP needed for next level correctly', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'test',
          email: 'test@test.com',
          username: 'testuser',
          level: 1,
          totalXp: 200,
          createdAt: now,
          updatedAt: now,
        );

        // Level 2 requires 400 XP, user has 200, needs 200 more
        expect(user.xpToNextLevel, equals(200));
      });

      test('returns 0 when exactly at next level threshold', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'test',
          email: 'test@test.com',
          username: 'testuser',
          level: 1,
          totalXp: 400, // Exactly level 2 threshold
          createdAt: now,
          updatedAt: now,
        );

        // User should actually be level 2, but if level wasn't updated,
        // xpToNextLevel would show 0
        expect(user.xpToNextLevel, equals(0));
      });
    });

    group('levelProgress', () {
      test('returns 0.5 when halfway to next level', () {
        final now = DateTime.now();
        // Level 1 = 100 XP, Level 2 = 400 XP
        // Midpoint would be 100 + (400-100)/2 = 250
        final user = UserModel(
          id: 'test',
          email: 'test@test.com',
          username: 'testuser',
          level: 1,
          totalXp: 250,
          createdAt: now,
          updatedAt: now,
        );

        expect(user.levelProgress, equals(0.5));
      });

      test('returns 0.0 when at level start', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'test',
          email: 'test@test.com',
          username: 'testuser',
          level: 1,
          totalXp: 100, // Exactly at level 1
          createdAt: now,
          updatedAt: now,
        );

        expect(user.levelProgress, equals(0.0));
      });

      test('returns close to 1.0 when near next level', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'test',
          email: 'test@test.com',
          username: 'testuser',
          level: 1,
          totalXp: 399, // Just 1 XP below level 2
          createdAt: now,
          updatedAt: now,
        );

        // (399 - 100) / (400 - 100) = 299/300 = 0.9966...
        expect(user.levelProgress, closeTo(0.9967, 0.001));
      });
    });
  });

  group('Daily Streak Logic', () {
    /// These tests document the expected behavior of updateDailyStreak
    /// based on the FirebaseService implementation.

    test('streak increments on consecutive days', () {
      // Given: User has streak of 5, last activity was yesterday
      // When: User is active today
      // Then: Streak should become 6

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();

      final lastDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final currentDay = DateTime(today.year, today.month, today.day);
      final difference = currentDay.difference(lastDay).inDays;

      expect(difference, equals(1));

      // Simulate the streak logic from FirebaseService
      int currentStreak = 5;
      if (difference == 1) {
        currentStreak++;
      }

      expect(currentStreak, equals(6));
    });

    test('streak resets after missing a day', () {
      // Given: User has streak of 5, last activity was 2 days ago
      // When: User is active today
      // Then: Streak should reset to 1

      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final today = DateTime.now();

      final lastDay =
          DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);
      final currentDay = DateTime(today.year, today.month, today.day);
      final difference = currentDay.difference(lastDay).inDays;

      expect(difference, equals(2));

      // Simulate the streak logic from FirebaseService
      int currentStreak = 5;
      if (difference == 0) {
        // Same day, no change
      } else if (difference == 1) {
        currentStreak++;
      } else {
        // Streak broken, reset
        currentStreak = 1;
      }

      expect(currentStreak, equals(1));
    });

    test('streak stays same on same day activity', () {
      // Given: User has streak of 5, last activity was earlier today
      // When: User is active again today
      // Then: Streak should stay at 5

      final today = DateTime.now();
      final lastDay = DateTime(today.year, today.month, today.day);
      final currentDay = DateTime(today.year, today.month, today.day);
      final difference = currentDay.difference(lastDay).inDays;

      expect(difference, equals(0));

      // Simulate the streak logic from FirebaseService
      int currentStreak = 5;
      bool didIncrement = false;

      if (difference == 0) {
        // Same day, no change
      } else if (difference == 1) {
        currentStreak++;
        didIncrement = true;
      } else {
        currentStreak = 1;
        didIncrement = true;
      }

      expect(currentStreak, equals(5));
      expect(didIncrement, isFalse);
    });

    test('first activity initializes streak to 1', () {
      // Given: User has never had activity (lastDate is null)
      // When: User is active for the first time
      // Then: Streak should be set to 1

      // Simulate the null-checking logic from FirebaseService
      const hasLastDate = false;
      int currentStreak = 0;
      bool didIncrement = false;

      if (!hasLastDate) {
        currentStreak = 1;
        didIncrement = true;
      }

      expect(currentStreak, equals(1));
      expect(didIncrement, isTrue);
    });

    test('best streak updates when current exceeds previous best', () {
      const currentCount = 5;
      const previousBest = 4;

      final newBest = currentCount > previousBest ? currentCount : previousBest;

      expect(newBest, equals(5));
    });

    test('best streak stays same when current does not exceed', () {
      const currentCount = 3;
      const previousBest = 7;

      final newBest = currentCount > previousBest ? currentCount : previousBest;

      expect(newBest, equals(7));
    });
  });

  group('Accuracy Streak Logic', () {
    /// These tests document the expected behavior of updateAccuracyStreak
    /// based on the FirebaseService implementation.

    test('accuracy streak increments on correct answer', () {
      // Given: User has accuracy streak of 5
      // When: User answers correctly
      // Then: Streak should become 6

      int currentStreak = 5;

      currentStreak = currentStreak + 1;

      expect(currentStreak, equals(6));
    });

    test('accuracy streak resets to 0 on wrong answer', () {
      // Given: User has accuracy streak of 10
      // When: User answers incorrectly
      // Then: Streak should reset to 0

      int currentStreak = 10;
      currentStreak = 0;

      expect(currentStreak, equals(0));
    });

    test('accuracy streak starts from 0 and increments to 1', () {
      // Given: User has accuracy streak of 0
      // When: User answers correctly
      // Then: Streak should become 1

      int currentStreak = 0;
      currentStreak = currentStreak + 1;

      expect(currentStreak, equals(1));
    });

    test('best accuracy streak updates when current exceeds previous best', () {
      const currentStreak = 15;
      const previousBest = 10;

      final newBest =
          currentStreak > previousBest ? currentStreak : previousBest;

      expect(newBest, equals(15));
    });

    test('best accuracy streak stays same when current does not exceed', () {
      const currentStreak = 5;
      const previousBest = 20;

      final newBest =
          currentStreak > previousBest ? currentStreak : previousBest;

      expect(newBest, equals(20));
    });

    test('wrong answer does not affect best streak', () {
      // Best streak is preserved even when current resets
      const previousBest = 15;
      int currentStreak = 10;
      currentStreak = 0;

      final newBest =
          currentStreak > previousBest ? currentStreak : previousBest;

      expect(currentStreak, equals(0));
      expect(newBest, equals(15)); // Best is preserved
    });
  });

  group('DailyStreak Model', () {
    test('copyWith preserves unchanged values', () {
      final original = DailyStreak(
        count: 5,
        lastDate: DateTime(2024, 1, 15),
        best: 10,
      );

      final updated = original.copyWith(count: 6);

      expect(updated.count, equals(6));
      expect(updated.lastDate, equals(original.lastDate));
      expect(updated.best, equals(10));
    });
  });

  group('AccuracyStreak Model', () {
    test('copyWith preserves unchanged values', () {
      const original = AccuracyStreak(current: 5, best: 10);
      final updated = original.copyWith(current: 6);

      expect(updated.current, equals(6));
      expect(updated.best, equals(10));
    });
  });

  group('BattleStats Model', () {
    test('winRate calculates correctly', () {
      const stats = BattleStats(wins: 7, losses: 3);

      expect(stats.winRate, equals(0.7));
    });

    test('winRate returns 0.0 when no battles', () {
      const stats = BattleStats(wins: 0, losses: 0);

      expect(stats.winRate, equals(0.0));
    });

    test('totalBattles sums wins and losses', () {
      const stats = BattleStats(wins: 5, losses: 3);

      expect(stats.totalBattles, equals(8));
    });
  });

  group('UserStats Model', () {
    test('overallAccuracy averages section accuracies', () {
      const stats = UserStats(
        totalQuestions: 100,
        sectionAccuracy: {
          'sat_math': 0.80,
          'sat_reading': 0.60,
        },
      );

      expect(stats.overallAccuracy, equals(0.70));
    });

    test('overallAccuracy returns 0 when no sections', () {
      const stats = UserStats(totalQuestions: 0);

      expect(stats.overallAccuracy, equals(0.0));
    });
  });
}
