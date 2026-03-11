import 'package:flutter_test/flutter_test.dart';
import 'package:prep_royale/models/user_model.dart';

import '../fixtures/user_fixtures.dart';

void main() {
  group('UserModel', () {
    group('xpForLevel', () {
      test('returns 100 for level 1', () {
        expect(UserModel.xpForLevel(1), equals(100));
      });

      test('returns 400 for level 2', () {
        expect(UserModel.xpForLevel(2), equals(400));
      });

      test('returns 900 for level 3', () {
        expect(UserModel.xpForLevel(3), equals(900));
      });

      test('returns 1600 for level 4', () {
        expect(UserModel.xpForLevel(4), equals(1600));
      });

      test('follows quadratic formula 100 * level * level', () {
        for (int level = 1; level <= 10; level++) {
          expect(
            UserModel.xpForLevel(level),
            equals(100 * level * level),
            reason: 'Level $level should require ${100 * level * level} XP',
          );
        }
      });
    });

    group('xpToNextLevel', () {
      test('calculates correctly for level 1 user with 0 totalXp', () {
        final user = createTestUser(level: 1, totalXp: 0);
        // Next level (2) requires 400 XP, user has 0
        expect(user.xpToNextLevel, equals(400));
      });

      test('calculates correctly for level 1 user with some totalXp', () {
        final user = createTestUser(level: 1, totalXp: 150);
        // Next level (2) requires 400 XP, user has 150
        expect(user.xpToNextLevel, equals(250));
      });

      test('calculates correctly for level 2 user', () {
        final user = createTestUser(level: 2, totalXp: 400);
        // Next level (3) requires 900 XP, user has 400
        expect(user.xpToNextLevel, equals(500));
      });

      test('calculates correctly for level 3 user with partial progress', () {
        final user = createTestUser(level: 3, totalXp: 1000);
        // Next level (4) requires 1600 XP, user has 1000
        expect(user.xpToNextLevel, equals(600));
      });
    });

    group('levelProgress', () {
      test('returns correct progress for user mid-way through level 2', () {
        // Level 2 starts at 400 XP, level 3 at 900 XP
        // User with 650 XP is (650-400)/(900-400) = 250/500 = 0.5 through level 2
        final user = createTestUser(level: 2, totalXp: 650);
        expect(user.levelProgress, closeTo(0.5, 0.001));
      });

      test('returns 0.0 when user just reached their level', () {
        // User just reached level 2 (400 XP)
        final user = createTestUser(level: 2, totalXp: 400);
        expect(user.levelProgress, closeTo(0.0, 0.001));
      });

      test('returns close to 1.0 when user is about to level up', () {
        // Level 2 is 400-899 XP, level 3 starts at 900
        // User with 899 XP: (899-400)/(900-400) = 499/500 = 0.998
        final user = createTestUser(level: 2, totalXp: 899);
        expect(user.levelProgress, closeTo(0.998, 0.001));
      });

      // BUG DOCUMENTATION: levelProgress calculation for level 1 with 0 XP
      //
      // When a user is level 1 with 0 totalXp, the mathematical calculation would be:
      //   currentLevelXp = xpForLevel(1) = 100
      //   nextLevelXp = xpForLevel(2) = 400
      //   xpIntoLevel = 0 - 100 = -100
      //   xpNeeded = 400 - 100 = 300
      //   levelProgress = -100 / 300 = -0.333...
      //
      // This represents a potential semantic bug because:
      // 1. Progress should logically be between 0.0 and 1.0
      // 2. The formula assumes totalXp >= xpForLevel(level), but new users
      //    start at level 1 with 0 totalXp
      //
      // In Dart integer division, -100 / 300 as double is -0.333...
      // but depending on the implementation, this might be handled differently.
      //
      // Suggested fix: The xpForLevel(1) should return 0 (not 100), OR
      // levelProgress should clamp the result to [0.0, 1.0]
      test('documents behavior for level 1 with 0 totalXp', () {
        final user = createTestUser(level: 1, totalXp: 0);
        // The calculation: (0 - 100) / (400 - 100) = -100 / 300
        // This could yield a negative value, which is semantically incorrect
        // for a "progress" metric that should be 0.0 to 1.0
        final progress = user.levelProgress;

        // Document the actual behavior - the value is negative OR zero depending
        // on how Dart handles the integer/double division
        expect(
          progress,
          lessThanOrEqualTo(0.0),
          reason: 'Level 1 user with 0 totalXp should have 0 or negative progress',
        );
      });

      test('returns value between 0 and 1 for normal level 1 user', () {
        // User at level 1 with 200 totalXp
        // (200-100)/(400-100) = 100/300 = 0.333
        final user = createTestUser(level: 1, totalXp: 200);
        expect(user.levelProgress, greaterThanOrEqualTo(0.0));
        expect(user.levelProgress, lessThanOrEqualTo(1.0));
        expect(user.levelProgress, closeTo(0.333, 0.01));
      });
    });

    group('Equatable behavior', () {
      test('two users with same properties are equal', () {
        final now = DateTime(2024, 1, 1);
        final user1 = createTestUser(
          id: 'user_1',
          email: 'test@test.com',
          username: 'testuser',
          level: 5,
          xp: 100,
          totalXp: 500,
          createdAt: now,
          updatedAt: now,
        );
        final user2 = createTestUser(
          id: 'user_1',
          email: 'test@test.com',
          username: 'testuser',
          level: 5,
          xp: 100,
          totalXp: 500,
          createdAt: now,
          updatedAt: now,
        );
        expect(user1, equals(user2));
      });

      test('two users with different IDs are not equal', () {
        final now = DateTime(2024, 1, 1);
        final user1 = createTestUser(id: 'user_1', createdAt: now, updatedAt: now);
        final user2 = createTestUser(id: 'user_2', createdAt: now, updatedAt: now);
        expect(user1, isNot(equals(user2)));
      });

      test('two users with different levels are not equal', () {
        final now = DateTime(2024, 1, 1);
        final user1 = createTestUser(level: 1, createdAt: now, updatedAt: now);
        final user2 = createTestUser(level: 2, createdAt: now, updatedAt: now);
        expect(user1, isNot(equals(user2)));
      });

      test('hashCode is same for equal users', () {
        final now = DateTime(2024, 1, 1);
        final user1 = createTestUser(id: 'user_1', createdAt: now, updatedAt: now);
        final user2 = createTestUser(id: 'user_1', createdAt: now, updatedAt: now);
        expect(user1.hashCode, equals(user2.hashCode));
      });
    });

    group('copyWith', () {
      test('creates a copy with updated level', () {
        final user = createTestUser(level: 1);
        final updated = user.copyWith(level: 5);
        expect(updated.level, equals(5));
        expect(updated.id, equals(user.id));
        expect(updated.email, equals(user.email));
      });

      test('creates a copy with updated stats', () {
        final user = createTestUser();
        final newStats = createTestUserStats(
          totalQuestions: 100,
          sectionAccuracy: {'sat_math': 0.85},
        );
        final updated = user.copyWith(stats: newStats);
        expect(updated.stats.totalQuestions, equals(100));
        expect(updated.stats.sectionAccuracy['sat_math'], equals(0.85));
      });
    });
  });

  group('BattleStats', () {
    group('winRate', () {
      test('returns 0.0 when no battles played (division by zero)', () {
        final stats = createTestBattleStats(wins: 0, losses: 0);
        expect(stats.winRate, equals(0.0));
      });

      test('returns 1.0 when all wins', () {
        final stats = createTestBattleStats(wins: 10, losses: 0);
        expect(stats.winRate, equals(1.0));
      });

      test('returns 0.0 when all losses', () {
        final stats = createTestBattleStats(wins: 0, losses: 10);
        expect(stats.winRate, equals(0.0));
      });

      test('returns correct ratio for mixed results', () {
        final stats = createTestBattleStats(wins: 7, losses: 3);
        expect(stats.winRate, equals(0.7));
      });

      test('returns 0.5 for equal wins and losses', () {
        final stats = createTestBattleStats(wins: 5, losses: 5);
        expect(stats.winRate, equals(0.5));
      });
    });

    group('totalBattles', () {
      test('sums wins and losses correctly', () {
        final stats = createTestBattleStats(wins: 7, losses: 3);
        expect(stats.totalBattles, equals(10));
      });

      test('returns 0 when no battles', () {
        final stats = createTestBattleStats(wins: 0, losses: 0);
        expect(stats.totalBattles, equals(0));
      });

      test('handles only wins', () {
        final stats = createTestBattleStats(wins: 15, losses: 0);
        expect(stats.totalBattles, equals(15));
      });

      test('handles only losses', () {
        final stats = createTestBattleStats(wins: 0, losses: 20);
        expect(stats.totalBattles, equals(20));
      });
    });

    group('Equatable behavior', () {
      test('two BattleStats with same values are equal', () {
        final stats1 = createTestBattleStats(wins: 5, losses: 3);
        final stats2 = createTestBattleStats(wins: 5, losses: 3);
        expect(stats1, equals(stats2));
      });

      test('two BattleStats with different values are not equal', () {
        final stats1 = createTestBattleStats(wins: 5, losses: 3);
        final stats2 = createTestBattleStats(wins: 5, losses: 4);
        expect(stats1, isNot(equals(stats2)));
      });
    });
  });

  group('UserStats', () {
    group('overallAccuracy', () {
      test('returns 0.0 when no sections', () {
        final stats = createTestUserStats(sectionAccuracy: {});
        expect(stats.overallAccuracy, equals(0.0));
      });

      test('returns single section accuracy when only one section', () {
        final stats = createTestUserStats(
          sectionAccuracy: {'sat_math': 0.85},
        );
        expect(stats.overallAccuracy, equals(0.85));
      });

      test('averages multiple section accuracies correctly', () {
        final stats = createTestUserStats(
          sectionAccuracy: {
            'sat_math': 0.80,
            'sat_reading': 0.90,
          },
        );
        expect(stats.overallAccuracy, closeTo(0.85, 0.0001));
      });

      test('averages three sections correctly', () {
        final stats = createTestUserStats(
          sectionAccuracy: {
            'sat_math': 0.70,
            'sat_reading': 0.80,
            'act_science': 0.90,
          },
        );
        expect(stats.overallAccuracy, closeTo(0.80, 0.0001));
      });

      test('handles perfect accuracy across sections', () {
        final stats = createTestUserStats(
          sectionAccuracy: {
            'sat_math': 1.0,
            'sat_reading': 1.0,
          },
        );
        expect(stats.overallAccuracy, equals(1.0));
      });

      test('handles zero accuracy across sections', () {
        final stats = createTestUserStats(
          sectionAccuracy: {
            'sat_math': 0.0,
            'sat_reading': 0.0,
          },
        );
        expect(stats.overallAccuracy, equals(0.0));
      });
    });

    group('Equatable behavior', () {
      test('two UserStats with same values are equal', () {
        final stats1 = createTestUserStats(
          totalQuestions: 100,
          sectionAccuracy: {'sat_math': 0.8},
        );
        final stats2 = createTestUserStats(
          totalQuestions: 100,
          sectionAccuracy: {'sat_math': 0.8},
        );
        expect(stats1, equals(stats2));
      });
    });
  });

  group('DailyStreak', () {
    group('Equatable behavior', () {
      test('two DailyStreaks with same values are equal', () {
        final date = DateTime(2024, 1, 15);
        final streak1 = createTestDailyStreak(count: 5, lastDate: date, best: 10);
        final streak2 = createTestDailyStreak(count: 5, lastDate: date, best: 10);
        expect(streak1, equals(streak2));
      });

      test('two DailyStreaks with different counts are not equal', () {
        final date = DateTime(2024, 1, 15);
        final streak1 = createTestDailyStreak(count: 5, lastDate: date);
        final streak2 = createTestDailyStreak(count: 6, lastDate: date);
        expect(streak1, isNot(equals(streak2)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated count', () {
        final streak = createTestDailyStreak(count: 5);
        final updated = streak.copyWith(count: 10);
        expect(updated.count, equals(10));
      });
    });
  });

  group('AccuracyStreak', () {
    group('Equatable behavior', () {
      test('two AccuracyStreaks with same values are equal', () {
        final streak1 = createTestAccuracyStreak(current: 5, best: 10);
        final streak2 = createTestAccuracyStreak(current: 5, best: 10);
        expect(streak1, equals(streak2));
      });

      test('two AccuracyStreaks with different values are not equal', () {
        final streak1 = createTestAccuracyStreak(current: 5, best: 10);
        final streak2 = createTestAccuracyStreak(current: 5, best: 11);
        expect(streak1, isNot(equals(streak2)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated current', () {
        final streak = createTestAccuracyStreak(current: 5);
        final updated = streak.copyWith(current: 10);
        expect(updated.current, equals(10));
        expect(updated.best, equals(streak.best));
      });
    });
  });
}
