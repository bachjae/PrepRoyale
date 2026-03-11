import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Tracks accuracy for a specific skill
class SkillStats extends Equatable {
  final int totalAttempts;
  final int correctAnswers;

  const SkillStats({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
  });

  double get accuracy => totalAttempts == 0 ? 0.0 : correctAnswers / totalAttempts;

  factory SkillStats.fromMap(Map<String, dynamic> map) {
    return SkillStats(
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

  SkillStats copyWith({
    int? totalAttempts,
    int? correctAnswers,
  }) {
    return SkillStats(
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
    );
  }

  @override
  List<Object?> get props => [totalAttempts, correctAnswers];
}

class UserStats extends Equatable {
  final int totalQuestions;
  final Map<String, double> sectionAccuracy; // e.g., {'SAT_Math': 0.85, 'SAT_Reading': 0.72}
  final Map<String, SkillStats> skillStats; // e.g., {'SAT_Math_LinearEquations': SkillStats}

  const UserStats({
    this.totalQuestions = 0,
    this.sectionAccuracy = const {},
    this.skillStats = const {},
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    final skillStatsMap = <String, SkillStats>{};
    if (map['skillStats'] != null) {
      final rawSkillStats = map['skillStats'] as Map<String, dynamic>;
      for (final entry in rawSkillStats.entries) {
        skillStatsMap[entry.key] = SkillStats.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    return UserStats(
      totalQuestions: map['totalQuestions'] ?? 0,
      sectionAccuracy: Map<String, double>.from(map['sectionAccuracy'] ?? {}),
      skillStats: skillStatsMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalQuestions': totalQuestions,
      'sectionAccuracy': sectionAccuracy,
      'skillStats': skillStats.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  double get overallAccuracy {
    if (sectionAccuracy.isEmpty) return 0.0;
    return sectionAccuracy.values.reduce((a, b) => a + b) / sectionAccuracy.length;
  }

  /// Get skill stats for a specific section (e.g., 'SAT_Math' returns all SAT_Math_* skills)
  Map<String, SkillStats> getSkillsForSection(String sectionKey) {
    return Map.fromEntries(
      skillStats.entries.where((e) => e.key.startsWith('${sectionKey}_')),
    );
  }

  /// Get formatted skill name (e.g., 'SAT_Math_LinearEquations' -> 'Linear Equations')
  static String formatSkillName(String skillKey) {
    // Extract skill name (last part after last underscore)
    final parts = skillKey.split('_');
    if (parts.length < 3) return skillKey;

    final skillName = parts.sublist(2).join('_');
    // Convert camelCase to Title Case with spaces
    return skillName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }

  UserStats copyWith({
    int? totalQuestions,
    Map<String, double>? sectionAccuracy,
    Map<String, SkillStats>? skillStats,
  }) {
    return UserStats(
      totalQuestions: totalQuestions ?? this.totalQuestions,
      sectionAccuracy: sectionAccuracy ?? this.sectionAccuracy,
      skillStats: skillStats ?? this.skillStats,
    );
  }

  @override
  List<Object?> get props => [totalQuestions, sectionAccuracy, skillStats];
}

class DailyStreak extends Equatable {
  final int count;
  final DateTime? lastDate;
  final int best;

  const DailyStreak({
    this.count = 0,
    this.lastDate,
    this.best = 0,
  });

  factory DailyStreak.fromMap(Map<String, dynamic> map) {
    return DailyStreak(
      count: map['count'] ?? 0,
      lastDate: map['lastDate'] != null
          ? (map['lastDate'] as Timestamp).toDate()
          : null,
      best: map['best'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'lastDate': lastDate != null ? Timestamp.fromDate(lastDate!) : null,
      'best': best,
    };
  }

  DailyStreak copyWith({
    int? count,
    DateTime? lastDate,
    int? best,
  }) {
    return DailyStreak(
      count: count ?? this.count,
      lastDate: lastDate ?? this.lastDate,
      best: best ?? this.best,
    );
  }

  @override
  List<Object?> get props => [count, lastDate, best];
}

class AccuracyStreak extends Equatable {
  final int current;
  final int best;

  const AccuracyStreak({
    this.current = 0,
    this.best = 0,
  });

  factory AccuracyStreak.fromMap(Map<String, dynamic> map) {
    return AccuracyStreak(
      current: map['current'] ?? 0,
      best: map['best'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current': current,
      'best': best,
    };
  }

  AccuracyStreak copyWith({
    int? current,
    int? best,
  }) {
    return AccuracyStreak(
      current: current ?? this.current,
      best: best ?? this.best,
    );
  }

  @override
  List<Object?> get props => [current, best];
}

class BattleStats extends Equatable {
  final int wins;
  final int losses;

  const BattleStats({
    this.wins = 0,
    this.losses = 0,
  });

  factory BattleStats.fromMap(Map<String, dynamic> map) {
    return BattleStats(
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wins': wins,
      'losses': losses,
    };
  }

  double get winRate {
    final total = wins + losses;
    if (total == 0) return 0.0;
    return wins / total;
  }

  int get totalBattles => wins + losses;

  BattleStats copyWith({
    int? wins,
    int? losses,
  }) {
    return BattleStats(
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
    );
  }

  @override
  List<Object?> get props => [wins, losses];
}

/// User notification preferences
class NotificationPreferences extends Equatable {
  final bool dailyReminder;
  final bool friendRequests;
  final bool friendBattleInvites;
  final bool friendRequestAccepted;
  final bool streakWarnings;
  final bool achievementUnlocks;
  final bool leaderboardChanges;
  final int dailyReminderTime; // Hour of day (0-23), default 14 (2 PM)

  const NotificationPreferences({
    this.dailyReminder = true,
    this.friendRequests = true,
    this.friendBattleInvites = true,
    this.friendRequestAccepted = true,
    this.streakWarnings = true,
    this.achievementUnlocks = true,
    this.leaderboardChanges = true,
    this.dailyReminderTime = 14,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      dailyReminder: map['dailyReminder'] ?? true,
      friendRequests: map['friendRequests'] ?? true,
      friendBattleInvites: map['friendBattleInvites'] ?? true,
      friendRequestAccepted: map['friendRequestAccepted'] ?? true,
      streakWarnings: map['streakWarnings'] ?? true,
      achievementUnlocks: map['achievementUnlocks'] ?? true,
      leaderboardChanges: map['leaderboardChanges'] ?? true,
      dailyReminderTime: map['dailyReminderTime'] ?? 14,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyReminder': dailyReminder,
      'friendRequests': friendRequests,
      'friendBattleInvites': friendBattleInvites,
      'friendRequestAccepted': friendRequestAccepted,
      'streakWarnings': streakWarnings,
      'achievementUnlocks': achievementUnlocks,
      'leaderboardChanges': leaderboardChanges,
      'dailyReminderTime': dailyReminderTime,
    };
  }

  NotificationPreferences copyWith({
    bool? dailyReminder,
    bool? friendRequests,
    bool? friendBattleInvites,
    bool? friendRequestAccepted,
    bool? streakWarnings,
    bool? achievementUnlocks,
    bool? leaderboardChanges,
    int? dailyReminderTime,
  }) {
    return NotificationPreferences(
      dailyReminder: dailyReminder ?? this.dailyReminder,
      friendRequests: friendRequests ?? this.friendRequests,
      friendBattleInvites: friendBattleInvites ?? this.friendBattleInvites,
      friendRequestAccepted: friendRequestAccepted ?? this.friendRequestAccepted,
      streakWarnings: streakWarnings ?? this.streakWarnings,
      achievementUnlocks: achievementUnlocks ?? this.achievementUnlocks,
      leaderboardChanges: leaderboardChanges ?? this.leaderboardChanges,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    );
  }

  @override
  List<Object?> get props => [
        dailyReminder,
        friendRequests,
        friendBattleInvites,
        friendRequestAccepted,
        streakWarnings,
        achievementUnlocks,
        leaderboardChanges,
        dailyReminderTime,
      ];
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? friendCode; // Unique 8-character alphanumeric code for adding friends
  final String? profilePictureUrl;
  final int level;
  final int xp;
  final int totalXp;
  final UserStats stats;
  final DailyStreak dailyStreak;
  final AccuracyStreak accuracyStreak;
  final BattleStats battleStats;
  final List<String> unlockedAchievements;
  final NotificationPreferences notificationPreferences;
  final String? fcmToken; // Firebase Cloud Messaging token for push notifications
  final DateTime? lastDailyReminderSent; // Track when last daily reminder was sent
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.friendCode,
    this.profilePictureUrl,
    this.level = 1,
    this.xp = 0,
    this.totalXp = 0,
    this.stats = const UserStats(),
    this.dailyStreak = const DailyStreak(),
    this.accuracyStreak = const AccuracyStreak(),
    this.battleStats = const BattleStats(),
    this.unlockedAchievements = const [],
    this.notificationPreferences = const NotificationPreferences(),
    this.fcmToken,
    this.lastDailyReminderSent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      friendCode: data['friendCode'],
      profilePictureUrl: data['profilePictureUrl'],
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      totalXp: data['totalXp'] ?? 0,
      stats: UserStats.fromMap(data['stats'] ?? {}),
      dailyStreak: DailyStreak.fromMap(data['dailyStreak'] ?? {}),
      accuracyStreak: AccuracyStreak.fromMap(data['accuracyStreak'] ?? {}),
      battleStats: BattleStats.fromMap(data['battleStats'] ?? {}),
      unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
      notificationPreferences: NotificationPreferences.fromMap(data['notificationPreferences'] ?? {}),
      fcmToken: data['fcmToken'],
      lastDailyReminderSent: (data['lastDailyReminderSent'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'friendCode': friendCode,
      'profilePictureUrl': profilePictureUrl,
      'level': level,
      'xp': xp,
      'totalXp': totalXp,
      'stats': stats.toMap(),
      'dailyStreak': dailyStreak.toMap(),
      'accuracyStreak': accuracyStreak.toMap(),
      'battleStats': battleStats.toMap(),
      'unlockedAchievements': unlockedAchievements,
      'notificationPreferences': notificationPreferences.toMap(),
      'fcmToken': fcmToken,
      'lastDailyReminderSent': lastDailyReminderSent != null ? Timestamp.fromDate(lastDailyReminderSent!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // XP required to reach a specific level
  static int xpForLevel(int level) {
    return 100 * level * level; // Quadratic scaling
  }

  // XP needed for next level
  int get xpToNextLevel => xpForLevel(level + 1) - totalXp;

  // Progress to next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelXp = xpForLevel(level);
    final nextLevelXp = xpForLevel(level + 1);
    final xpIntoLevel = totalXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    return (xpIntoLevel / xpNeeded).clamp(0.0, 1.0);
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? friendCode,
    String? profilePictureUrl,
    int? level,
    int? xp,
    int? totalXp,
    UserStats? stats,
    DailyStreak? dailyStreak,
    AccuracyStreak? accuracyStreak,
    BattleStats? battleStats,
    List<String>? unlockedAchievements,
    NotificationPreferences? notificationPreferences,
    String? fcmToken,
    DateTime? lastDailyReminderSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      friendCode: friendCode ?? this.friendCode,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      totalXp: totalXp ?? this.totalXp,
      stats: stats ?? this.stats,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      accuracyStreak: accuracyStreak ?? this.accuracyStreak,
      battleStats: battleStats ?? this.battleStats,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      fcmToken: fcmToken ?? this.fcmToken,
      lastDailyReminderSent: lastDailyReminderSent ?? this.lastDailyReminderSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        friendCode,
        profilePictureUrl,
        level,
        xp,
        totalXp,
        stats,
        dailyStreak,
        accuracyStreak,
        battleStats,
        unlockedAchievements,
        notificationPreferences,
        fcmToken,
        lastDailyReminderSent,
        createdAt,
        updatedAt,
      ];
}
