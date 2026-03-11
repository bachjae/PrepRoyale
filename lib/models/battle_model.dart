import 'package:equatable/equatable.dart';

enum BattleStatus { waiting, inProgress, completed, declined }

class BattlePlayer extends Equatable {
  final String odId; // Using odId for backwards compatibility, use userId getter
  final String username;
  final String? profilePictureUrl;
  final int level;
  final int health;
  final int score;
  final int currentQuestionIndex;
  final List<int?> answers; // null if not answered yet

  const BattlePlayer({
    required this.odId,
    required this.username,
    this.profilePictureUrl,
    required this.level,
    this.health = 100,
    this.score = 0,
    this.currentQuestionIndex = 0,
    this.answers = const [],
  });

  // Alias for odId
  String get odIdAlias => odId;

  factory BattlePlayer.fromMap(Map<String, dynamic> map) {
    return BattlePlayer(
      odId: map['id'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      level: map['level'] ?? 1,
      health: map['health'] ?? 100,
      score: map['score'] ?? 0,
      currentQuestionIndex: map['currentQuestionIndex'] ?? 0,
      answers: List<int?>.from(map['answers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': odId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'level': level,
      'health': health,
      'score': score,
      'currentQuestionIndex': currentQuestionIndex,
      'answers': answers,
    };
  }

  BattlePlayer copyWith({
    String? odId,
    String? username,
    String? profilePictureUrl,
    int? level,
    int? health,
    int? score,
    int? currentQuestionIndex,
    List<int?>? answers,
  }) {
    return BattlePlayer(
      odId: odId ?? this.odId,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      level: level ?? this.level,
      health: health ?? this.health,
      score: score ?? this.score,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
    );
  }

  @override
  List<Object?> get props => [
        odId,
        username,
        profilePictureUrl,
        level,
        health,
        score,
        currentQuestionIndex,
        answers,
      ];
}

class BattleModel extends Equatable {
  final String id;
  final BattlePlayer player1;
  final BattlePlayer? player2;
  final BattleStatus status;
  final List<String> questionIds;
  final int currentQuestionIndex;
  final int questionTimeLimit; // seconds per question
  final DateTime? questionStartTime;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const BattleModel({
    required this.id,
    required this.player1,
    this.player2,
    this.status = BattleStatus.waiting,
    this.questionIds = const [],
    this.currentQuestionIndex = 0,
    this.questionTimeLimit = 30,
    this.questionStartTime,
    this.winnerId,
    required this.createdAt,
    this.completedAt,
  });

  factory BattleModel.fromRealtimeDb(String id, Map<dynamic, dynamic> data) {
    return BattleModel(
      id: id,
      player1: BattlePlayer.fromMap(Map<String, dynamic>.from(data['player1'] ?? {})),
      player2: data['player2'] != null
          ? BattlePlayer.fromMap(Map<String, dynamic>.from(data['player2']))
          : null,
      status: BattleStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BattleStatus.waiting,
      ),
      questionIds: List<String>.from(data['questionIds'] ?? []),
      currentQuestionIndex: data['currentQuestionIndex'] ?? 0,
      questionTimeLimit: data['questionTimeLimit'] ?? 30,
      questionStartTime: data['questionStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['questionStartTime'])
          : null,
      winnerId: data['winnerId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      completedAt: data['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toRealtimeDb() {
    return {
      'player1': player1.toMap(),
      'player2': player2?.toMap(),
      'status': status.name,
      'questionIds': questionIds,
      'currentQuestionIndex': currentQuestionIndex,
      'questionTimeLimit': questionTimeLimit,
      'questionStartTime': questionStartTime?.millisecondsSinceEpoch,
      'winnerId': winnerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  bool get isWaitingForOpponent => status == BattleStatus.waiting && player2 == null;
  bool get isInProgress => status == BattleStatus.inProgress;
  bool get isCompleted => status == BattleStatus.completed;
  bool get isFull => player2 != null;

  int get totalQuestions => questionIds.length;

  // Calculate damage dealt to opponent for a correct answer
  static int calculateDamage(bool isCorrect, int timeSpentSeconds) {
    if (!isCorrect) return 0;
    if (timeSpentSeconds <= 15) return 15;
    if (timeSpentSeconds <= 30) return 12;
    return 10;
  }

  // Calculate self-damage for wrong or timed-out answers
  static int calculateSelfDamage(bool isCorrect, bool timedOut) {
    if (timedOut) return 15;
    if (!isCorrect) return 8;
    return 0;
  }

  BattleModel copyWith({
    String? id,
    BattlePlayer? player1,
    BattlePlayer? player2,
    BattleStatus? status,
    List<String>? questionIds,
    int? currentQuestionIndex,
    int? questionTimeLimit,
    DateTime? questionStartTime,
    String? winnerId,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return BattleModel(
      id: id ?? this.id,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      status: status ?? this.status,
      questionIds: questionIds ?? this.questionIds,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questionTimeLimit: questionTimeLimit ?? this.questionTimeLimit,
      questionStartTime: questionStartTime ?? this.questionStartTime,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        player1,
        player2,
        status,
        questionIds,
        currentQuestionIndex,
        questionTimeLimit,
        questionStartTime,
        winnerId,
        createdAt,
        completedAt,
      ];
}

// Matchmaking queue entry
class MatchmakingEntry extends Equatable {
  final String odId; // User ID - using odId for backwards compatibility
  final String odUsername; // Username - using odUsername for backwards compatibility
  final String? profilePictureUrl;
  final int level;
  final String testType;
  final DateTime joinedAt;

  const MatchmakingEntry({
    required this.odId,
    required this.odUsername,
    this.profilePictureUrl,
    required this.level,
    this.testType = 'SAT',
    required this.joinedAt,
  });

  // Alias getters
  String get odIdAlias => odId;
  String get username => odUsername;

  factory MatchmakingEntry.fromMap(String odId, Map<dynamic, dynamic> map) {
    return MatchmakingEntry(
      odId: odId,
      odUsername: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      level: map['level'] ?? 1,
      testType: map['testType'] ?? 'SAT',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': odUsername,
      'profilePictureUrl': profilePictureUrl,
      'level': level,
      'testType': testType,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }

  MatchmakingEntry copyWith({
    String? odId,
    String? odUsername,
    String? profilePictureUrl,
    int? level,
    String? testType,
    DateTime? joinedAt,
  }) {
    return MatchmakingEntry(
      odId: odId ?? this.odId,
      odUsername: odUsername ?? this.odUsername,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      level: level ?? this.level,
      testType: testType ?? this.testType,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [odId, odUsername, profilePictureUrl, level, testType, joinedAt];
}
