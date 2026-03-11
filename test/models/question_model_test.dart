import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:prep_royale/models/question_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('QuestionModel.fromFirestore', () {
    test('should parse integer correctAnswer', () async {
      final data = {
        'examType': 'SAT',
        'section': 'Math',
        'skill': 'Linear Equations',
        'questionText': 'Solve for x: 2x = 4',
        'choices': ['1', '2', '3', '4'],
        'correctAnswer': 1,
        'difficulty': 1,
        'explanation': '2x = 4 => x = 2',
        'createdAt': Timestamp.now(),
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.correctAnswer, 1);
      expect(question.correctAnswerLetter, 'B');
    });

    test('should parse string numeric correctAnswer', () async {
      final data = {
        'correctAnswer': '2',
        'choices': ['A', 'B', 'C', 'D'],
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.correctAnswer, 2);
      expect(question.correctAnswerLetter, 'C');
    });

    test('should parse letter-based correctAnswer (A)', () async {
      final data = {
        'correctAnswer': 'A',
        'choices': ['A', 'B', 'C', 'D']
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.correctAnswer, 0);
    });

    test('should parse letter-based correctAnswer (D)', () async {
      final data = {
        'correctAnswer': 'D',
        'choices': ['A', 'B', 'C', 'D']
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.correctAnswer, 3);
    });

    test('should handle correctChoiceIndex (legacy field)', () async {
      final data = {
        'correctChoiceIndex': 2,
        'choices': ['A', 'B', 'C', 'D']
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.correctAnswer, 2);
    });

    test('should default to 0 for invalid correctAnswer', () async {
      final data = {
        'correctAnswer': 'Invalid',
        'choices': ['A', 'B', 'C', 'D']
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.correctAnswer, 0);
    });
  });

  group('QuestionModel.isAnswerCorrect', () {
    test('should return true for correct index', () async {
      final data = {
        'correctAnswer': 1,
        'choices': ['A', 'B', 'C', 'D']
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.isAnswerCorrect(1), true);
    });

    test('should return false for incorrect index', () async {
      final data = {
        'correctAnswer': 1,
        'choices': ['A', 'B', 'C', 'D']
      };
      await fakeFirestore.collection('questions').doc('test_id').set(data);
      final doc =
          await fakeFirestore.collection('questions').doc('test_id').get();

      final question = QuestionModel.fromFirestore(doc);
      expect(question.isAnswerCorrect(0), false);
    });
  });
}
