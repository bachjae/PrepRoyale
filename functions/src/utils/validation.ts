/**
 * Question validation and deduplication utilities.
 * Uses SHA-256 hashing for duplicate detection.
 */

import * as crypto from "crypto";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { GeneratedQuestion } from "./geminiHelper";

// Lazy initialization to ensure admin.initializeApp() is called first
function getDb() {
  return admin.firestore();
}

// Get server timestamp safely
function getServerTimestamp() {
  return FieldValue.serverTimestamp();
}

// Question document interface for Firestore
export interface QuestionDocument {
  examType: string;
  section: string;
  skill: string;
  difficulty: string;
  questionText: string;
  passage?: string; // Optional passage for Reading/Writing/Science/English questions
  choices: string[];
  correctChoiceIndex: number;
  explanation: string;
  createdAt: FieldValue;
  sourceModel: string;
  hash: string;
}

/**
 * Generate a stable hash of the question text for deduplication.
 * Uses SHA-256 and normalizes the text to avoid false negatives.
 */
export function generateQuestionHash(questionText: string): string {
  // Normalize: lowercase, remove extra whitespace, remove punctuation variations
  const normalized = questionText
    .toLowerCase()
    .replace(/\s+/g, " ")
    .replace(/['']/g, "'")
    .replace(/[""]/g, '"')
    .trim();

  return crypto.createHash("sha256").update(normalized).digest("hex");
}

/**
 * Check if a question with the given hash already exists in Firestore.
 */
export async function questionExists(hash: string): Promise<boolean> {
  const snapshot = await getDb().collection("questions")
    .where("hash", "==", hash)
    .limit(1)
    .get();

  return !snapshot.empty;
}

/**
 * Batch check for existing questions by hash.
 * More efficient than checking one by one.
 */
export async function filterExistingQuestions(
  questions: GeneratedQuestion[]
): Promise<GeneratedQuestion[]> {
  if (questions.length === 0) return [];

  // Generate hashes for all questions
  const questionsWithHashes = questions.map(q => ({
    question: q,
    hash: generateQuestionHash(q.questionText)
  }));

  // Get unique hashes
  const uniqueHashes = [...new Set(questionsWithHashes.map(q => q.hash))];

  // Batch query for existing hashes (Firestore limits 'in' to 30 items)
  const existingHashes = new Set<string>();
  const batchSize = 30;

  for (let i = 0; i < uniqueHashes.length; i += batchSize) {
    const batchHashes = uniqueHashes.slice(i, i + batchSize);

    const snapshot = await getDb().collection("questions")
      .where("hash", "in", batchHashes)
      .select("hash")
      .get();

    snapshot.docs.forEach(doc => {
      existingHashes.add(doc.data().hash);
    });
  }

  // Filter out questions that already exist
  const newQuestions = questionsWithHashes
    .filter(q => !existingHashes.has(q.hash))
    .map(q => q.question);

  const duplicateCount = questions.length - newQuestions.length;
  if (duplicateCount > 0) {
    console.log(`Filtered out ${duplicateCount} duplicate questions`);
  }

  return newQuestions;
}

/**
 * Convert a GeneratedQuestion to a Firestore document.
 */
export function toFirestoreDocument(
  question: GeneratedQuestion,
  sourceModel: string = "gemini-2.0-flash"
): QuestionDocument {
  const doc: QuestionDocument = {
    examType: question.examType,
    section: question.section,
    skill: question.skill,
    difficulty: question.difficulty,
    questionText: question.questionText,
    choices: question.choices,
    correctChoiceIndex: question.correctChoiceIndex,
    explanation: question.explanation,
    createdAt: getServerTimestamp(),
    sourceModel,
    hash: generateQuestionHash(question.questionText)
  };

  // Include passage if present (Reading/Writing/Science/English questions)
  if (question.passage) {
    doc.passage = question.passage;
  }

  return doc;
}

/**
 * Write questions to Firestore in batches.
 * Uses batched writes for efficiency (max 500 operations per batch).
 */
export async function writeQuestionsToFirestore(
  questions: GeneratedQuestion[],
  sourceModel: string = "gemini-2.0-flash"
): Promise<{ written: number; skipped: number }> {
  if (questions.length === 0) {
    return { written: 0, skipped: 0 };
  }

  // Filter out duplicates first
  const newQuestions = await filterExistingQuestions(questions);
  const skipped = questions.length - newQuestions.length;

  if (newQuestions.length === 0) {
    return { written: 0, skipped };
  }

  // Write in batches of 500 (Firestore limit)
  const batchSize = 500;
  let written = 0;

  for (let i = 0; i < newQuestions.length; i += batchSize) {
    const batch = getDb().batch();
    const batchQuestions = newQuestions.slice(i, i + batchSize);

    for (const question of batchQuestions) {
      const docRef = getDb().collection("questions").doc();
      const document = toFirestoreDocument(question, sourceModel);
      batch.set(docRef, document);
    }

    await batch.commit();
    written += batchQuestions.length;

    console.log(`Written batch: ${written}/${newQuestions.length} questions`);
  }

  return { written, skipped };
}

/**
 * Get current question counts by skill for planning generation.
 */
export async function getQuestionCountsBySkill(
  examType: string,
  section: string
): Promise<Map<string, number>> {
  const counts = new Map<string, number>();

  // Query questions grouped by skill
  const snapshot = await getDb().collection("questions")
    .where("examType", "==", examType)
    .where("section", "==", section)
    .select("skill")
    .get();

  // Count questions per skill
  for (const doc of snapshot.docs) {
    const skill = doc.data().skill;
    counts.set(skill, (counts.get(skill) || 0) + 1);
  }

  return counts;
}

/**
 * Determine how many questions need to be generated for each skill.
 * Returns a map of skill -> needed count.
 */
export async function getQuestionDeficit(
  examType: string,
  section: string,
  skills: readonly string[],
  targetPerSkill: number
): Promise<Map<string, number>> {
  const currentCounts = await getQuestionCountsBySkill(examType, section);
  const deficit = new Map<string, number>();

  for (const skill of skills) {
    const current = currentCounts.get(skill) || 0;
    const needed = Math.max(0, targetPerSkill - current);
    if (needed > 0) {
      deficit.set(skill, needed);
    }
  }

  return deficit;
}

/**
 * Log a generation run for auditing and debugging.
 */
export async function logGenerationRun(
  examType: string,
  section: string,
  skill: string,
  attempted: number,
  generated: number,
  written: number,
  skipped: number,
  error?: string
): Promise<void> {
  await getDb().collection("generationLogs").add({
    examType,
    section,
    skill,
    attempted,
    generated,
    written,
    skipped,
    error: error || null,
    timestamp: getServerTimestamp()
  });
}
