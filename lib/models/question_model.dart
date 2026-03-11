import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Exam types supported by the app
enum ExamType { SAT, ACT }

/// Sections available for each exam type
enum Section {
  // Common sections
  Math,
  Reading,
  Writing,
  // ACT only
  English,
  Science,
}

/// Extension to get valid sections for each exam type
extension ExamTypeExtension on ExamType {
  List<Section> get sections {
    switch (this) {
      case ExamType.SAT:
        return [Section.Math, Section.Reading, Section.Writing];
      case ExamType.ACT:
        return [
          Section.Math,
          Section.Reading,
          Section.English,
          Section.Science
        ];
    }
  }

  String get displayName {
    switch (this) {
      case ExamType.SAT:
        return 'SAT';
      case ExamType.ACT:
        return 'ACT';
    }
  }
}

extension SectionExtension on Section {
  String get displayName {
    switch (this) {
      case Section.Math:
        return 'Math';
      case Section.Reading:
        return 'Reading';
      case Section.Writing:
        return 'Writing';
      case Section.English:
        return 'English';
      case Section.Science:
        return 'Science';
    }
  }
}

// Keep old enum for backwards compatibility during migration
enum TestType { sat, act }

class QuestionModel extends Equatable {
  final String id;
  final String examType; // "SAT" or "ACT"
  final String section; // "Math", "Reading", "Writing", "English", "Science"
  final String skill;
  final String questionText;
  final String? passage;
  final List<String> choices; // Always 4 choices (A, B, C, D)
  final int correctAnswer; // 0-3 index
  final int difficulty; // 1-5
  final String explanation;
  final String? contentHash; // For deduplication
  final DateTime createdAt;

