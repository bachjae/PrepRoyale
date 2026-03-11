// Run with: dart run tool/seed_questions.dart
// This script seeds sample questions to Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/config/firebase_config.dart';

final sampleQuestions = [
  // SAT Math Questions
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Linear Equations',
    'difficulty': 1,
    'questionText': 'Solve for x: 2x + 6 = 14',
    'choices': ['x = 4', 'x = 5', 'x = 3', 'x = 8'],
    'correctAnswer': 0,
    'explanation': 'Subtract 6 from both sides: 2x = 8. Divide by 2: x = 4.',
    'contentHash': 'sat_math_linear_001',
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Linear Equations',
    'difficulty': 2,
    'questionText': 'If 3(x - 2) = 15, what is the value of x?',
    'choices': ['x = 7', 'x = 5', 'x = 9', 'x = 3'],
    'correctAnswer': 0,
    'explanation': 'Distribute: 3x - 6 = 15. Add 6: 3x = 21. Divide by 3: x = 7.',
    'contentHash': 'sat_math_linear_002',
  },
  // Add more questions here...
];

void main() async {
  await Firebase.initializeApp(options: FirebaseConfig.defaultPlatformOptions);

  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  for (final q in sampleQuestions) {
    final docRef = db.collection('questions').doc();
    batch.set(docRef, {
      ...q,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  print('Seeded ${sampleQuestions.length} questions!');
}
