import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../models/question_model.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _friendCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding 0, O, 1, I for clarity

  // Collection references
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _questionsRef => _firestore.collection('questions');
  CollectionReference get _userAnswersRef => _firestore.collection('userAnswers');

  /// Generate a random 8-character friend code
  String _generateFriendCode() {
    final random = Random.secure();
    return List.generate(8, (_) => _friendCodeChars[random.nextInt(_friendCodeChars.length)]).join();
  }

  /// Generate a unique friend code with collision checking
  Future<String> _generateUniqueFriendCode() async {
    const maxAttempts = 10;
    for (var i = 0; i < maxAttempts; i++) {
      final code = _generateFriendCode();
      final existing = await _usersRef.where('friendCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }
    // Extremely unlikely to reach here with 8-char codes
    throw Exception('Failed to generate unique friend code after $maxAttempts attempts');
  }

  // ============ USER OPERATIONS ============

  // Create a new user profile
  Future<void> createUser({
    required String userId,
    required String email,
    required String username,
    String? profilePictureUrl,
  }) async {
    final now = DateTime.now();
    // Generate a unique friend code for the new user
    final friendCode = await _generateUniqueFriendCode();
    final user = UserModel(
      id: userId,
      email: email,
      username: username,
      friendCode: friendCode,
      profilePictureUrl: profilePictureUrl,
      createdAt: now,
      updatedAt: now,
    );
    final userData = user.toMap();
    // Add lowercase username for case-insensitive search
    userData['usernameLower'] = username.toLowerCase();
    await _usersRef.doc(userId).set(userData);
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Check if username is available (case-insensitive)
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _usersRef
        .where('usernameLower', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? profilePictureUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };
    if (username != null) {
      updates['username'] = username;
      updates['usernameLower'] = username.toLowerCase(); // For search
    }
    if (profilePictureUrl != null) updates['profilePictureUrl'] = profilePictureUrl;

    await _usersRef.doc(userId).update(updates);
  }

  // ============ XP & LEVEL OPERATIONS ============

  // Add XP and potentially level up
  Future<LevelUpResult> addXp(String userId, int xpAmount) async {
    final userDoc = _usersRef.doc(userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) {
        throw Exception('User not found');
      }

      final user = UserModel.fromFirestore(snapshot);
      final newTotalXp = user.totalXp + xpAmount;

      // Calculate new level
      int newLevel = user.level;
      while (newTotalXp >= UserModel.xpForLevel(newLevel + 1)) {
        newLevel++;
      }

      final didLevelUp = newLevel > user.level;

      // Check level achievements
      final unlocked = user.unlockedAchievements;
      final toUnlock = <String>[];
      if (newLevel >= 5 && !unlocked.contains('rising_star')) toUnlock.add('rising_star');
      if (newLevel >= 20 && !unlocked.contains('expert')) toUnlock.add('expert');
      if (newLevel >= 50 && !unlocked.contains('titan')) toUnlock.add('titan');

      final xpUpdates = <String, dynamic>{
        'xp': user.xp + xpAmount,
        'totalXp': newTotalXp,
        'level': newLevel,
        'updatedAt': Timestamp.now(),
      };
      if (toUnlock.isNotEmpty) {
        xpUpdates['unlockedAchievements'] = FieldValue.arrayUnion(toUnlock);
      }

      transaction.update(userDoc, xpUpdates);

      return LevelUpResult(
        newLevel: newLevel,
        newTotalXp: newTotalXp,
        didLevelUp: didLevelUp,
      );
    });
  }

  // ============ STREAK OPERATIONS ============

  // Update daily streak
  Future<StreakUpdateResult> updateDailyStreak(String userId) async {
    final userDoc = _usersRef.doc(userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) {
        throw Exception('User not found');
      }

      final user = UserModel.fromFirestore(snapshot);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final lastDate = user.dailyStreak.lastDate;
      int newCount = user.dailyStreak.count;
      bool didIncrement = false;

      if (lastDate == null) {
        // First ever activity
        newCount = 1;
        didIncrement = true;
      } else {
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final difference = today.difference(lastDay).inDays;

        if (difference == 0) {
          // Same day, no change
        } else if (difference == 1) {
          // Consecutive day
          newCount++;
          didIncrement = true;
        } else {
          // Streak broken, reset
          newCount = 1;
          didIncrement = true;
        }
      }

      final newBest = newCount > user.dailyStreak.best ? newCount : user.dailyStreak.best;

      // Check streak achievements
      final streakUnlocked = user.unlockedAchievements;
      final streakToUnlock = <String>[];
      if (newCount >= 7 && !streakUnlocked.contains('week_warrior')) streakToUnlock.add('week_warrior');
      if (newCount >= 30 && !streakUnlocked.contains('month_champion')) streakToUnlock.add('month_champion');
      if (newCount >= 100 && !streakUnlocked.contains('unstoppable')) streakToUnlock.add('unstoppable');

      final streakUpdates = <String, dynamic>{
        'dailyStreak.count': newCount,
        'dailyStreak.lastDate': Timestamp.fromDate(today),
        'dailyStreak.best': newBest,
        'updatedAt': Timestamp.now(),
      };
      if (streakToUnlock.isNotEmpty) {
        streakUpdates['unlockedAchievements'] = FieldValue.arrayUnion(streakToUnlock);
      }

      transaction.update(userDoc, streakUpdates);

      return StreakUpdateResult(
        newCount: newCount,
        didIncrement: didIncrement,
        isNewBest: newCount > user.dailyStreak.best,
      );
    });
  }

  // Update accuracy streak
  Future<StreakUpdateResult> updateAccuracyStreak(String userId, bool isCorrect) async {
    final userDoc = _usersRef.doc(userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) {
        throw Exception('User not found');
      }

      final user = UserModel.fromFirestore(snapshot);
      int newCurrent;

      if (isCorrect) {
        newCurrent = user.accuracyStreak.current + 1;
      } else {
        newCurrent = 0;
      }

      final newBest = newCurrent > user.accuracyStreak.best
          ? newCurrent
          : user.accuracyStreak.best;

      // Check accuracy streak achievements
      final accUnlocked = user.unlockedAchievements;
      final accToUnlock = <String>[];
      if (newCurrent >= 10 && !accUnlocked.contains('sharpshooter')) accToUnlock.add('sharpshooter');
      if (newCurrent >= 20 && !accUnlocked.contains('perfectionist')) accToUnlock.add('perfectionist');
      if (newCurrent >= 50 && !accUnlocked.contains('flawless')) accToUnlock.add('flawless');

      final accUpdates = <String, dynamic>{
        'accuracyStreak.current': newCurrent,
        'accuracyStreak.best': newBest,
        'updatedAt': Timestamp.now(),
      };
      if (accToUnlock.isNotEmpty) {
        accUpdates['unlockedAchievements'] = FieldValue.arrayUnion(accToUnlock);
      }

      transaction.update(userDoc, accUpdates);

      return StreakUpdateResult(
        newCount: newCurrent,
        didIncrement: isCorrect,
        isNewBest: newCurrent > user.accuracyStreak.best,
      );
    });
  }

  // ============ STATS OPERATIONS ============

  // Update user stats after answering a question
  // Tracks both section-level and skill-level accuracy
  Future<void> updateStats({
    required String userId,
    required String sectionKey, // e.g., 'SAT_Math'
    required bool isCorrect,
    String? skill, // e.g., 'LinearEquations' - optional for skill tracking
  }) async {
    final userDoc = _usersRef.doc(userId);
    final skillKey = skill != null ? '${sectionKey}_$skill' : null;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return;

      final user = UserModel.fromFirestore(snapshot);
      final newTotal = user.stats.totalQuestions + 1;

      // Calculate new section accuracy
      final currentAccuracy = user.stats.sectionAccuracy[sectionKey] ?? 0.0;
      final sectionQuestions = await _getSectionQuestionCount(userId, sectionKey);
      final correctCount = (currentAccuracy * sectionQuestions).round();
      final newCorrectCount = isCorrect ? correctCount + 1 : correctCount;
      final newAccuracy = sectionQuestions > 0
          ? newCorrectCount / (sectionQuestions + 1)
          : (isCorrect ? 1.0 : 0.0);

      final newSectionAccuracy = Map<String, double>.from(user.stats.sectionAccuracy);
      newSectionAccuracy[sectionKey] = newAccuracy;

      final updates = <String, dynamic>{
        'stats.totalQuestions': newTotal,
        'stats.sectionAccuracy': newSectionAccuracy,
        'updatedAt': Timestamp.now(),
      };

      // Update skill-level stats if skill is provided
      if (skillKey != null) {
        final currentSkillStats = user.stats.skillStats[skillKey] ??
            const SkillStats(totalAttempts: 0, correctAnswers: 0);
        final newSkillStats = SkillStats(
          totalAttempts: currentSkillStats.totalAttempts + 1,
          correctAnswers: currentSkillStats.correctAnswers + (isCorrect ? 1 : 0),
        );
        updates['stats.skillStats.$skillKey'] = newSkillStats.toMap();
      }

      // Check question count achievements
      final unlocked = user.unlockedAchievements;
      final toUnlock = <String>[];
      if (newTotal >= 10 && !unlocked.contains('first_steps')) toUnlock.add('first_steps');
      if (newTotal >= 100 && !unlocked.contains('century')) toUnlock.add('century');
      if (newTotal >= 500 && !unlocked.contains('dedicated')) toUnlock.add('dedicated');
      if (newTotal >= 1000 && !unlocked.contains('master')) toUnlock.add('master');
      if (toUnlock.isNotEmpty) {
        updates['unlockedAchievements'] = FieldValue.arrayUnion(toUnlock);
      }

      transaction.update(userDoc, updates);
    });
  }

  Future<int> _getSectionQuestionCount(String userId, String sectionKey) async {
    // Count only answers for the specific section
    final userAnswersQuery = await _usersRef
        .doc(userId)
        .collection('answers')
        .where('sectionKey', isEqualTo: sectionKey)
        .get();
    return userAnswersQuery.docs.length;
  }

  // ============ BATTLE STATS OPERATIONS ============

  // Update battle stats
  Future<void> updateBattleStats(String userId, bool isWinner) async {
    await _usersRef.doc(userId).update({
      if (isWinner) 'battleStats.wins': FieldValue.increment(1),
      if (!isWinner) 'battleStats.losses': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  // ============ ACHIEVEMENT OPERATIONS ============

  // Add unlocked achievement
  Future<void> unlockAchievement(String userId, String achievementId) async {
    await _usersRef.doc(userId).update({
      'unlockedAchievements': FieldValue.arrayUnion([achievementId]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ============ QUESTION OPERATIONS ============

  /// Get questions by exam type and section that the user hasn't answered yet.
  /// Uses the new Firestore schema with examType and section fields.
  /// Implements a fetch-and-retry strategy to ensure we get enough unanswered questions.
  Future<List<QuestionModel>> getUnansweredQuestions({
    required String userId,
    required String examType,
    required String section,
    String? skill,
    int limit = 10,
  }) async {
    // First, get all question IDs the user has already answered
    final answeredIds = await getAnsweredQuestionIds(userId);

    final List<QuestionModel> unansweredQuestions = [];
    DocumentSnapshot? lastDoc;
    int fetchAttempts = 0;
    const maxAttempts = 10; // Prevent infinite loops
    const batchSize = 50; // Fetch in batches

    // Keep fetching until we have enough unanswered questions or exhaust attempts
    while (unansweredQuestions.length < limit && fetchAttempts < maxAttempts) {
      // Build query for questions
      Query query = _questionsRef
          .where('examType', isEqualTo: examType)
          .where('section', isEqualTo: section);

      if (skill != null) {
        query = query.where('skill', isEqualTo: skill);
      }

      // For pagination, start after the last document
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      // Fetch a batch
      final snapshot = await query.limit(batchSize).get();

      // If no more documents, break
      if (snapshot.docs.isEmpty) {
        break;
      }

      // Filter out already answered questions and add to result
      for (final doc in snapshot.docs) {
        if (!answeredIds.contains(doc.id)) {
          unansweredQuestions.add(QuestionModel.fromFirestore(doc));
          if (unansweredQuestions.length >= limit) {
            break;
          }
        }
      }

      // Update last document for pagination
      lastDoc = snapshot.docs.last;
      fetchAttempts++;
    }

    return unansweredQuestions;
  }

  /// Get questions by test type and section (legacy method for backwards compatibility)
  Future<List<QuestionModel>> getQuestions({
    required TestType testType,
    required Section section,
    int limit = 10,
  }) async {
    final examType = testType == TestType.sat ? 'SAT' : 'ACT';
    final sectionName = section.name.substring(0, 1).toUpperCase() + section.name.substring(1);

    final query = await _questionsRef
        .where('examType', isEqualTo: examType)
        .where('section', isEqualTo: sectionName)
        .limit(limit)
        .get();

    return query.docs.map((doc) => QuestionModel.fromFirestore(doc)).toList();
  }

  /// Get a random set of questions for a battle
  Future<List<QuestionModel>> getRandomQuestionsForBattle({
    int count = 5,
  }) async {
    // Get more questions than needed and randomly select
    final snapshot = await _questionsRef.limit(count * 4).get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    final questions = snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc))
        .toList();

    questions.shuffle();
    return questions.take(count).toList();
  }

  /// Get question by ID
  Future<QuestionModel?> getQuestion(String questionId) async {
    final doc = await _questionsRef.doc(questionId).get();
    if (!doc.exists) return null;
    return QuestionModel.fromFirestore(doc);
  }

  /// Get multiple questions by IDs
  Future<List<QuestionModel>> getQuestionsByIds(List<String> questionIds) async {
    if (questionIds.isEmpty) return [];

    // Firestore whereIn is limited to 30 items
    final List<QuestionModel> questions = [];
    for (var i = 0; i < questionIds.length; i += 30) {
      final batch = questionIds.skip(i).take(30).toList();
      final snapshot = await _questionsRef
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      questions.addAll(snapshot.docs.map((doc) => QuestionModel.fromFirestore(doc)));
    }

    return questions;
  }

  // ============ USER ANSWER OPERATIONS ============

  /// Get all question IDs that a user has already answered.
  /// Uses the subcollection /users/{userId}/answers/
  Future<Set<String>> getAnsweredQuestionIds(String userId) async {
    final snapshot = await _usersRef
        .doc(userId)
        .collection('answers')
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// Record an answer in the user's subcollection.
  /// Document ID is the questionId to prevent duplicate answers.
  Future<void> recordAnswerToSubcollection({
    required String userId,
    required String questionId,
    required int selectedChoiceIndex,
    required bool isCorrect,
    String? sectionKey,
    int? timeSpentSeconds,
  }) async {
    await _usersRef
        .doc(userId)
        .collection('answers')
        .doc(questionId)
        .set({
      'questionId': questionId,
      'answeredAt': FieldValue.serverTimestamp(),
      'isCorrect': isCorrect,
      'selectedChoiceIndex': selectedChoiceIndex,
      if (sectionKey != null) 'sectionKey': sectionKey,
      if (timeSpentSeconds != null) 'timeSpentSeconds': timeSpentSeconds,
    });
  }

  /// Check if user has already answered a specific question
  Future<bool> hasAnsweredQuestion(String userId, String questionId) async {
    final doc = await _usersRef
        .doc(userId)
        .collection('answers')
        .doc(questionId)
        .get();
    return doc.exists;
  }

  /// Record user answer (legacy method - writes to both locations for compatibility)
  Future<void> recordAnswer(UserAnswer answer) async {
    // Write to user's subcollection (new format)
    await recordAnswerToSubcollection(
      userId: answer.userId,
      questionId: answer.questionId,
      selectedChoiceIndex: answer.selectedChoiceIndex,
      isCorrect: answer.isCorrect,
      timeSpentSeconds: answer.timeSpentSeconds,
    );

    // Also write to legacy userAnswers collection for backwards compatibility
    await _userAnswersRef.add(answer.toMap());
  }

  /// Get user's answer history with pagination
  Future<List<UserAnswer>> getAnswerHistory({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _usersRef
        .doc(userId)
        .collection('answers')
        .orderBy('answeredAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => UserAnswer.fromFirestore(doc)).toList();
  }

  /// Get count of questions answered by user
  Future<int> getAnsweredQuestionCount(String userId) async {
    final snapshot = await _usersRef
        .doc(userId)
        .collection('answers')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get count of correct answers by user
  Future<int> getCorrectAnswerCount(String userId) async {
    final snapshot = await _usersRef
        .doc(userId)
        .collection('answers')
        .where('isCorrect', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}

// Result classes
class LevelUpResult {
  final int newLevel;
  final int newTotalXp;
  final bool didLevelUp;

  LevelUpResult({
    required this.newLevel,
    required this.newTotalXp,
    required this.didLevelUp,
  });
}

class StreakUpdateResult {
  final int newCount;
  final bool didIncrement;
  final bool isNewBest;

  StreakUpdateResult({
    required this.newCount,
    required this.didIncrement,
    required this.isNewBest,
  });
}