  const QuestionModel({
    required this.id,
    required this.examType,
    required this.section,
    required this.skill,
    required this.questionText,
    this.passage,
    required this.choices,
    required this.correctAnswer,
    required this.difficulty,
    required this.explanation,
    this.contentHash,
    required this.createdAt,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle correctAnswer field - supports both 'correctAnswer' and 'correctChoiceIndex'
    // Also supports letter-based answers (A, B, C, D) commonly found in manually entered data
    int correctAnswer = 0;
    final dynamic rawValue =
        data['correctAnswer'] ?? data['correctChoiceIndex'];

    if (rawValue != null) {
      if (rawValue is int) {
        correctAnswer = rawValue;
      } else {
        final stringValue = rawValue.toString().trim().toUpperCase();
        // Check for numeric string
        final parsedInt = int.tryParse(stringValue);
        if (parsedInt != null) {
          correctAnswer = parsedInt;
        } else {
          // Check for letter (A, B, C, D)
          switch (stringValue) {
            case 'A':
              correctAnswer = 0;
              break;
            case 'B':
              correctAnswer = 1;
              break;
            case 'C':
              correctAnswer = 2;
              break;
            case 'D':
              correctAnswer = 3;
              break;
            default:
              correctAnswer = 0; // Default to first option
          }
        }
      }
    }

    // Handle difficulty field - supports both int and string formats
    int difficulty = 3;
    final difficultyValue = data['difficulty'];
    if (difficultyValue != null) {
      if (difficultyValue is int) {
        difficulty = difficultyValue;
      } else if (difficultyValue is String) {
        // Convert string difficulty to int (1-5 scale)
        switch (difficultyValue.toLowerCase()) {
          case 'easy':
            difficulty = 2;
            break;
          case 'medium':
            difficulty = 3;
            break;
          case 'hard':
            difficulty = 4;
            break;
          default:
            difficulty = int.tryParse(difficultyValue) ?? 3;
        }
      }
    }

    return QuestionModel(
      id: doc.id,
      examType: data['examType'] ?? data['testType'] ?? 'SAT',
      section: data['section'] ?? 'Math',
      skill: data['skill'] ?? '',
      questionText: data['questionText'] ?? '',
      passage: data['passage'],
      choices: List<String>.from(data['choices'] ?? []),
      correctAnswer: correctAnswer,
      difficulty: difficulty,
      explanation: data['explanation'] ?? '',
      contentHash: data['contentHash'] ?? data['hash'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examType': examType,
      'section': section,
      'skill': skill,
      'questionText': questionText,
      'passage': passage,
      'choices': choices,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      'explanation': explanation,
      if (contentHash != null) 'contentHash': contentHash,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get the section key for stats tracking
  String get sectionKey => '${examType}_$section';

  /// Get the correct answer as a letter (A, B, C, D)
  String get correctAnswerLetter {
    const letters = ['A', 'B', 'C', 'D'];
    if (correctAnswer < 0 || correctAnswer >= letters.length) return '?';
    return letters[correctAnswer];
  }

  /// Check if a selected answer index is correct
  bool isAnswerCorrect(int selectedIndex) {
    return selectedIndex == correctAnswer;
  }

  /// Get the ExamType enum value
  ExamType get examTypeEnum {
    return examType == 'ACT' ? ExamType.ACT : ExamType.SAT;
  }

  /// Get the Section enum value
  Section get sectionEnum {
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

  // Legacy getters for backwards compatibility
  TestType get testType => examType == 'ACT' ? TestType.act : TestType.sat;

  /// Create a copy of this question with shuffled answer choices
  /// Returns a new QuestionModel with shuffled choices and updated correctAnswer index
  QuestionModel withShuffledChoices() {
    // Create a list of indices (0, 1, 2, 3)
    final indices = List<int>.generate(choices.length, (i) => i);

    // Shuffle the indices
    indices.shuffle();

    // Create new shuffled choices based on shuffled indices
    final shuffledChoices = indices.map((i) => choices[i]).toList();

    // Find the new position of the correct answer
    final newCorrectAnswer = indices.indexOf(correctAnswer);

    return QuestionModel(
      id: id,
      examType: examType,
      section: section,
      skill: skill,
      questionText: questionText,
      passage: passage,
      choices: shuffledChoices,
      correctAnswer: newCorrectAnswer,
      difficulty: difficulty,
      explanation: explanation,
      contentHash: contentHash,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examType,
        section,
        skill,
        questionText,
        passage,
        choices,
        correctAnswer,
        difficulty,
        explanation,
        contentHash,
        createdAt,
      ];
}

/// User answer record stored in /users/{userId}/answers/{questionId}
class UserAnswer extends Equatable {
  final String id;
  final String questionId;
  final String odId; // Kept for backwards compatibility
  final int selectedChoiceIndex;
  final bool isCorrect;
  final int? timeSpentSeconds;
  final DateTime answeredAt;

  const UserAnswer({
    required this.id,
    required this.questionId,
    required this.odId,
    required this.selectedChoiceIndex,
    required this.isCorrect,
    this.timeSpentSeconds,
    required this.answeredAt,
  });

  // Alias for selectedAnswer to maintain compatibility
  int get selectedAnswer => selectedChoiceIndex;

  // Alias for userId to fix the naming
  String get userId => odId;

  factory UserAnswer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAnswer(
      id: doc.id,
      questionId: data['questionId'] ?? doc.id,
      odId: data['userId'] ?? data['odId'] ?? '',
      selectedChoiceIndex:
          data['selectedChoiceIndex'] ?? data['selectedAnswer'] ?? 0,
      isCorrect: data['isCorrect'] ?? false,
      timeSpentSeconds: data['timeSpentSeconds'],
      answeredAt:
          (data['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a UserAnswer for the new subcollection structure
  factory UserAnswer.forSubcollection({
    required String questionId,
    required int selectedChoiceIndex,
    required bool isCorrect,
    int? timeSpentSeconds,
  }) {
    return UserAnswer(
      id: questionId, // Use questionId as document ID
      questionId: questionId,
      odId: '', // Not needed in subcollection
      selectedChoiceIndex: selectedChoiceIndex,
      isCorrect: isCorrect,
      timeSpentSeconds: timeSpentSeconds,
      answeredAt: DateTime.now(),
    );
  }

  /// Map for the new subcollection structure (/users/{userId}/answers/{questionId})
  Map<String, dynamic> toSubcollectionMap() {
    return {
      'questionId': questionId,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'isCorrect': isCorrect,
      'selectedChoiceIndex': selectedChoiceIndex,
      if (timeSpentSeconds != null) 'timeSpentSeconds': timeSpentSeconds,
    };
  }

  /// Legacy map for top-level userAnswers collection
  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'userId': odId,
      'selectedAnswer': selectedChoiceIndex,
      'selectedChoiceIndex': selectedChoiceIndex,
      'isCorrect': isCorrect,
      if (timeSpentSeconds != null) 'timeSpentSeconds': timeSpentSeconds,
      'answeredAt': Timestamp.fromDate(answeredAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        odId,
        selectedChoiceIndex,
        isCorrect,
        timeSpentSeconds,
        answeredAt,
      ];
}
