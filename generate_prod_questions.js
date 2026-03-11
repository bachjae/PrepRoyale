/**
 * Production Question Generator - Writes directly to Firebase (not emulator)
 *
 * SETUP (one time):
 *   1. Go to Firebase Console → Project Settings → Service Accounts
 *   2. Click "Generate new private key" → save as serviceAccountKey.json in this folder
 *   3. Run: node generate_prod_questions.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
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
          choices: [`x = ${correctX}`, `x = ${correctX + 2}`, `x = ${correctX - 1}`, `x = ${Math.floor(c / a)}`],
          correctAnswer: 0,
          explanation: `Subtract ${b} from both sides: ${a}x = ${c - b}. Then divide by ${a}: x = ${correctX}.`,
        };
      },
      skill: 'LinearEquations', difficulty: 2,
    },
    {
      generate: () => {
        const a = Math.floor(Math.random() * 5) + 2;
        const b = Math.floor(Math.random() * 10) + 1;
        const correctX = Math.floor(Math.random() * 8) + 1;
        const c = a * (correctX - b);
        return {
          question: `If ${a}(x - ${b}) = ${c}, what is the value of x?`,
          choices: [`x = ${correctX}`, `x = ${correctX + 1}`, `x = ${Math.floor(c / a)}`, `x = ${correctX - 2}`],
          correctAnswer: 0,
          explanation: `Divide both sides by ${a}: (x - ${b}) = ${c / a}. Add ${b}: x = ${correctX}.`,
        };
      },
      skill: 'LinearEquations', difficulty: 2,
    },
  ],
  systems: [
    {
      generate: () => {
        const x = Math.floor(Math.random() * 8) + 1;
        const y = Math.floor(Math.random() * 8) + 1;
        const a1 = Math.floor(Math.random() * 4) + 1;
        const b1 = Math.floor(Math.random() * 4) + 1;
        const c1 = a1 * x + b1 * y;
        return {
          question: `If ${a1}x + ${b1}y = ${c1} and x = ${x}, what is y?`,
          choices: [`y = ${y}`, `y = ${y + 1}`, `y = ${y - 1}`, `y = ${y + 2}`],
          correctAnswer: 0,
          explanation: `Substitute x = ${x}: ${a1}(${x}) + ${b1}y = ${c1}. Solve: y = ${y}.`,
        };
      },
      skill: 'SystemsOfEquations', difficulty: 3,
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
          choices: [`x = ${r1} and x = ${r2}`, `x = ${r1 + 1} and x = ${r2}`, `x = -${r1} and x = -${r2}`, `x = ${r1} and x = ${r2 + 1}`],
          correctAnswer: 0,
          explanation: `Factor: (x - ${r1})(x - ${r2}) = 0. Solutions: x = ${r1} or x = ${r2}.`,
        };
      },
      skill: 'Quadratics', difficulty: 3,
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
          choices: [`$${salePrice}`, `$${salePrice + 10}`, `$${original - percent}`, `$${salePrice - 5}`],
          correctAnswer: 0,
          explanation: `${percent}% of $${original} = $${discount}. Sale price = $${original} - $${discount} = $${salePrice}.`,
        };
      },
      skill: 'RatiosProportionsPercentages', difficulty: 2,
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
          choices: [`${area}`, `${area + 5}`, `${2 * (length + width)}`, `${area - 3}`],
          correctAnswer: 0,
          explanation: `Area = length × width = ${length} × ${width} = ${area}.`,
        };
      },
      skill: 'GeometryAndTrigonometry', difficulty: 2,
    },
  ],
  statistics: [
    {
      generate: () => {
        const nums = Array.from({ length: 5 }, () => Math.floor(Math.random() * 20) + 1).sort((a, b) => a - b);
        const mean = (nums.reduce((a, b) => a + b, 0) / nums.length).toFixed(1);
        return {
          question: `What is the mean of the data set: ${nums.join(', ')}?`,
          choices: [`${mean}`, `${nums[2]}`, `${parseFloat(mean) + 2}`, `${parseFloat(mean) - 1}`],
          correctAnswer: 0,
          explanation: `Sum all values and divide by 5: (${nums.join(' + ')}) ÷ 5 = ${mean}.`,
        };
      },
      skill: 'StatisticsDataAnalysis', difficulty: 2,
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
          choices: [`${product}`, `${product + 5}`, `${a + b}`, `${product - 7}`],
          correctAnswer: 0,
          explanation: `${a} × ${b} = ${product}.`,
        };
      },
      skill: 'PreAlgebra', difficulty: 1,
    },
  ],
  algebra: [
    {
      generate: () => {
        const base = Math.floor(Math.random() * 5) + 2;
        const exp1 = Math.floor(Math.random() * 4) + 2;
        const exp2 = Math.floor(Math.random() * 4) + 2;
        const result = exp1 + exp2;
        return {
          question: `Simplify: ${base}^${exp1} × ${base}^${exp2}`,
          choices: [`${base}^${result}`, `${base}^${exp1 * exp2}`, `${base * 2}^${exp1 + exp2}`, `${base}^${result - 1}`],
          correctAnswer: 0,
          explanation: `When multiplying powers with the same base, add exponents: ${base}^${exp1} × ${base}^${exp2} = ${base}^${result}.`,
        };
      },
      skill: 'Algebra', difficulty: 2,
    },
  ],
  coordinateGeometry: [
    {
      generate: () => {
        const x1 = Math.floor(Math.random() * 10) - 5;
        const y1 = Math.floor(Math.random() * 10) - 5;
        const x2 = Math.floor(Math.random() * 10);
        const y2 = Math.floor(Math.random() * 10);
        const dist = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2)).toFixed(2);
        return {
          question: `What is the distance between points (${x1}, ${y1}) and (${x2}, ${y2})?`,
          choices: [`${dist}`, `${(parseFloat(dist) + 1).toFixed(2)}`, `${Math.abs(x2 - x1) + Math.abs(y2 - y1)}`, `${(parseFloat(dist) - 0.5).toFixed(2)}`],
          correctAnswer: 0,
          explanation: `Distance = √[(${x2}-${x1})² + (${y2}-${y1})²] = ${dist}.`,
        };
      },
      skill: 'CoordinateGeometry', difficulty: 3,
    },
  ],
  planeGeometry: [
    {
      generate: () => {
        const r = Math.floor(Math.random() * 10) + 2;
        const area = (Math.PI * r * r).toFixed(2);
        return {
          question: `What is the area of a circle with radius ${r}? (Use π ≈ 3.14)`,
          choices: [`${(3.14 * r * r).toFixed(2)}`, `${(2 * 3.14 * r).toFixed(2)}`, `${(3.14 * r).toFixed(2)}`, `${(3.14 * r * r + 10).toFixed(2)}`],
          correctAnswer: 0,
          explanation: `Area = πr² = 3.14 × ${r}² = 3.14 × ${r * r} = ${(3.14 * r * r).toFixed(2)}.`,
        };
      },
      skill: 'PlaneGeometry', difficulty: 2,
    },
  ],
  trigonometry: [
    {
      generate: () => {
        const angle = [30, 45, 60][Math.floor(Math.random() * 3)];
        const vals = { 30: { sin: '1/2', cos: '√3/2', tan: '√3/3' }, 45: { sin: '√2/2', cos: '√2/2', tan: '1' }, 60: { sin: '√3/2', cos: '1/2', tan: '√3' } };
        return {
          question: `What is sin(${angle}°)?`,
          choices: [vals[angle].sin, vals[angle].cos, vals[angle].tan, '1'],
          correctAnswer: 0,
          explanation: `For ${angle}°, sin = ${vals[angle].sin}.`,
        };
      },
      skill: 'Trigonometry', difficulty: 4,
    },
  ],
};

// ============ READING/WRITING PASSAGES ============
const satReadingPassages = [
  {
    passage: 'The Renaissance was a period of cultural rebirth in Europe, spanning roughly from the 14th to the 17th century. It marked a renewed interest in classical Greek and Roman art, literature, and philosophy. Artists like Leonardo da Vinci and Michelangelo created masterpieces that continue to inspire people today.',
    questions: [
      { question: 'According to the passage, the Renaissance primarily involved:', choices: ['A renewed interest in classical culture', 'The rejection of all past traditions', 'A focus solely on scientific advancement', 'The decline of European civilization'], correctAnswer: 0, skill: 'MainIdea', difficulty: 2 },
      { question: 'Which best describes the time period of the Renaissance?', choices: ['From the 14th to 17th century', 'From the 10th to 13th century', 'From the 18th to 20th century', 'From the 1st to 5th century'], correctAnswer: 0, skill: 'SupportingEvidence', difficulty: 1 },
    ],
  },
  {
    passage: 'Climate change poses significant challenges to global ecosystems. Rising temperatures affect weather patterns, sea levels, and biodiversity. Scientists emphasize the urgent need for sustainable practices to mitigate these effects and protect our planet for future generations.',
    questions: [
      { question: 'The primary purpose of this passage is to:', choices: ['Highlight the urgency of addressing climate change', 'Explain the history of climate science', 'Describe specific weather events', 'Compare different ecosystems'], correctAnswer: 0, skill: 'AuthorPurposeTone', difficulty: 2 },
      { question: 'Which of the following is NOT mentioned as an effect of rising temperatures?', choices: ['Changes in ocean salinity', 'Changed weather patterns', 'Rising sea levels', 'Reduced biodiversity'], correctAnswer: 0, skill: 'Inference', difficulty: 3 },
    ],
  },
  {
    passage: 'Photosynthesis is the process by which plants use sunlight, water, and carbon dioxide to produce oxygen and energy in the form of glucose. This process takes place in the chloroplasts of plant cells and is fundamental to life on Earth, as it forms the base of most food chains.',
    questions: [
      { question: 'According to the passage, photosynthesis produces:', choices: ['Oxygen and glucose', 'Carbon dioxide and water', 'Sunlight and energy', 'Chloroplasts and cells'], correctAnswer: 0, skill: 'SupportingEvidence', difficulty: 1 },
      { question: 'Why is photosynthesis described as "fundamental to life on Earth"?', choices: ['It forms the base of most food chains', 'It produces all oxygen in the atmosphere', 'It powers all animal movement', 'It creates all fresh water'], correctAnswer: 0, skill: 'Inference', difficulty: 2 },
    ],
  },
];

const actReadingPassages = [
  {
    passage: 'The Great Migration was the movement of six million African Americans from the rural Southern United States to the urban Northeast, Midwest, and West between 1916 and 1970. This mass migration was driven by poor economic conditions and racial segregation in the South, as well as the promise of better opportunities in industrial cities.',
    questions: [
      { question: 'According to the passage, the Great Migration primarily occurred:', choices: ['Between 1916 and 1970', 'During the Civil War', 'In the 21st century', 'Before 1900'], correctAnswer: 0, skill: 'DetailQuestions', difficulty: 1 },
      { question: 'What motivated African Americans to migrate, according to the passage?', choices: ['Poor economic conditions and racial segregation', 'Natural disasters', 'Government mandates', 'Educational requirements'], correctAnswer: 0, skill: 'MainIdea', difficulty: 2 },
    ],
  },
  {
    passage: 'The invention of the printing press by Johannes Gutenberg in the mid-15th century revolutionized the spread of information in Europe. Before the press, books were painstakingly copied by hand, making them rare and expensive. The press made it possible to produce books quickly and cheaply, dramatically increasing literacy rates.',
    questions: [
      { question: 'Which of the following best states the main idea of the passage?', choices: ['The printing press transformed access to information', 'Books were too expensive before Gutenberg', 'Gutenberg was the most important inventor', 'Literacy rates were always high in Europe'], correctAnswer: 0, skill: 'MainIdea', difficulty: 2 },
      { question: 'According to the passage, books before the printing press were:', choices: ['Rare and expensive', 'Common and affordable', 'Printed but costly', 'Only available to rulers'], correctAnswer: 0, skill: 'DetailQuestions', difficulty: 1 },
    ],
  },
];

// ============ ACT ENGLISH (Grammar) ============
const actEnglishItems = [
  { question: 'The dog wagged it\'s tail happily.\n\nWhich correction should be made?', choices: ['Change "it\'s" to "its"', 'Change "wagged" to "wags"', 'Change "happily" to "happy"', 'No change needed'], correctAnswer: 0, explanation: '"Its" is possessive; "it\'s" means "it is".', skill: 'GrammarUsage', difficulty: 2 },
  { question: 'She enjoys reading, writing, and to paint.\n\nHow should this sentence be corrected?', choices: ['Change "to paint" to "painting"', 'Change "reading" to "to read"', 'Change "writing" to "to write"', 'No change needed'], correctAnswer: 0, explanation: 'Parallel structure requires all items in the list to have the same grammatical form.', skill: 'SentenceStructure', difficulty: 2 },
  { question: 'Neither the students nor the teacher were ready for the test.\n\nWhich correction should be made?', choices: ['Change "were" to "was"', 'Change "Neither" to "Either"', 'Change "nor" to "or"', 'No change needed'], correctAnswer: 0, explanation: 'With "neither...nor," the verb agrees with the nearest subject ("teacher" — singular), so "was" is correct.', skill: 'GrammarUsage', difficulty: 3 },
  { question: 'The team, along with their coaches, are traveling to the competition.\n\nWhich correction should be made?', choices: ['Change "are" to "is"', 'Change "their" to "its"', 'Change "along with" to "and"', 'No change needed'], correctAnswer: 0, explanation: '"The team" is the subject (singular); "along with their coaches" is a parenthetical phrase. Use "is".', skill: 'GrammarUsage', difficulty: 3 },
  { question: 'Running through the park, the flowers smelled beautiful.\n\nWhat is wrong with this sentence?', choices: ['Dangling modifier — the flowers were not running', 'Incorrect verb tense', 'Missing comma after "park"', 'Nothing is wrong'], correctAnswer: 0, explanation: 'The participial phrase "Running through the park" must modify the subject of the main clause — a person, not the flowers.', skill: 'SentenceStructure', difficulty: 3 },
  { question: 'Which sentence uses a semicolon correctly?\n\nA) I love hiking; and camping.\nB) She studied hard; therefore, she passed.\nC) He went to the store; to buy milk.\nD) They played; in the rain.', choices: ['B', 'A', 'C', 'D'], correctAnswer: 0, explanation: 'A semicolon correctly joins two independent clauses. "She studied hard" and "therefore, she passed" are both independent clauses.', skill: 'Punctuation', difficulty: 3 },
  { question: 'The professor asked the students to submit there assignments by Friday.\n\nWhich word should be corrected?', choices: ['"there" should be "their"', '"submit" should be "submitted"', '"professor" should be "professors"', 'No error'], correctAnswer: 0, explanation: '"Their" is the possessive pronoun; "there" indicates a place.', skill: 'GrammarUsage', difficulty: 1 },
  { question: 'The report was lengthy, however it was very informative.\n\nHow should this be corrected?', choices: ['Change the comma after "lengthy" to a semicolon', 'Remove "however"', 'Add a comma after "however"', 'Change "was" to "is"'], correctAnswer: 0, explanation: 'Two independent clauses joined by a conjunctive adverb (however) need a semicolon: "The report was lengthy; however, it was very informative."', skill: 'Punctuation', difficulty: 3 },
];

// ============ SAT WRITING (Grammar) ============
const satWritingItems = [
  { question: 'Which sentence is grammatically correct?', choices: ['The data suggest that the hypothesis is correct.', 'The data suggests that the hypothesis is correct.', 'The data is suggesting the hypothesis is correct.', 'The data have suggested the hypothesis are correct.'], correctAnswer: 0, explanation: '"Data" is the plural of "datum," so it takes the plural verb "suggest."', skill: 'GrammarUsage', difficulty: 3 },
  { question: 'Choose the option that creates the most concise sentence:\n\n"Due to the fact that it was raining, we stayed inside."', choices: ['Because it was raining, we stayed inside.', 'Due to the fact of rain, we stayed indoors.', 'As a result of the raining conditions, we stayed inside.', 'Since rain was occurring, we remained inside.'], correctAnswer: 0, explanation: '"Because" replaces the wordy phrase "due to the fact that" without changing the meaning.', skill: 'Conciseness', difficulty: 2 },
  { question: 'Which option best improves the transition?\n\n"The experiment failed. _____ the team did not give up."', choices: ['Nevertheless,', 'Therefore,', 'For example,', 'In addition,'], correctAnswer: 0, explanation: '"Nevertheless" signals contrast — appropriate when the experiment failing is contrasted with the team\'s persistence.', skill: 'TransitionsAndOrganization', difficulty: 2 },
  { question: 'Identify the error:\n\n"Each of the students must bring their own pencil."', choices: ['Pronoun-antecedent disagreement ("their" should be "his or her")', 'Verb error ("must bring" should be "must have brought")', 'Incorrect use of "own"', 'No error — this is acceptable in modern usage'], correctAnswer: 3, explanation: 'Using "their" as a singular gender-neutral pronoun is widely accepted in modern usage. This sentence is correct.', skill: 'GrammarUsage', difficulty: 4 },
  { question: 'Which punctuation is correct?\n\n"My favorite subjects are math science and history."', choices: ['My favorite subjects are math, science, and history.', 'My favorite subjects are math; science; and history.', 'My favorite subjects are: math, science and history.', 'My favorite subjects are math, science and, history.'], correctAnswer: 0, explanation: 'Use commas to separate items in a list. The Oxford comma before "and" is preferred in formal writing.', skill: 'Punctuation', difficulty: 1 },
];

// ============ ACT SCIENCE ============
const actScienceItems = [
  {
    generate: () => {
      const t1 = Math.floor(Math.random() * 30) + 20;
      const t2 = t1 + 10;
      return { question: `In an experiment, a chemical reaction was observed at two temperatures. At ${t1}°C it took 60 seconds; at ${t2}°C it took 30 seconds.\n\nWhat can be concluded?`, choices: ['Higher temperature increases reaction rate', 'Higher temperature decreases reaction rate', 'Temperature has no effect', 'The reaction stopped at higher temperature'], correctAnswer: 0, explanation: `Reaction time halved as temperature increased from ${t1}°C to ${t2}°C — faster reaction = higher rate.`, skill: 'DataRepresentation', difficulty: 2 };
    },
  },
  {
    generate: () => {
      const pH = Math.floor(Math.random() * 5) + 2;
      const type = pH < 7 ? 'acidic' : pH > 7 ? 'basic' : 'neutral';
      return { question: `A solution has a pH of ${pH}. How would this solution be classified?`, choices: [pH < 7 ? 'Acidic' : pH > 7 ? 'Basic' : 'Neutral', pH < 7 ? 'Basic' : 'Acidic', 'Neutral', 'Unable to determine'], correctAnswer: 0, explanation: `pH < 7 = acidic, pH = 7 = neutral, pH > 7 = basic. pH ${pH} is ${type}.`, skill: 'ResearchSummaries', difficulty: 2 };
    },
  },
  {
    generate: () => {
      const mass = Math.floor(Math.random() * 50) + 10;
      const accel = Math.floor(Math.random() * 10) + 2;
      const force = mass * accel;
      return { question: `An object with mass ${mass} kg accelerates at ${accel} m/s². What force acts on it? (F = ma)`, choices: [`${force} N`, `${force + 10} N`, `${mass + accel} N`, `${force / 2} N`], correctAnswer: 0, explanation: `F = ma = ${mass} × ${accel} = ${force} N.`, skill: 'DataRepresentation', difficulty: 2 };
    },
  },
];

// ============ GENERATION FUNCTIONS ============

function buildFromTemplate(templates, examType, section, count) {
  const questions = [];
  const keys = Object.keys(templates);
  for (let i = 0; i < count; i++) {
    const key = keys[i % keys.length];
    const arr = templates[key];
    const tmpl = arr[Math.floor(Math.random() * arr.length)];
    const q = tmpl.generate();
    questions.push({
      examType, section,
      skill: tmpl.skill,
      difficulty: tmpl.difficulty,
      questionText: q.question,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      contentHash: `${examType}_${section}_${key}_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  return questions;
}

function buildFromPassages(passages, examType, section, count) {
  const questions = [];
  for (let i = 0; i < count; i++) {
    const p = passages[i % passages.length];
    const q = p.questions[i % p.questions.length];
    questions.push({
      examType, section,
      skill: q.skill,
      difficulty: q.difficulty,
      questionText: q.question,
      passage: p.passage,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: 'The answer is directly supported by evidence in the passage.',
      contentHash: `${examType}_${section}_${Date.now()}_${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  return questions;
}

function buildFromItems(items, examType, section, count) {
  const questions = [];
  for (let i = 0; i < count; i++) {
    const q = items[i % items.length];
    const generated = typeof q.generate === 'function' ? q.generate() : q;
    questions.push({
      examType, section,
      skill: generated.skill,
      difficulty: generated.difficulty,
      questionText: generated.question,
      choices: generated.choices,
      correctAnswer: generated.correctAnswer,
      explanation: generated.explanation,
      contentHash: `${examType}_${section}_${Date.now()}_${i}_${Math.random()}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  return questions;
}

async function uploadQuestions(questions) {
  const batchSize = 400; // Firestore max is 500 per batch
  for (let i = 0; i < questions.length; i += batchSize) {
    const batch = db.batch();
    const slice = questions.slice(i, i + batchSize);
    for (const q of slice) {
      batch.set(db.collection('questions').doc(), q);
    }
    await batch.commit();
    console.log(`   Uploaded ${Math.min(i + batchSize, questions.length)}/${questions.length}`);
  }
}

async function main() {
  console.log('🚀 Starting production question generation...\n');

  const COUNT = 500;
  let all = [];

  console.log('📐 SAT Math...');
  all = all.concat(buildFromTemplate(satMathTemplates, 'SAT', 'Math', COUNT));

  console.log('📚 SAT Reading...');
  all = all.concat(buildFromPassages(satReadingPassages, 'SAT', 'Reading', COUNT));

  console.log('✍️  SAT Writing...');
  all = all.concat(buildFromItems(satWritingItems, 'SAT', 'Writing', COUNT));

  console.log('📐 ACT Math...');
  all = all.concat(buildFromTemplate(actMathTemplates, 'ACT', 'Math', COUNT));

  console.log('📚 ACT Reading...');
  all = all.concat(buildFromPassages(actReadingPassages, 'ACT', 'Reading', COUNT));

  console.log('✍️  ACT English...');
  all = all.concat(buildFromItems(actEnglishItems, 'ACT', 'English', COUNT));

  console.log('🔬 ACT Science...');
  all = all.concat(buildFromItems(actScienceItems, 'ACT', 'Science', COUNT));

  console.log(`\n✅ Generated ${all.length} questions total`);
  console.log('📤 Uploading to Firestore...\n');

  await uploadQuestions(all);

  console.log('\n🎉 Done!');
  console.log(`   SAT Math:     ${COUNT}`);
  console.log(`   SAT Reading:  ${COUNT}`);
  console.log(`   SAT Writing:  ${COUNT}`);
  console.log(`   ACT Math:     ${COUNT}`);
  console.log(`   ACT Reading:  ${COUNT}`);
  console.log(`   ACT English:  ${COUNT}`);
  console.log(`   ACT Science:  ${COUNT}`);
  console.log(`   TOTAL:        ${all.length}`);
}

main().then(() => process.exit(0)).catch(e => { console.error('❌ Error:', e.message); process.exit(1); });
