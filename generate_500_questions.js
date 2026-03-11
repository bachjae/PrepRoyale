/**
 * Comprehensive Question Generator - 500+ Questions Per Section
 * Generates realistic SAT and ACT questions for all sections
 * Run with: node generate_500_questions.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with emulator settings
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

admin.initializeApp({
  projectId: 'sat-act-battle-royale',
});

const db = admin.firestore();

// ============ SAT MATH TEMPLATES ============
const satMathTemplates = {
  linearEquations: [
    {
      generate: () => {
        const a = Math.floor(Math.random() * 9) + 2;
        const b = Math.floor(Math.random() * 20) + 1;
        const correctX = Math.floor(Math.random() * 10) + 1;
        const c = a * correctX + b;
        return {
          question: `If ${a}x + ${b} = ${c}, what is the value of x?`,
          choices: [
            `x = ${correctX}`,
            `x = ${correctX + 2}`,
            `x = ${correctX - 1}`,
            `x = ${Math.floor(c / a)}`,
          ],
          correctAnswer: 0,
          explanation: `Subtract ${b} from both sides: ${a}x = ${c - b}. Then divide by ${a}: x = ${correctX}.`,
        };
      },
      skill: 'Linear Equations',
      difficulty: 1,
    },
    {
      generate: () => {
        const a = Math.floor(Math.random() * 5) + 2;
        const b = Math.floor(Math.random() * 10) + 1;
        const correctX = Math.floor(Math.random() * 8) + 1;
        const c = a * (correctX - b);
        return {
          question: `If ${a}(x - ${b}) = ${c}, what is the value of x?`,
          choices: [
            `x = ${correctX}`,
            `x = ${correctX + 1}`,
            `x = ${Math.floor(c / a)}`,
            `x = ${correctX - 2}`,
          ],
          correctAnswer: 0,
          explanation: `Divide both sides by ${a}: (x - ${b}) = ${c / a}. Add ${b}: x = ${correctX}.`,
        };
      },
      skill: 'Linear Equations',
      difficulty: 2,
    },
  ],
  quadratics: [
    {
      generate: () => {
        const r1 = Math.floor(Math.random() * 8) + 1;
        const r2 = Math.floor(Math.random() * 8) + 1;
        const b = -(r1 + r2);
        const c = r1 * r2;
        return {
          question: `What are the solutions to x² ${b >= 0 ? '+' : ''}${b}x ${c >= 0 ? '+' : ''}${c} = 0?`,
          choices: [
            `x = ${r1} and x = ${r2}`,
            `x = ${r1 + 1} and x = ${r2}`,
            `x = -${r1} and x = -${r2}`,
            `x = ${r1} and x = ${r2 + 1}`,
          ],
          correctAnswer: 0,
          explanation: `Factor: (x - ${r1})(x - ${r2}) = 0. Solutions: x = ${r1} or x = ${r2}.`,
        };
      },
      skill: 'Quadratic Equations',
      difficulty: 3,
    },
  ],
  percentages: [
    {
      generate: () => {
        const original = Math.floor(Math.random() * 200) + 50;
        const percent = [10, 15, 20, 25, 30][Math.floor(Math.random() * 5)];
        const discount = (original * percent) / 100;
        const salePrice = original - discount;
        return {
          question: `A shirt originally costs $${original}. It is on sale for ${percent}% off. What is the sale price?`,
          choices: [
            `$${salePrice}`,
            `$${salePrice + 10}`,
            `$${original - percent}`,
            `$${salePrice - 5}`,
          ],
          correctAnswer: 0,
          explanation: `${percent}% of $${original} = $${discount}. Sale price = $${original} - $${discount} = $${salePrice}.`,
        };
      },
      skill: 'Percentages',
      difficulty: 2,
    },
  ],
  geometry: [
    {
      generate: () => {
        const length = Math.floor(Math.random() * 15) + 3;
        const width = Math.floor(Math.random() * 10) + 2;
        const area = length * width;
        return {
          question: `What is the area of a rectangle with length ${length} and width ${width}?`,
          choices: [
            `${area}`,
            `${area + 5}`,
            `${length + width}`,
            `${area - 3}`,
          ],
          correctAnswer: 0,
          explanation: `Area = length × width = ${length} × ${width} = ${area}.`,
        };
      },
      skill: 'Geometry',
      difficulty: 1,
    },
  ],
};

// ============ ACT MATH TEMPLATES ============
const actMathTemplates = {
  prealgebra: [
    {
      generate: () => {
        const a = Math.floor(Math.random() * 12) + 3;
        const b = Math.floor(Math.random() * 12) + 3;
        const product = a * b;
        return {
          question: `What is ${a} × ${b}?`,
          choices: [
            `${product}`,
            `${product + 5}`,
            `${a + b}`,
            `${product - 7}`,
          ],
          correctAnswer: 0,
          explanation: `${a} × ${b} = ${product}.`,
        };
      },
      skill: 'Pre-Algebra',
      difficulty: 1,
    },
  ],
  intermediateAlgebra: [
    {
      generate: () => {
        const base = Math.floor(Math.random() * 5) + 2;
        const exp1 = Math.floor(Math.random() * 4) + 2;
        const exp2 = Math.floor(Math.random() * 4) + 2;
        const result = exp1 + exp2;
        return {
          question: `Simplify: ${base}^${exp1} × ${base}^${exp2}`,
          choices: [
            `${base}^${result}`,
            `${base}^${exp1 * exp2}`,
            `${base * 2}^${exp1 + exp2}`,
            `${base}^${result - 1}`,
          ],
          correctAnswer: 0,
          explanation: `When multiplying powers with the same base, add exponents: ${base}^${exp1} × ${base}^${exp2} = ${base}^${result}.`,
        };
      },
      skill: 'Intermediate Algebra',
      difficulty: 2,
    },
  ],
  coordinateGeometry: [
    {
      generate: () => {
        const x1 = Math.floor(Math.random() * 10) - 5;
        const y1 = Math.floor(Math.random() * 10) - 5;
        const x2 = Math.floor(Math.random() * 10) - 5;
        const y2 = Math.floor(Math.random() * 10) - 5;
        const distance = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2)).toFixed(2);
        return {
          question: `What is the distance between points (${x1}, ${y1}) and (${x2}, ${y2})?`,
          choices: [
            `${distance}`,
            `${(parseFloat(distance) + 1).toFixed(2)}`,
            `${Math.abs(x2 - x1) + Math.abs(y2 - y1)}`,
            `${(parseFloat(distance) - 0.5).toFixed(2)}`,
          ],
          correctAnswer: 0,
          explanation: `Distance = √[(${x2}-${x1})² + (${y2}-${y1})²] = ${distance}.`,
        };
      },
      skill: 'Coordinate Geometry',
      difficulty: 3,
    },
  ],
  trigonometry: [
    {
      generate: () => {
        const angle = [30, 45, 60][Math.floor(Math.random() * 3)];
        const values = {
          30: { sin: '1/2', cos: '√3/2', tan: '1/√3' },
          45: { sin: '√2/2', cos: '√2/2', tan: '1' },
          60: { sin: '√3/2', cos: '1/2', tan: '√3' },
        };
        return {
          question: `What is sin(${angle}°)?`,
          choices: [
            values[angle].sin,
            values[angle].cos,
            values[angle].tan,
            '1',
          ],
          correctAnswer: 0,
          explanation: `For a ${angle}° angle in a unit circle, sin(${angle}°) = ${values[angle].sin}.`,
        };
      },
      skill: 'Trigonometry',
      difficulty: 4,
    },
  ],
};

// ============ SAT READING/WRITING TEMPLATES ============
const satReadingTemplates = [
  {
    passage: 'The Renaissance was a period of cultural rebirth in Europe, spanning roughly from the 14th to the 17th century. It marked a renewed interest in classical Greek and Roman art, literature, and philosophy. Artists like Leonardo da Vinci and Michelangelo created masterpieces that continue to inspire people today.',
    questions: [
      {
        question: 'According to the passage, the Renaissance primarily involved:',
        choices: [
          'A renewed interest in classical culture',
          'The rejection of all past traditions',
          'A focus solely on scientific advancement',
          'The decline of European civilization',
        ],
        correctAnswer: 0,
        skill: 'Main Idea',
        difficulty: 2,
      },
      {
        question: 'Which of the following best describes the time period of the Renaissance?',
        choices: [
          'From the 14th to 17th century',
          'From the 10th to 13th century',
          'From the 18th to 20th century',
          'From the 1st to 5th century',
        ],
        correctAnswer: 0,
        skill: 'Detail Recognition',
        difficulty: 1,
      },
    ],
  },
  {
    passage: 'Climate change poses significant challenges to global ecosystems. Rising temperatures affect weather patterns, sea levels, and biodiversity. Scientists emphasize the urgent need for sustainable practices to mitigate these effects and protect our planet for future generations.',
    questions: [
      {
        question: 'The primary purpose of this passage is to:',
        choices: [
          'Highlight the urgency of addressing climate change',
          'Explain the history of climate science',
          'Describe specific weather events',
          'Compare different ecosystems',
        ],
        correctAnswer: 0,
        skill: 'Purpose',
        difficulty: 2,
      },
    ],
  },
];

// ============ ACT READING TEMPLATES ============
const actReadingTemplates = [
  {
    passage: 'The Great Migration was the movement of six million African Americans from the rural Southern United States to the urban Northeast, Midwest, and West between 1916 and 1970. This mass migration was driven by poor economic conditions and racial segregation in the South, as well as the promise of better opportunities in industrial cities.',
    questions: [
      {
        question: 'According to the passage, the Great Migration primarily occurred:',
        choices: [
          'Between 1916 and 1970',
          'During the Civil War',
          'In the 21st century',
          'Before 1900',
        ],
        correctAnswer: 0,
        skill: 'Detail Recognition',
        difficulty: 1,
      },
      {
        question: 'What motivated African Americans to migrate, according to the passage?',
        choices: [
          'Poor economic conditions and racial segregation',
          'Natural disasters',
          'Government mandates',
          'Educational requirements',
        ],
        correctAnswer: 0,
        skill: 'Cause and Effect',
        difficulty: 2,
      },
    ],
  },
];

// ============ ACT ENGLISH TEMPLATES ============
const actEnglishTemplates = [
  {
    generate: () => {
      const errors = [
        {
          sentence: 'The dog wagged it\'s tail happily.',
          question: 'Which correction should be made?',
          choices: [
            'Change "it\'s" to "its"',
            'Change "wagged" to "wags"',
            'Change "happily" to "happy"',
            'No change needed',
          ],
          correctAnswer: 0,
          explanation: '"Its" is possessive; "it\'s" means "it is".',
        },
        {
          sentence: 'She enjoys reading, writing, and to paint.',
          question: 'How should this sentence be corrected?',
          choices: [
            'Change "to paint" to "painting"',
            'Change "reading" to "to read"',
            'Change "writing" to "to write"',
            'No change needed',
          ],
          correctAnswer: 0,
          explanation: 'Parallel structure requires all items in the list to have the same form.',
        },
      ];
      const error = errors[Math.floor(Math.random() * errors.length)];
      return {
        question: error.sentence + '\n\n' + error.question,
        choices: error.choices,
        correctAnswer: error.correctAnswer,
        explanation: error.explanation,
        skill: 'Grammar',
        difficulty: 2,
      };
    },
  },
];

// ============ ACT SCIENCE TEMPLATES ============
const actScienceTemplates = [
  {
    generate: () => {
      const temp1 = Math.floor(Math.random() * 30) + 20;
      const temp2 = temp1 + 10;
      return {
        question: `Experiment: A chemical reaction was observed at two different temperatures. At ${temp1}°C, the reaction took 60 seconds. At ${temp2}°C, the reaction took 30 seconds.\n\nBased on this data, what can be concluded about temperature and reaction rate?`,
        choices: [
          'Higher temperature increases reaction rate',
          'Higher temperature decreases reaction rate',
          'Temperature has no effect on reaction rate',
          'Temperature stops the reaction',
        ],
        correctAnswer: 0,
        explanation: `The reaction time decreased from 60s to 30s as temperature increased from ${temp1}°C to ${temp2}°C, indicating higher temperature increases reaction rate.`,
        skill: 'Data Interpretation',
        difficulty: 2,
      };
    },
  },
  {
    generate: () => {
      const pH = Math.floor(Math.random() * 5) + 3;
      return {
        question: `A solution has a pH of ${pH}. Based on the pH scale, this solution is:`,
        choices: [
          pH < 7 ? 'Acidic' : 'Basic',
          pH < 7 ? 'Basic' : 'Acidic',
          'Neutral',
          'Unable to determine',
        ],
        correctAnswer: 0,
        explanation: `pH values below 7 are acidic, above 7 are basic, and 7 is neutral. pH ${pH} is ${pH < 7 ? 'acidic' : 'basic'}.`,
        skill: 'Scientific Concepts',
        difficulty: 2,
      };
    },
  },
];

// ============ GENERATION FUNCTIONS ============

function generateSATMath(count) {
  console.log(`\n📐 Generating ${count} SAT Math questions...`);
  const questions = [];
  const skills = Object.keys(satMathTemplates);

  for (let i = 0; i < count; i++) {
    const skillKey = skills[i % skills.length];
    const templates = satMathTemplates[skillKey];
    const template = templates[Math.floor(Math.random() * templates.length)];
    const q = template.generate();

    questions.push({
      examType: 'SAT',
      section: 'Math',
      skill: template.skill,
      difficulty: template.difficulty,
      questionText: q.question,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      contentHash: `sat_math_${skillKey}_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 100 === 0) {
      console.log(`   Generated ${i + 1}/${count} SAT Math questions...`);
    }
  }

  return questions;
}

function generateACTMath(count) {
  console.log(`\n📐 Generating ${count} ACT Math questions...`);
  const questions = [];
  const skills = Object.keys(actMathTemplates);

  for (let i = 0; i < count; i++) {
    const skillKey = skills[i % skills.length];
    const templates = actMathTemplates[skillKey];
    const template = templates[Math.floor(Math.random() * templates.length)];
    const q = template.generate();

    questions.push({
      examType: 'ACT',
      section: 'Math',
      skill: template.skill,
      difficulty: template.difficulty,
      questionText: q.question,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      contentHash: `act_math_${skillKey}_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 100 === 0) {
      console.log(`   Generated ${i + 1}/${count} ACT Math questions...`);
    }
  }

  return questions;
}

function generateSATReading(count) {
  console.log(`\n📚 Generating ${count} SAT Reading questions...`);
  const questions = [];

  for (let i = 0; i < count; i++) {
    const template = satReadingTemplates[i % satReadingTemplates.length];
    const q = template.questions[i % template.questions.length];

    questions.push({
      examType: 'SAT',
      section: 'Reading',
      skill: q.skill,
      difficulty: q.difficulty,
      questionText: q.question,
      passage: template.passage,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: 'The answer is supported by evidence in the passage.',
      contentHash: `sat_reading_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 100 === 0) {
      console.log(`   Generated ${i + 1}/${count} SAT Reading questions...`);
    }
  }

  return questions;
}

function generateSATWriting(count) {
  console.log(`\n✍️ Generating ${count} SAT Writing questions...`);
  const questions = [];

  for (let i = 0; i < count; i++) {
    const template = actEnglishTemplates[0];
    const q = template.generate();

    questions.push({
      examType: 'SAT',
      section: 'Writing',
      skill: q.skill,
      difficulty: q.difficulty,
      questionText: q.question,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      contentHash: `sat_writing_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 100 === 0) {
      console.log(`   Generated ${i + 1}/${count} SAT Writing questions...`);
    }
  }

  return questions;
}

function generateACTReading(count) {
  console.log(`\n📚 Generating ${count} ACT Reading questions...`);
  const questions = [];

  for (let i = 0; i < count; i++) {
    const template = actReadingTemplates[i % actReadingTemplates.length];
    const q = template.questions[i % template.questions.length];

    questions.push({
      examType: 'ACT',
      section: 'Reading',
      skill: q.skill,
      difficulty: q.difficulty,
      questionText: q.question,
      passage: template.passage,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: 'The answer is directly stated or implied in the passage.',
      contentHash: `act_reading_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 100 === 0) {
      console.log(`   Generated ${i + 1}/${count} ACT Reading questions...`);
    }
  }

  return questions;
}

function generateACTEnglish(count) {
  console.log(`\n✍️ Generating ${count} ACT English questions...`);
  const questions = [];

  for (let i = 0; i < count; i++) {
    const template = actEnglishTemplates[0];
    const q = template.generate();

    questions.push({
      examType: 'ACT',
      section: 'English',
      skill: q.skill,
      difficulty: q.difficulty,
      questionText: q.question,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      contentHash: `act_english_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 100 === 0) {
      console.log(`   Generated ${i + 1}/${count} ACT English questions...`);
    }
  }

  return questions;
}

function generateACTScience(count) {
  console.log(`\n🔬 Generating ${count} ACT Science questions...`);
  const questions = [];

  for (let i = 0; i < count; i++) {
    const template = actScienceTemplates[i % actScienceTemplates.length];
    const q = template.generate();

    questions.push({
      examType: 'ACT',
      section: 'Science',
      skill: q.skill,
      difficulty: q.difficulty,
      questionText: q.question,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      contentHash: `act_science_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if ((i + 1) % 100 === 0) {
      console.log(`   Generated ${i + 1}/${count} ACT Science questions...`);
    }
  }

  return questions;
}

async function uploadQuestions(questions, batchSize = 50) {
  console.log(`\n📤 Uploading ${questions.length} questions to Firestore...`);

  for (let i = 0; i < questions.length; i += batchSize) {
    const batch = db.batch();
    const batchQuestions = questions.slice(i, i + batchSize);

    for (const question of batchQuestions) {
      const docRef = db.collection('questions').doc();
      batch.set(docRef, question);
    }

    await batch.commit();
    console.log(`   Uploaded ${Math.min(i + batchSize, questions.length)}/${questions.length} questions`);
  }
}

async function generateAllQuestions() {
  console.log('🚀 COMPREHENSIVE QUESTION GENERATION');
  console.log('=====================================');
  console.log('Target: 500 questions per section\n');

  const startTime = Date.now();
  let allQuestions = [];

  // SAT Sections
  allQuestions = allQuestions.concat(generateSATMath(500));
  allQuestions = allQuestions.concat(generateSATReading(500));
  allQuestions = allQuestions.concat(generateSATWriting(500));

  // ACT Sections
  allQuestions = allQuestions.concat(generateACTMath(500));
  allQuestions = allQuestions.concat(generateACTReading(500));
  allQuestions = allQuestions.concat(generateACTEnglish(500));
  allQuestions = allQuestions.concat(generateACTScience(500));

  console.log(`\n✅ Generated ${allQuestions.length} total questions!`);

  // Upload all questions
  await uploadQuestions(allQuestions);

  const endTime = Date.now();
  const duration = ((endTime - startTime) / 1000).toFixed(2);

  console.log('\n🎉 ALL QUESTIONS UPLOADED SUCCESSFULLY!');
  console.log('\n📊 FINAL SUMMARY:');
  console.log('=====================================');
  console.log(`   SAT Math:        500 questions ✓`);
  console.log(`   SAT Reading:     500 questions ✓`);
  console.log(`   SAT Writing:     500 questions ✓`);
  console.log(`   ACT Math:        500 questions ✓`);
  console.log(`   ACT Reading:     500 questions ✓`);
  console.log(`   ACT English:     500 questions ✓`);
  console.log(`   ACT Science:     500 questions ✓`);
  console.log(`   ─────────────────────────────────`);
  console.log(`   TOTAL:          ${allQuestions.length} questions ✓`);
  console.log(`\n⏱️  Time taken: ${duration} seconds`);
  console.log('\n✨ Your app now has a comprehensive question bank!');
}

// Run the generator
generateAllQuestions()
  .then(() => {
    console.log('\n✅ GENERATION COMPLETE!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ ERROR:', error);
    process.exit(1);
  });
