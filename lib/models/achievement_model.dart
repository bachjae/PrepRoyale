import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AchievementCategory {
  questions,
  streaks,
  accuracy,
  battles,
  level,
  social
}

class Achievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int requirement;
  final int bonusXp;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.requirement,
    this.bonusXp = 50,
  });

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '🏆',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => AchievementCategory.questions,
      ),
      requirement: data['requirement'] ?? 0,
      bonusXp: data['bonusXp'] ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'emoji': emoji,
      'category': category.name,
      'requirement': requirement,
      'bonusXp': bonusXp,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, emoji, category, requirement, bonusXp];
}

class UnlockedAchievement extends Equatable {
  final String achievementId;
  final DateTime unlockedAt;

  const UnlockedAchievement({
    required this.achievementId,
    required this.unlockedAt,
  });

  factory UnlockedAchievement.fromMap(Map<String, dynamic> map) {
    return UnlockedAchievement(
      achievementId: map['achievementId'] ?? '',
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
    };
  }

  @override
  List<Object?> get props => [achievementId, unlockedAt];
}

// Default achievements to seed in Firestore
class DefaultAchievements {
  static const List<Achievement> all = [
    // Questions achievements
    Achievement(
      id: 'first_steps',
      name: 'First Steps',
      description: 'Answer 10 questions',
      emoji: '👶',
      category: AchievementCategory.questions,
      requirement: 10,
      bonusXp: 25,
    ),
    Achievement(
      id: 'century',
      name: 'Century',
      description: 'Answer 100 questions',
      emoji: '💯',
      category: AchievementCategory.questions,
      requirement: 100,
      bonusXp: 100,
    ),
    Achievement(
      id: 'dedicated',
      name: 'Dedicated',
      description: 'Answer 500 questions',
      emoji: '📚',
      category: AchievementCategory.questions,
      requirement: 500,
      bonusXp: 250,
    ),
    Achievement(
      id: 'master',
      name: 'Master',
      description: 'Answer 1000 questions',
      emoji: '🎓',
      category: AchievementCategory.questions,
      requirement: 1000,
      bonusXp: 500,
    ),

    // Streak achievements
    Achievement(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: '7 day study streak',
      emoji: '🔥',
      category: AchievementCategory.streaks,
      requirement: 7,
      bonusXp: 75,
    ),
    Achievement(
      id: 'month_champion',
      name: 'Month Champion',
      description: '30 day study streak',
      emoji: '🌟',
      category: AchievementCategory.streaks,
      requirement: 30,
      bonusXp: 300,
    ),
    Achievement(
      id: 'unstoppable',
      name: 'Unstoppable',
      description: '100 day study streak',
      emoji: '💪',
      category: AchievementCategory.streaks,
      requirement: 100,
      bonusXp: 1000,
    ),

    // Accuracy achievements
    Achievement(
      id: 'sharpshooter',
      name: 'Sharpshooter',
      description: '10 correct answers in a row',
      emoji: '🎯',
      category: AchievementCategory.accuracy,
      requirement: 10,
      bonusXp: 50,
    ),
    Achievement(
      id: 'perfectionist',
      name: 'Perfectionist',
      description: '20 correct answers in a row',
      emoji: '⚡',
      category: AchievementCategory.accuracy,
      requirement: 20,
      bonusXp: 100,
    ),
    Achievement(
      id: 'flawless',
      name: 'Flawless',
      description: '50 correct answers in a row',
      emoji: '💎',
      category: AchievementCategory.accuracy,
      requirement: 50,
      bonusXp: 300,
    ),

    // Battle achievements
    Achievement(
      id: 'battle_ready',
      name: 'Battle Ready',
      description: 'Complete 1 battle',
      emoji: '⚔️',
      category: AchievementCategory.battles,
      requirement: 1,
      bonusXp: 25,
    ),
    Achievement(
      id: 'victor',
      name: 'Victor',
      description: 'Win 10 battles',
      emoji: '🏆',
      category: AchievementCategory.battles,
      requirement: 10,
      bonusXp: 100,
    ),
    Achievement(
      id: 'champion',
      name: 'Champion',
      description: 'Win 50 battles',
      emoji: '👑',
      category: AchievementCategory.battles,
      requirement: 50,
      bonusXp: 300,
    ),
    Achievement(
      id: 'legend',
      name: 'Legend',
      description: 'Win 100 battles',
      emoji: '🌈',
      category: AchievementCategory.battles,
      requirement: 100,
      bonusXp: 500,
    ),

    // Level achievements
    Achievement(
      id: 'rising_star',
      name: 'Rising Star',
      description: 'Reach Level 5',
      emoji: '⭐',
      category: AchievementCategory.level,
      requirement: 5,
      bonusXp: 50,
    ),
    Achievement(
      id: 'expert',
      name: 'Expert',
      description: 'Reach Level 20',
      emoji: '🎓',
      category: AchievementCategory.level,
      requirement: 20,
      bonusXp: 200,
    ),
    Achievement(
      id: 'titan',
      name: 'Titan',
      description: 'Reach Level 50',
      emoji: '🔱',
      category: AchievementCategory.level,
      requirement: 50,
      bonusXp: 500,
    ),

    // Social achievements
    Achievement(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      description: 'Add 5 friends',
      emoji: '🦋',
      category: AchievementCategory.social,
      requirement: 5,
      bonusXp: 50,
    ),
    Achievement(
      id: 'influencer',
      name: 'Influencer',
      description: 'Add 20 friends',
      emoji: '🤳',
      category: AchievementCategory.social,
      requirement: 20,
      bonusXp: 200,
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
