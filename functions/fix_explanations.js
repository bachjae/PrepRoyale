const admin = require('firebase-admin');
const { VertexAI } = require('@google-cloud/vertexai');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, '../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Error: Service account key not found at', serviceAccountPath);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sat-act-battle-royale',
});

const db = admin.firestore();

// Set credentials for Vertex AI (ADC)
process.env.GOOGLE_APPLICATION_CREDENTIALS = serviceAccountPath;

// Initialize Vertex AI
const vertexAI = new VertexAI({
  project: 'sat-act-battle-royale',
  location: 'us-central1',
});

const generativeModel = vertexAI.getGenerativeModel({
  model: 'gemini-2.0-flash',
  generationConfig: {
    maxOutputTokens: 2048,
    temperature: 0.1, // Low temperature for factual rewriting
  },
});

// Sleep helper
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const DRY_RUN = process.argv.includes('--dry-run');

// Regex to catch rambling explanations
const RAMBLING_REGEX = /(Let['’]s try|Something is wrong|Oh,|doesn['’]t work|Wait,|Wait a minute|Hold on|Oops|Hmm)/i;

async function fixExplanation(questionData) {
  const prompt = `
You are an expert test prep tutor. The following question has an explanation that includes "internal monologue" or "rambling" (e.g., trial and error, saying "Let's try" or "Something is wrong").
Please rewrite the explanation to be direct, professional, and definitive. State the facts immediately. Explain why the correct answer is correct and briefly why the distractors are incorrect without any conversational filler.

Question Data:
Skill: ${questionData.skill}
Question: ${questionData.questionText}
Choices: ${JSON.stringify(questionData.choices)}
Correct Choice Index: ${questionData.correctAnswer ?? questionData.correctChoiceIndex}

Original Explanation: 
${questionData.explanation}

Provide ONLY the newly rewritten explanation text. Do not include markdown blocks, intros, or JSON formatting. Just the plain text explanation.
`.trim();

  try {
    const result = await generativeModel.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
    });
    
    let text = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
    if (text) {
      return text.trim();
    }
  } catch (error) {
    console.error('Failed to generate new explanation:', error.message);
  }
  return null;
}

async function run() {
  console.log('Starting Explanation Cleanup Script...');
  console.log(`Mode: ${DRY_RUN ? 'DRY RUN (No database updates)' : 'LIVE UPDATE'}`);
  
  const snapshot = await db.collection('questions').get();
  console.log(`Found ${snapshot.size} total questions in the database.`);
  
  let flaggedCount = 0;
  let fixedCount = 0;
  const flaggedQuestions = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    
    if (data.explanation && RAMBLING_REGEX.test(data.explanation)) {
      flaggedCount++;
      flaggedQuestions.push({
        id: doc.id,
        skill: data.skill,
        question: data.questionText,
        choices: data.choices,
        correctIndex: data.correctAnswer ?? data.correctChoiceIndex,
        explanation: data.explanation
      });
    }
  }
  
  fs.writeFileSync('flagged_questions.json', JSON.stringify(flaggedQuestions, null, 2));
  console.log(`Dumped ${flaggedCount} questions to flagged_questions.json`);
  
  console.log('\n========================================');
  console.log('Summary:');
  console.log(`Total flagged: ${flaggedCount}`);
  console.log(`Total fixed: ${fixedCount}`);
  console.log('Finished.');
  process.exit(0);
}

run().catch(console.error);
