/**
 * Quick script to manually generate test questions in the emulator.
 * Run this with: node test-generate.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with emulator settings
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

admin.initializeApp({
  projectId: 'sat-act-battle-royale',
});

const db = admin.firestore();

// Sample questions for testing
const sampleQuestions = [
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Algebra',
    difficulty: 3,
    questionText: 'If 2x + 5 = 15, what is the value of x?',
    choices: ['5', '10', '7.5', '2.5'],
    correctAnswer: 0,
    explanation: 'Subtract 5 from both sides: 2x = 10. Then divide by 2: x = 5.',
    contentHash: 'test_hash_1',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Geometry',
    difficulty: 2,
    questionText: 'What is the area of a rectangle with length 8 and width 5?',
    choices: ['13', '26', '40', '80'],
    correctAnswer: 2,
    explanation: 'Area of rectangle = length × width = 8 × 5 = 40.',
    contentHash: 'test_hash_2',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    examType: 'SAT',
    section: 'Reading',
    skill: 'Main Ideas',
    difficulty: 2,
    questionText: 'What is the main purpose of an introductory paragraph?',
    choices: [
      'To provide detailed examples',
      'To introduce the topic and thesis',
      'To conclude the argument',
      'To list all sources'
    ],
    correctAnswer: 1,
    explanation: 'The introduction serves to introduce the topic and present the main thesis or argument.',
    contentHash: 'test_hash_3',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    examType: 'ACT',
    section: 'Math',
    skill: 'Algebra',
    difficulty: 3,
    questionText: 'Solve for y: 3y - 7 = 14',
    choices: ['7', '21', '7/3', '21/3'],
    correctAnswer: 0,
    explanation: 'Add 7 to both sides: 3y = 21. Divide by 3: y = 7.',
    contentHash: 'test_hash_4',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    examType: 'ACT',
    section: 'Science',
    skill: 'Data Interpretation',
    difficulty: 2,
    questionText: 'Which graph type is best for showing changes over time?',
    choices: ['Pie chart', 'Line graph', 'Bar chart', 'Scatter plot'],
    correctAnswer: 1,
    explanation: 'Line graphs are ideal for showing trends and changes over time periods.',
    contentHash: 'test_hash_5',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function generateTestQuestions() {
  console.log('🔧 Connected to Firestore Emulator at localhost:8080');
  console.log('📝 Generating test questions...');

  const batch = db.batch();

  for (const question of sampleQuestions) {
    const docRef = db.collection('questions').doc();
    batch.set(docRef, question);
    console.log(`  ✓ Added ${question.examType} ${question.section} question: ${question.skill}`);
  }

  await batch.commit();
  console.log(`\n✅ Successfully added ${sampleQuestions.length} test questions to emulator!`);

  // Verify questions were added
  const snapshot = await db.collection('questions').get();
  console.log(`\n📊 Total questions in database: ${snapshot.size}`);

  process.exit(0);
}

generateTestQuestions().catch((error) => {
  console.error('❌ Error generating questions:', error);
  process.exit(1);
});
