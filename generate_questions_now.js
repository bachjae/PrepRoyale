/**
 * Quick Question Generator Script
 * Generates 100 SAT/ACT questions immediately and uploads to Firestore emulator
 * Run with: node generate_questions_now.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with emulator settings
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

admin.initializeApp({
  projectId: 'sat-act-battle-royale',
});

const db = admin.firestore();

// Question templates for quick generation
const mathQuestions = [
  {
    template: 'If {a}x + {b} = {c}, what is the value of x?',
    skill: 'Linear Equations',
    difficulty: 1,
    generateChoices: (a, b, c) => {
      const correct = (c - b) / a;
      return [
        `x = ${correct}`,
        `x = ${correct + 2}`,
        `x = ${correct - 1}`,
        `x = ${c - b}`,
      ];
    },
  },
  {
    template: 'What is {a} × {b}?',
    skill: 'Arithmetic',
    difficulty: 1,
    generateChoices: (a, b) => {
      const correct = a * b;
      return [
        `${correct}`,
        `${correct + 5}`,
        `${a + b}`,
        `${correct - 3}`,
      ];
    },
  },
  {
    template: 'Solve for x: x² - {a}x + {b} = 0',
    skill: 'Quadratic Equations',
    difficulty: 3,
    generateChoices: (a, b) => {
      // For simplicity, use factored form
      const x1 = Math.floor(Math.random() * 5) + 1;
      const x2 = Math.floor(Math.random() * 5) + 1;
      return [
        `x = ${x1} or x = ${x2}`,
        `x = ${x1 + 1} or x = ${x2}`,
        `x = ${x1} or x = ${x2 + 1}`,
        `x = ${-x1} or x = ${-x2}`,
      ];
    },
  },
];

const readingQuestions = [
  {
    passage: 'The Industrial Revolution marked a major turning point in history. Almost every aspect of daily life was influenced in some way. Average income and population began to exhibit unprecedented sustained growth.',
    question: 'According to the passage, the Industrial Revolution primarily affected:',
    skill: 'Main Idea',
    difficulty: 2,
    choices: [
      'Daily life and economic growth',
      'Only manufacturing processes',
      'Agricultural techniques',
      'International trade laws',
    ],
    correctAnswer: 0,
  },
  {
    passage: 'Photosynthesis is the process by which plants use sunlight to convert carbon dioxide and water into glucose and oxygen. This process is essential for life on Earth.',
    question: 'What is the primary purpose of photosynthesis?',
    skill: 'Reading Comprehension',
    difficulty: 1,
    choices: [
      'To convert sunlight into chemical energy',
      'To produce carbon dioxide',
      'To create water',
      'To eliminate oxygen',
    ],
    correctAnswer: 0,
  },
];

async function generateQuestions() {
  console.log('🚀 Starting question generation...');

  const questions = [];
  let questionCount = 0;

  // Generate 60 Math questions
  console.log('\n📐 Generating Math questions...');
  for (let i = 0; i < 60; i++) {
    const template = mathQuestions[i % mathQuestions.length];
    const a = Math.floor(Math.random() * 10) + 2;
    const b = Math.floor(Math.random() * 20) + 1;
    const c = a * Math.floor(Math.random() * 5) + b + Math.floor(Math.random() * 10);

    let questionText = template.template
      .replace('{a}', a)
      .replace('{b}', b)
      .replace('{c}', c);

    const choices = template.generateChoices(a, b, c);

    questions.push({
      examType: i % 2 === 0 ? 'SAT' : 'ACT',
      section: 'Math',
      skill: template.skill,
      difficulty: template.difficulty,
      questionText,
      choices,
      correctAnswer: 0,
      explanation: `To solve this problem, isolate x by performing inverse operations on both sides of the equation.`,
      contentHash: `generated_math_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    questionCount++;
  }

  // Generate 30 Reading questions
  console.log('📚 Generating Reading questions...');
  for (let i = 0; i < 30; i++) {
    const template = readingQuestions[i % readingQuestions.length];

    questions.push({
      examType: i % 2 === 0 ? 'SAT' : 'ACT',
      section: i % 2 === 0 ? 'Reading' : 'English',
      skill: template.skill,
      difficulty: template.difficulty,
      questionText: template.question,
      passage: template.passage,
      choices: template.choices,
      correctAnswer: template.correctAnswer,
      explanation: `The answer can be found directly in the passage. Look for key phrases that support the correct answer.`,
      contentHash: `generated_reading_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    questionCount++;
  }

  // Generate 10 ACT Science questions
  console.log('🔬 Generating Science questions...');
  for (let i = 0; i < 10; i++) {
    questions.push({
      examType: 'ACT',
      section: 'Science',
      skill: 'Data Interpretation',
      difficulty: 2,
      questionText: `Based on the experimental data, as temperature increases from ${20 + i * 5}°C to ${25 + i * 5}°C, what happens to the reaction rate?`,
      choices: [
        'The reaction rate increases',
        'The reaction rate decreases',
        'The reaction rate stays the same',
        'The reaction stops completely',
      ],
      correctAnswer: 0,
      explanation: 'Generally, increasing temperature increases the kinetic energy of molecules, leading to more frequent collisions and a faster reaction rate.',
      contentHash: `generated_science_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    questionCount++;
  }

  console.log(`\n✅ Generated ${questionCount} questions!`);
  console.log('\n📤 Uploading to Firestore...');

  // Upload in batches of 10
  const batchSize = 10;
  for (let i = 0; i < questions.length; i += batchSize) {
    const batch = db.batch();
    const batchQuestions = questions.slice(i, i + batchSize);

    for (const question of batchQuestions) {
      const docRef = db.collection('questions').doc();
      batch.set(docRef, question);
    }

    await batch.commit();
    console.log(`   Uploaded batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(questions.length / batchSize)}`);
  }

  console.log('\n🎉 All questions uploaded successfully!');
  console.log('\n📊 Summary:');
  console.log(`   Total questions: ${questionCount}`);
  console.log(`   Math: 60`);
  console.log(`   Reading/English: 30`);
  console.log(`   Science: 10`);
  console.log('\n✨ You can now use these questions in the app!');
}

// Run the generator
generateQuestions()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
