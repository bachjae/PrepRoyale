import 'package:prep_royale/models/user_model.dart';
import 'package:prep_royale/models/battle_model.dart';

/// Creates a test UserModel with customizable fields.
///
/// All parameters have sensible defaults for basic testing scenarios.
/// Override specific fields as needed for your test case.
UserModel createTestUser({
  String id = 'test_user_1',
  String email = 'test@example.com',
  String username = 'testuser',
  String? profilePictureUrl,
  int level = 1,
  int xp = 0,
  int totalXp = 0,
  UserStats? stats,
  DailyStreak? dailyStreak,
  AccuracyStreak? accuracyStreak,
  BattleStats? battleStats,
  List<String>? unlockedAchievements,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return UserModel(
    id: id,
    email: email,
    username: username,
    profilePictureUrl: profilePictureUrl,
    level: level,
    xp: xp,
    totalXp: totalXp,
    stats: stats ?? const UserStats(),
    dailyStreak: dailyStreak ?? const DailyStreak(),
    accuracyStreak: accuracyStreak ?? const AccuracyStreak(),
    battleStats: battleStats ?? const BattleStats(),
    unlockedAchievements: unlockedAchievements ?? const [],
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

/// Creates a test BattlePlayer with customizable fields.
///
/// Use this for building BattleModel instances or testing player-specific logic.
BattlePlayer createTestPlayer({
  String odId = 'player_1',
  String username = 'testplayer',
  String? profilePictureUrl,
  int level = 1,
  int health = 100,
  int score = 0,
  int currentQuestionIndex = 0,
  List<int?>? answers,
}) {
  return BattlePlayer(
    odId: odId,
    username: username,
    profilePictureUrl: profilePictureUrl,
    level: level,
    health: health,
    score: score,
    currentQuestionIndex: currentQuestionIndex,
    answers: answers ?? const [],
  );
}

/// Creates a test BattleModel with customizable fields.
///
/// By default creates a battle in waiting status with only player1.
/// Set player2 to create a full battle ready to start.
BattleModel createTestBattle({
  String id = 'battle_1',
  BattlePlayer? player1,
  BattlePlayer? player2,
  BattleStatus status = BattleStatus.waiting,
  List<String>? questionIds,
  int currentQuestionIndex = 0,
  int questionTimeLimit = 30,
  DateTime? questionStartTime,
  String? winnerId,
  DateTime? createdAt,
  DateTime? completedAt,
}) {
  return BattleModel(
    id: id,
    player1: player1 ?? createTestPlayer(odId: 'player_1', username: 'player1'),
    player2: player2,
    status: status,
    questionIds: questionIds ?? const [],
    currentQuestionIndex: currentQuestionIndex,
    questionTimeLimit: questionTimeLimit,
    questionStartTime: questionStartTime,
    winnerId: winnerId,
    createdAt: createdAt ?? DateTime.now(),
    completedAt: completedAt,
  );
}

/// Creates a test MatchmakingEntry with customizable fields.
MatchmakingEntry createTestMatchmakingEntry({
  String odId = 'user_1',
  String odUsername = 'testuser',
  String? profilePictureUrl,
  int level = 1,
  String testType = 'SAT',
  DateTime? joinedAt,
}) {
  return MatchmakingEntry(
    odId: odId,
    odUsername: odUsername,
    profilePictureUrl: profilePictureUrl,
    level: level,
    testType: testType,
    joinedAt: joinedAt ?? DateTime.now(),
  );
}

/// Creates test UserStats with customizable fields.
UserStats createTestUserStats({
  int totalQuestions = 0,
  Map<String, double>? sectionAccuracy,
}) {
  return UserStats(
    totalQuestions: totalQuestions,
    sectionAccuracy: sectionAccuracy ?? const {},
  );
}

/// Creates test BattleStats with customizable fields.
BattleStats createTestBattleStats({
  int wins = 0,
  int losses = 0,
}) {
  return BattleStats(
    wins: wins,
    losses: losses,
  );
}

/// Creates test DailyStreak with customizable fields.
DailyStreak createTestDailyStreak({
  int count = 0,
  DateTime? lastDate,
  int best = 0,
}) {
  return DailyStreak(
    count: count,
    lastDate: lastDate,
    best: best,
  );
}

/// Creates test AccuracyStreak with customizable fields.
AccuracyStreak createTestAccuracyStreak({
  int current = 0,
  int best = 0,
}) {
  return AccuracyStreak(
    current: current,
    best: best,
  );
}
