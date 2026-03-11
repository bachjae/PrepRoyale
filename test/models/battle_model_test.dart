import 'package:flutter_test/flutter_test.dart';
import 'package:prep_royale/models/battle_model.dart';

import '../fixtures/user_fixtures.dart';

void main() {
  group('BattleModel', () {
    group('calculateDamage', () {
      group('correct answers', () {
        test('returns 15 for correct answer within 5 seconds', () {
          expect(BattleModel.calculateDamage(true, 5), equals(15));
        });

        test('returns 15 for correct answer at exactly 15 seconds (boundary)', () {
          expect(BattleModel.calculateDamage(true, 15), equals(15));
        });

        test('returns 12 for correct answer at 16 seconds', () {
          expect(BattleModel.calculateDamage(true, 16), equals(12));
        });

        test('returns 12 for correct answer at exactly 30 seconds (boundary)', () {
          expect(BattleModel.calculateDamage(true, 30), equals(12));
        });

        test('returns 10 for correct answer at 31 seconds', () {
          expect(BattleModel.calculateDamage(true, 31), equals(10));
        });

        test('returns 15 for correct answer at 0 seconds', () {
          expect(BattleModel.calculateDamage(true, 0), equals(15));
        });

        test('returns 15 for correct answer at 1 second', () {
          expect(BattleModel.calculateDamage(true, 1), equals(15));
        });

        test('returns 12 for correct answer at 20 seconds', () {
          expect(BattleModel.calculateDamage(true, 20), equals(12));
        });

        test('returns 12 for correct answer at 25 seconds', () {
          expect(BattleModel.calculateDamage(true, 25), equals(12));
        });

        test('returns 10 for correct answer at 45 seconds', () {
          expect(BattleModel.calculateDamage(true, 45), equals(10));
        });

        test('returns 10 for correct answer at 60 seconds', () {
          expect(BattleModel.calculateDamage(true, 60), equals(10));
        });
      });

      group('incorrect answers', () {
        test('returns 0 for incorrect answer regardless of time', () {
          expect(BattleModel.calculateDamage(false, 5), equals(0));
        });

        test('returns 0 for incorrect answer at 0 seconds', () {
          expect(BattleModel.calculateDamage(false, 0), equals(0));
        });

        test('returns 0 for incorrect answer at 15 seconds', () {
          expect(BattleModel.calculateDamage(false, 15), equals(0));
        });

        test('returns 0 for incorrect answer at 30 seconds', () {
          expect(BattleModel.calculateDamage(false, 30), equals(0));
        });

        test('returns 0 for incorrect answer at 60 seconds', () {
          expect(BattleModel.calculateDamage(false, 60), equals(0));
        });
      });
    });

    group('calculateSelfDamage', () {
      test('returns 15 for timeout (incorrect with timedOut=true)', () {
        expect(BattleModel.calculateSelfDamage(false, true), equals(15));
      });

      test('returns 8 for wrong answer (incorrect with timedOut=false)', () {
        expect(BattleModel.calculateSelfDamage(false, false), equals(8));
      });

      test('returns 0 for correct answer (correct with timedOut=false)', () {
        expect(BattleModel.calculateSelfDamage(true, false), equals(0));
      });

      // Edge case: correct but also timedOut=true (shouldn't happen in practice)
      // The implementation checks timedOut first, so this returns 15
      test('returns 15 for correct answer with timedOut=true (edge case)', () {
        expect(BattleModel.calculateSelfDamage(true, true), equals(15));
      });
    });

    group('BattleStatus helpers', () {
      group('isWaitingForOpponent', () {
        test('returns true when status is waiting and player2 is null', () {
          final battle = createTestBattle(
            status: BattleStatus.waiting,
            player2: null,
          );
          expect(battle.isWaitingForOpponent, isTrue);
        });

        test('returns false when status is waiting but player2 exists', () {
          final battle = createTestBattle(
            status: BattleStatus.waiting,
            player2: createTestPlayer(odId: 'player_2', username: 'player2'),
          );
          expect(battle.isWaitingForOpponent, isFalse);
        });

        test('returns false when status is inProgress', () {
          final battle = createTestBattle(
            status: BattleStatus.inProgress,
            player2: null,
          );
          expect(battle.isWaitingForOpponent, isFalse);
        });

        test('returns false when status is completed', () {
          final battle = createTestBattle(
            status: BattleStatus.completed,
            player2: null,
          );
          expect(battle.isWaitingForOpponent, isFalse);
        });
      });

      group('isFull', () {
        test('returns true when player2 is present', () {
          final battle = createTestBattle(
            player2: createTestPlayer(odId: 'player_2', username: 'player2'),
          );
          expect(battle.isFull, isTrue);
        });

        test('returns false when player2 is null', () {
          final battle = createTestBattle(player2: null);
          expect(battle.isFull, isFalse);
        });
      });

      group('isInProgress', () {
        test('returns true when status is inProgress', () {
          final battle = createTestBattle(status: BattleStatus.inProgress);
          expect(battle.isInProgress, isTrue);
        });

        test('returns false when status is waiting', () {
          final battle = createTestBattle(status: BattleStatus.waiting);
          expect(battle.isInProgress, isFalse);
        });

        test('returns false when status is completed', () {
          final battle = createTestBattle(status: BattleStatus.completed);
          expect(battle.isInProgress, isFalse);
        });
      });

      group('isCompleted', () {
        test('returns true when status is completed', () {
          final battle = createTestBattle(status: BattleStatus.completed);
          expect(battle.isCompleted, isTrue);
        });

        test('returns false when status is waiting', () {
          final battle = createTestBattle(status: BattleStatus.waiting);
          expect(battle.isCompleted, isFalse);
        });

        test('returns false when status is inProgress', () {
          final battle = createTestBattle(status: BattleStatus.inProgress);
          expect(battle.isCompleted, isFalse);
        });
      });

      group('totalQuestions', () {
        test('returns 0 when questionIds is empty', () {
          final battle = createTestBattle(questionIds: []);
          expect(battle.totalQuestions, equals(0));
        });

        test('returns correct count for non-empty questionIds', () {
          final battle = createTestBattle(
            questionIds: ['q1', 'q2', 'q3', 'q4', 'q5'],
          );
          expect(battle.totalQuestions, equals(5));
        });

        test('returns 20 for full battle', () {
          final questionIds = List.generate(20, (i) => 'q_$i');
          final battle = createTestBattle(questionIds: questionIds);
          expect(battle.totalQuestions, equals(20));
        });
      });
    });

    group('Equatable behavior', () {
      test('two battles with same properties are equal', () {
        final createdAt = DateTime(2024, 1, 1);
        final player1 = createTestPlayer(odId: 'p1', username: 'player1');

        final battle1 = createTestBattle(
          id: 'battle_1',
          player1: player1,
          status: BattleStatus.waiting,
          createdAt: createdAt,
        );
        final battle2 = createTestBattle(
          id: 'battle_1',
          player1: player1,
          status: BattleStatus.waiting,
          createdAt: createdAt,
        );

        expect(battle1, equals(battle2));
      });

      test('two battles with different IDs are not equal', () {
        final createdAt = DateTime(2024, 1, 1);
        final battle1 = createTestBattle(id: 'battle_1', createdAt: createdAt);
        final battle2 = createTestBattle(id: 'battle_2', createdAt: createdAt);
        expect(battle1, isNot(equals(battle2)));
      });

      test('two battles with different statuses are not equal', () {
        final createdAt = DateTime(2024, 1, 1);
        final battle1 = createTestBattle(
          status: BattleStatus.waiting,
          createdAt: createdAt,
        );
        final battle2 = createTestBattle(
          status: BattleStatus.inProgress,
          createdAt: createdAt,
        );
        expect(battle1, isNot(equals(battle2)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated status', () {
        final battle = createTestBattle(status: BattleStatus.waiting);
        final updated = battle.copyWith(status: BattleStatus.inProgress);
        expect(updated.status, equals(BattleStatus.inProgress));
        expect(updated.id, equals(battle.id));
      });

      test('creates copy with updated player2', () {
        final battle = createTestBattle(player2: null);
        final player2 = createTestPlayer(odId: 'player_2', username: 'player2');
        final updated = battle.copyWith(player2: player2);
        expect(updated.player2, equals(player2));
        expect(updated.player1, equals(battle.player1));
      });

      test('creates copy with updated winnerId', () {
        final battle = createTestBattle(winnerId: null);
        final updated = battle.copyWith(winnerId: 'player_1');
        expect(updated.winnerId, equals('player_1'));
      });

      test('creates copy with updated questionIds', () {
        final battle = createTestBattle(questionIds: []);
        final updated = battle.copyWith(questionIds: ['q1', 'q2']);
        expect(updated.questionIds, equals(['q1', 'q2']));
      });
    });
  });

  group('BattlePlayer', () {
    group('Equatable behavior', () {
      test('two players with same properties are equal', () {
        final player1 = createTestPlayer(
          odId: 'player_1',
          username: 'testplayer',
          level: 5,
          health: 100,
        );
        final player2 = createTestPlayer(
          odId: 'player_1',
          username: 'testplayer',
          level: 5,
          health: 100,
        );
        expect(player1, equals(player2));
      });

      test('two players with different IDs are not equal', () {
        final player1 = createTestPlayer(odId: 'player_1');
        final player2 = createTestPlayer(odId: 'player_2');
        expect(player1, isNot(equals(player2)));
      });

      test('two players with different health are not equal', () {
        final player1 = createTestPlayer(health: 100);
        final player2 = createTestPlayer(health: 85);
        expect(player1, isNot(equals(player2)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated health', () {
        final player = createTestPlayer(health: 100);
        final updated = player.copyWith(health: 85);
        expect(updated.health, equals(85));
        expect(updated.odId, equals(player.odId));
      });

      test('creates copy with updated score', () {
        final player = createTestPlayer(score: 0);
        final updated = player.copyWith(score: 150);
        expect(updated.score, equals(150));
      });

      test('creates copy with updated answers', () {
        final player = createTestPlayer(answers: []);
        final updated = player.copyWith(answers: [0, 1, null, 2]);
        expect(updated.answers, equals([0, 1, null, 2]));
      });
    });

    group('odIdAlias', () {
      test('returns same value as odId', () {
        final player = createTestPlayer(odId: 'test_player_id');
        expect(player.odIdAlias, equals(player.odId));
        expect(player.odIdAlias, equals('test_player_id'));
      });
    });
  });

  group('MatchmakingEntry', () {
    group('Equatable behavior', () {
      test('two entries with same properties are equal', () {
        final joinedAt = DateTime(2024, 1, 1);
        final entry1 = createTestMatchmakingEntry(
          odId: 'user_1',
          odUsername: 'testuser',
          level: 5,
          testType: 'SAT',
          joinedAt: joinedAt,
        );
        final entry2 = createTestMatchmakingEntry(
          odId: 'user_1',
          odUsername: 'testuser',
          level: 5,
          testType: 'SAT',
          joinedAt: joinedAt,
        );
        expect(entry1, equals(entry2));
      });

      test('two entries with different IDs are not equal', () {
        final joinedAt = DateTime(2024, 1, 1);
        final entry1 = createTestMatchmakingEntry(odId: 'user_1', joinedAt: joinedAt);
        final entry2 = createTestMatchmakingEntry(odId: 'user_2', joinedAt: joinedAt);
        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('alias getters', () {
      test('odIdAlias returns same value as odId', () {
        final entry = createTestMatchmakingEntry(odId: 'test_id');
        expect(entry.odIdAlias, equals(entry.odId));
      });

      test('username returns same value as odUsername', () {
        final entry = createTestMatchmakingEntry(odUsername: 'testname');
        expect(entry.username, equals(entry.odUsername));
      });
    });

    group('copyWith', () {
      test('creates copy with updated level', () {
        final entry = createTestMatchmakingEntry(level: 1);
        final updated = entry.copyWith(level: 5);
        expect(updated.level, equals(5));
        expect(updated.odId, equals(entry.odId));
      });

      test('creates copy with updated testType', () {
        final entry = createTestMatchmakingEntry(testType: 'SAT');
        final updated = entry.copyWith(testType: 'ACT');
        expect(updated.testType, equals('ACT'));
      });
    });
  });

  group('BattleStatus enum', () {
    test('has waiting value', () {
      expect(BattleStatus.values, contains(BattleStatus.waiting));
    });

    test('has inProgress value', () {
      expect(BattleStatus.values, contains(BattleStatus.inProgress));
    });

    test('has completed value', () {
      expect(BattleStatus.values, contains(BattleStatus.completed));
    });

    test('has exactly 3 values', () {
      expect(BattleStatus.values.length, equals(3));
    });
  });
}
