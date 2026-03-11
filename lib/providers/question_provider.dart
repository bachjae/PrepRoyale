import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question_model.dart';
import '../services/achievement_service.dart';
import '../services/firebase_service.dart';
import '../services/local_stats_service.dart';
import '../services/widget_service.dart';
import '../providers/session_provider.dart';

/// Study session state for managing a quiz session
class StudySession {
  final ExamType examType;
  final String section;
  final String? skill;
  final List<QuestionModel> questions;
  final int currentIndex;
  final DateTime? questionStartTime;
  final bool isLoading;
  final String? error;

  const StudySession({
    required this.examType,
    required this.section,
    this.skill,
    this.questions = const [],
    this.currentIndex = 0,
    this.questionStartTime,
    this.isLoading = false,
    this.error,
  });

  QuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  bool get hasMoreQuestions => currentIndex < questions.length - 1;

  int get questionsRemaining => questions.length - currentIndex - 1;

  double get progress =>
      questions.isEmpty ? 0.0 : (currentIndex + 1) / questions.length;

  StudySession copyWith({
    ExamType? examType,
    String? section,
    String? skill,
    List<QuestionModel>? questions,
    int? currentIndex,
    DateTime? questionStartTime,
    bool? isLoading,
    String? error,
  }) {
    return StudySession(
      examType: examType ?? this.examType,
      section: section ?? this.section,
      skill: skill ?? this.skill,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      questionStartTime: questionStartTime ?? this.questionStartTime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Study session notifier for managing quiz state
class StudySessionNotifier extends StateNotifier<StudySession?> {
  final Ref _ref;

  StudySessionNotifier(this._ref) : super(null);

  /// Start a new study session with questions from Firestore
  /// Works for both authenticated users and guests
  Future<void> startSession(
    ExamType examType,
    String section, {
    String? skill,
    int questionCount = 50,
  }) async {
    state = StudySession(
      examType: examType,
      section: section,
      skill: skill,
      isLoading: true,
    );

    try {
      final session = _ref.read(userSessionProvider);
      final firebaseService = _ref.read(firebaseServiceProvider);
      final localStatsService = _ref.read(localStatsServiceProvider);

      // Get answered question IDs based on session type
      Set<String> answeredIds;
      if (session?.isAuthenticated == true && session?.odUserId != null) {
        // Authenticated user - get from Firestore
        answeredIds =
            await firebaseService.getAnsweredQuestionIds(session!.odUserId!);
      } else if (session?.isGuest == true) {
        // Guest user - get from local storage
        answeredIds = await localStatsService.getAnsweredQuestionIds();
      } else {
        state = state!.copyWith(
          isLoading: false,
          error: 'Please sign in or continue as guest to start a study session',
        );
        return;
      }

      // Fetch questions from Firestore (questions are public)
      // NEW LOGIC: Priority 1 = unanswered questions, Priority 2 = review questions
      List<QuestionModel> questions;
      if (session?.isAuthenticated == true && session?.odUserId != null) {
        // Try to get unanswered questions first
        questions = await firebaseService.getUnansweredQuestions(
          userId: session!.odUserId!,
          examType: examType.name,
          section: section,
          skill: skill,
          limit: questionCount,
        );

        // If no unanswered questions, fetch all questions for review
        if (questions.isEmpty) {
          questions = await firebaseService.getQuestions(
            testType: examType == ExamType.SAT ? TestType.sat : TestType.act,
            section: _sectionFromString(section),
            limit: questionCount * 2, // Fetch more for variety
          );
          if (skill != null) {
            questions = questions.where((q) => q.skill == skill).toList();
          }
          // Shuffle for randomized review
          questions.shuffle();
          questions = questions.take(questionCount).toList();
        }
      } else {
        // Guest mode - fetch questions and filter locally
        questions = await _fetchQuestionsForGuest(
          examType: examType.name,
          section: section,
          skill: skill,
          answeredIds: answeredIds,
          limit: questionCount,
        );

        // If no unanswered questions for guests, fetch all questions for review
        if (questions.isEmpty) {
          final allQuestions = await firebaseService.getQuestions(
            testType: examType == ExamType.SAT ? TestType.sat : TestType.act,
            section: _sectionFromString(section),
            limit: questionCount * 2,
          );
          if (skill != null) {
            questions = allQuestions.where((q) => q.skill == skill).toList();
          } else {
            questions = allQuestions;
          }
          // Shuffle for randomized review
          questions.shuffle();
          questions = questions.take(questionCount).toList();
        }
      }

      // Filter out passage-required questions that have no passage
      const passageSections = {'Reading', 'Writing', 'English', 'Science'};
      questions = questions
          .where((q) =>
              !passageSections.contains(q.section) ||
              (q.passage != null && q.passage!.isNotEmpty))
          .toList();

      if (questions.isEmpty) {
        state = state!.copyWith(
          isLoading: false,
          error:
              'No questions available for this section. Please try a different section.',
        );
        return;
      }

      // Shuffle questions for variety
      questions.shuffle();

      // Shuffle answer choices for each question to randomize correct answer position
      final shuffledQuestions =
          questions.map((q) => q.withShuffledChoices()).toList();

      state = state!.copyWith(
        questions: shuffledQuestions,
        isLoading: false,
        questionStartTime: DateTime.now(),
      );
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to load questions: $e',
      );
    }
  }

  /// Fetch questions for guest users
  Future<List<QuestionModel>> _fetchQuestionsForGuest({
    required String examType,
    required String section,
    String? skill,
    required Set<String> answeredIds,
    required int limit,
  }) async {
    final firebaseService = _ref.read(firebaseServiceProvider);

    // Fetch more questions than needed to account for filtering
    final fetchLimit = limit + answeredIds.length.clamp(0, 50);

    // Use the basic getQuestions method
    final allQuestions = await firebaseService.getQuestions(
      testType: examType == 'ACT' ? TestType.act : TestType.sat,
      section: _sectionFromString(section),
      limit: fetchLimit,
    );

    // Filter out already answered questions and filter by skill if provided
    var filtered = allQuestions.where((q) => !answeredIds.contains(q.id));
    // Filter out passage-required questions that have no passage
    filtered = filtered.where((q) =>
        !const {'Reading', 'Writing', 'English', 'Science'}
            .contains(q.section) ||
        (q.passage != null && q.passage!.isNotEmpty));
    if (skill != null) {
      filtered = filtered.where((q) => q.skill == skill);
    }
    return filtered.take(limit).toList();
  }

  Section _sectionFromString(String section) {
    switch (section) {
      case 'Reading':
        return Section.Reading;
      case 'Writing':
        return Section.Writing;
      case 'English':
        return Section.English;
      case 'Science':
        return Section.Science;
      default:
        return Section.Math;
    }
  }

  /// Start a session with legacy TestType/Section enums (for backwards compatibility)
  Future<void> startLegacySession(TestType testType, Section section) async {
    final examType = testType == TestType.sat ? ExamType.SAT : ExamType.ACT;
    final sectionName = section.displayName;
    await startSession(examType, sectionName);
  }

  /// Get time spent on current question in seconds
  int getTimeSpent() {
    if (state?.questionStartTime == null) return 0;
    return DateTime.now().difference(state!.questionStartTime!).inSeconds;
  }

  /// Submit answer for current question and update user stats
  /// Works for both authenticated users and guests
  Future<AnswerResult> submitAnswer(int selectedAnswer) async {
    if (state?.currentQuestion == null) {
      throw Exception('No current question');
    }

    final question = state!.currentQuestion!;
    final isCorrect = question.isAnswerCorrect(selectedAnswer);

    // Robust debug logging for troubleshooting grading issues
    debugPrint('--- GRADING DEBUG ---');
    debugPrint('Question ID: ${question.id}');
    debugPrint('Section: ${question.section} | Mode: ${question.examType}');
    debugPrint('Choices: ${question.choices}');
    debugPrint('Correct Index (Stored): ${question.correctAnswer}');
    if (question.correctAnswer >= 0 &&
        question.correctAnswer < question.choices.length) {
      debugPrint('Correct Text: ${question.choices[question.correctAnswer]}');
    }
    debugPrint('User Selection Index: $selectedAnswer');
    if (selectedAnswer >= 0 && selectedAnswer < question.choices.length) {
      debugPrint('User Selection Text: ${question.choices[selectedAnswer]}');
    }
    debugPrint('Is Correct: $isCorrect');
    debugPrint('Explanation: ${question.explanation}');
    debugPrint('----------------------');
    final timeSpent = getTimeSpent();
    final xpAmount = isCorrect ? 10 : 5;

    final session = _ref.read(userSessionProvider);

    if (session?.isAuthenticated == true && session?.odUserId != null) {
      // Authenticated user - save to Firestore
      final userId = session!.odUserId!;
      final firebaseService = _ref.read(firebaseServiceProvider);

      // Record answer to user's subcollection
      await firebaseService.recordAnswerToSubcollection(
        userId: userId,
        questionId: question.id,
        selectedChoiceIndex: selectedAnswer,
        isCorrect: isCorrect,
        sectionKey: question.sectionKey,
        timeSpentSeconds: timeSpent,
      );

      // Update streaks
      await firebaseService.updateDailyStreak(userId);
      await firebaseService.updateAccuracyStreak(userId, isCorrect);

      // Update stats
      await firebaseService.updateStats(
        userId: userId,
        sectionKey: question.sectionKey,
        isCorrect: isCorrect,
        skill: question.skill,
      );

      // Award XP
      await firebaseService.addXp(userId, xpAmount);

      // Update widget with new streak (run in background, don't await)
      try {
        final widgetService = _ref.read(widgetServiceProvider);
        final userDoc = await firebaseService.getUser(userId);
        if (userDoc != null) {
          final streakCount = userDoc.dailyStreak.count;
          widgetService.updateStreakOnly(streakCount);

          // Check and unlock achievements with fresh user data
          final achievementService = _ref.read(achievementServiceProvider);
          achievementService.checkAndUnlockAchievements(userDoc);
        }
      } catch (e) {
        // Widget update is non-critical, just log the error
        print('Failed to update widget: $e');
      }
    } else if (session?.isGuest == true) {
      // Guest user - save locally
      final localStatsService = _ref.read(localStatsServiceProvider);

      await localStatsService.updateGuestStats(
        questionId: question.id,
        sectionKey: question.sectionKey,
        isCorrect: isCorrect,
        skill: question.skill,
        xpEarned: xpAmount,
      );

      // Refresh guest stats provider
      _ref.invalidate(guestStatsProvider);

      // Update widget with guest streak (run in background, don't await)
      try {
        final widgetService = _ref.read(widgetServiceProvider);
        final guestStats = await localStatsService.getGuestStats();
        widgetService.updateStreakOnly(guestStats.dailyStreakCount);
      } catch (e) {
        // Widget update is non-critical, just log the error
        print('Failed to update widget for guest: $e');
      }
    }

    return AnswerResult(
      isCorrect: isCorrect,
      selectedAnswer: selectedAnswer,
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
      xpEarned: xpAmount,
      timeSpent: timeSpent,
    );
  }

  /// Move to next question
  /// Returns true if there are more questions, false if no more questions available
  bool nextQuestion() {
    if (state == null) return false;

    if (state!.hasMoreQuestions) {
      state = state!.copyWith(
        currentIndex: state!.currentIndex + 1,
        questionStartTime: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  /// Check if there are more questions
  bool get hasMoreQuestions => state?.hasMoreQuestions ?? false;

  /// Load more questions when current batch is exhausted
  /// Returns true if new questions were loaded, false if no questions available
  Future<bool> loadMoreQuestions() async {
    if (state == null) return false;

    final examType = state!.examType;
    final section = state!.section;
    final skill = state!.skill;

    await startSession(examType, section, skill: skill, questionCount: 50);

    // If skill-filtered load came up empty, retry without skill filter
    if ((state?.questions.isEmpty == true || state?.error != null) &&
        skill != null) {
      await startSession(examType, section, questionCount: 50);
    }

    return (state?.questions.isNotEmpty == true) && (state?.error == null);
  }

  /// End the current session
  void endSession() {
    state = null;
  }

  /// Get session summary
  SessionSummary? getSessionSummary() {
    if (state == null) return null;

    return SessionSummary(
      totalQuestions: state!.questions.length,
      questionsAnswered: state!.currentIndex + 1,
      examType: state!.examType,
      section: state!.section,
    );
  }
}

/// Result of submitting an answer
class AnswerResult {
  final bool isCorrect;
  final int selectedAnswer;
  final int correctAnswer;
  final String explanation;
  final int xpEarned;
  final int timeSpent;

  const AnswerResult({
    required this.isCorrect,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.xpEarned,
    required this.timeSpent,
  });

  String get selectedAnswerLetter {
    const letters = ['A', 'B', 'C', 'D'];
    return letters[selectedAnswer];
  }

  String get correctAnswerLetter {
    const letters = ['A', 'B', 'C', 'D'];
    return letters[correctAnswer];
  }
}

/// Summary of a completed study session
class SessionSummary {
  final int totalQuestions;
  final int questionsAnswered;
  final ExamType examType;
  final String section;

  const SessionSummary({
    required this.totalQuestions,
    required this.questionsAnswered,
    required this.examType,
    required this.section,
  });
}

// Providers
final studySessionProvider =
    StateNotifierProvider<StudySessionNotifier, StudySession?>((ref) {
  return StudySessionNotifier(ref);
});

/// Provider for available sections based on exam type
final availableSectionsProvider =
    Provider.family<List<Section>, ExamType>((ref, examType) {
  return examType.sections;
});

/// Provider for getting unanswered question count
/// Works for both authenticated and guest users
final unansweredQuestionCountProvider =
    FutureProvider.family<int, ({String examType, String section})>(
  (ref, params) async {
    final session = ref.watch(userSessionProvider);
    final firebaseService = ref.read(firebaseServiceProvider);
    final localStatsService = ref.read(localStatsServiceProvider);

    Set<String> answeredIds;
    if (session?.isAuthenticated == true && session?.odUserId != null) {
      answeredIds =
          await firebaseService.getAnsweredQuestionIds(session!.odUserId!);
    } else if (session?.isGuest == true) {
      answeredIds = await localStatsService.getAnsweredQuestionIds();
    } else {
      return 0;
    }

    // This is an approximation - we just return a large number minus answered
    // A more accurate count would require querying Firestore for total questions
    final estimatedTotal = 100;
    return (estimatedTotal - answeredIds.length).clamp(0, estimatedTotal);
  },
);

/// Provider for user's total answered questions
/// Works for both authenticated and guest users
final totalAnsweredQuestionsProvider = FutureProvider<int>((ref) async {
  final session = ref.watch(userSessionProvider);

  if (session?.isAuthenticated == true && session?.odUserId != null) {
    final firebaseService = ref.read(firebaseServiceProvider);
    return firebaseService.getAnsweredQuestionCount(session!.odUserId!);
  } else if (session?.isGuest == true) {
    final localStatsService = ref.read(localStatsServiceProvider);
    final stats = await localStatsService.getGuestStats();
    return stats.totalQuestionsAnswered;
  }

  return 0;
});

/// Provider for user's correct answer count
/// Works for both authenticated and guest users
final correctAnswersProvider = FutureProvider<int>((ref) async {
  final session = ref.watch(userSessionProvider);

  if (session?.isAuthenticated == true && session?.odUserId != null) {
    final firebaseService = ref.read(firebaseServiceProvider);
    return firebaseService.getCorrectAnswerCount(session!.odUserId!);
  } else if (session?.isGuest == true) {
    final localStatsService = ref.read(localStatsServiceProvider);
    final stats = await localStatsService.getGuestStats();
    return stats.totalCorrect;
  }

  return 0;
});

/// Provider for user's overall accuracy
final overallAccuracyProvider = FutureProvider<double>((ref) async {
  final total = await ref.watch(totalAnsweredQuestionsProvider.future);
  final correct = await ref.watch(correctAnswersProvider.future);

  if (total == 0) return 0.0;
  return correct / total;
});
