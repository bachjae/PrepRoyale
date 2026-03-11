/**
 * Daily batch question generator.
 * Runs once per day to generate questions for all skills defined in QUESTION_CONFIG.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  QUESTION_CONFIG,
  ExamType,
  getSkillsForSection,
  getPerSkillCount
} from "../config/questionConfig";
import { generateQuestionsBatch } from "../utils/geminiHelper";
import {
  getQuestionDeficit,
  writeQuestionsToFirestore,
  logGenerationRun
} from "../utils/validation";

// Configuration for daily generation
const DAILY_CONFIG = {
  // Maximum questions to generate per run
  // Increased to ensure we always have plenty of questions available
  maxQuestionsPerRun: 1000,
  // Batch size for each Gemini call
  batchSize: 10,
  // Delay between skill generations (ms)
  delayBetweenSkills: 3000, // Reduced delay for faster generation
  // Maximum skills to process per run
  maxSkillsPerRun: 40 // Increased to process more skills per run
};

interface GenerationResult {
  examType: string;
  section: string;
  skill: string;
  attempted: number;
  generated: number;
  written: number;
  skipped: number;
  error?: string;
}

/**
 * Generate questions for a single skill.
 */
async function generateForSkill(
  examType: string,
  section: string,
  skill: string,
  targetCount: number
): Promise<GenerationResult> {
  const result: GenerationResult = {
    examType,
    section,
    skill,
    attempted: targetCount,
    generated: 0,
    written: 0,
    skipped: 0
  };

  try {
    console.log(`Generating ${targetCount} questions for ${examType}/${section}/${skill}`);

    // Generate questions in batches
    const questions = await generateQuestionsBatch(
      examType,
      section,
      skill,
      targetCount,
      DAILY_CONFIG.batchSize
    );

    result.generated = questions.length;

    // Write to Firestore with deduplication
    const writeResult = await writeQuestionsToFirestore(questions);
    result.written = writeResult.written;
    result.skipped = writeResult.skipped;

    console.log(`Skill ${skill}: Generated ${result.generated}, Written ${result.written}, Skipped ${result.skipped}`);

  } catch (error) {
    result.error = (error as Error).message;
    console.error(`Error generating for ${skill}:`, error);
  }

  // Log the run
  await logGenerationRun(
    examType,
    section,
    skill,
    result.attempted,
    result.generated,
    result.written,
    result.skipped,
    result.error
  );

  return result;
}

/**
 * Sleep helper
 */
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Run the daily generation for all configured skills.
 * Prioritizes skills with the largest deficit.
 */
export async function runDailyGeneration(): Promise<{
  totalGenerated: number;
  totalWritten: number;
  results: GenerationResult[];
}> {
  console.log("Starting daily question generation...");

  const results: GenerationResult[] = [];
  let totalGenerated = 0;
  let totalWritten = 0;
  let skillsProcessed = 0;

  // Collect all skills with their deficits
  const skillsToProcess: Array<{
    examType: ExamType;
    section: string;
    skill: string;
    deficit: number;
  }> = [];

  // Iterate over all exam types and sections
  for (const examType of Object.keys(QUESTION_CONFIG) as ExamType[]) {
    const examConfig = QUESTION_CONFIG[examType];

    for (const section of Object.keys(examConfig)) {
      const skills = getSkillsForSection(examType, section);
      const targetPerSkill = getPerSkillCount(examType, section);

      // Get deficit for each skill
      const deficits = await getQuestionDeficit(examType, section, skills, targetPerSkill);

      for (const [skill, deficit] of deficits.entries()) {
        skillsToProcess.push({ examType, section, skill, deficit });
      }
    }
  }

  // Sort by deficit (highest first) to prioritize skills needing most questions
  skillsToProcess.sort((a, b) => b.deficit - a.deficit);

  console.log(`Found ${skillsToProcess.length} skills with deficits`);

  // Process skills up to our daily limits
  for (const item of skillsToProcess) {
    // Check if we've hit our limits
    if (skillsProcessed >= DAILY_CONFIG.maxSkillsPerRun) {
      console.log("Reached max skills per run limit");
      break;
    }

    if (totalGenerated >= DAILY_CONFIG.maxQuestionsPerRun) {
      console.log("Reached max questions per run limit");
      break;
    }

    // Calculate how many questions to generate for this skill
    const remaining = DAILY_CONFIG.maxQuestionsPerRun - totalGenerated;
    const targetCount = Math.min(item.deficit, remaining, 50); // Cap at 50 per skill per run

    if (targetCount <= 0) continue;

    console.log(`Starting generation for skill: ${item.skill} (${item.examType} ${item.section}). Target: ${targetCount}`);
    // Generate for this skill
    const result = await generateForSkill(
      item.examType,
      item.section,
      item.skill,
      targetCount
    );

    results.push(result);
    totalGenerated += result.generated;
    totalWritten += result.written;
    skillsProcessed++;

    // Delay between skills to respect rate limits
    if (skillsProcessed < skillsToProcess.length) {
      await sleep(DAILY_CONFIG.delayBetweenSkills);
    }
  }

  console.log(`Daily generation complete: Generated ${totalGenerated}, Written ${totalWritten}`);

  return { totalGenerated, totalWritten, results };
}

/**
 * Generate questions for a specific exam/section/skill.
 * Used for manual triggers and testing.
 */
export async function generateForSpecificSkill(
  examType: string,
  section: string,
  skill: string,
  countOverride?: number
): Promise<GenerationResult> {
  // Validate inputs
  const validExamTypes = Object.keys(QUESTION_CONFIG);
  if (!validExamTypes.includes(examType)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid examType. Must be one of: ${validExamTypes.join(", ")}`
    );
  }

  const examConfig = QUESTION_CONFIG[examType as ExamType];
  const validSections = Object.keys(examConfig);
  if (!validSections.includes(section)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid section for ${examType}. Must be one of: ${validSections.join(", ")}`
    );
  }

  const skills = getSkillsForSection(examType as ExamType, section);
  if (!skills.includes(skill)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid skill for ${examType}/${section}. Must be one of: ${skills.join(", ")}`
    );
  }

  const targetCount = countOverride || 10;

  return generateForSkill(examType, section, skill, targetCount);
}

/**
 * Get generation statistics for monitoring.
 */
export async function getGenerationStats(): Promise<{
  totalQuestions: number;
  byExamType: Record<string, number>;
  bySection: Record<string, number>;
  lastGeneration: admin.firestore.Timestamp | null;
}> {
  const db = admin.firestore();

  // Get total count
  const totalSnapshot = await db.collection("questions").count().get();
  const totalQuestions = totalSnapshot.data().count;

  // Get counts by exam type
  const byExamType: Record<string, number> = {};
  for (const examType of ["SAT", "ACT"]) {
    const snapshot = await db.collection("questions")
      .where("examType", "==", examType)
      .count()
      .get();
    byExamType[examType] = snapshot.data().count;
  }

  // Get counts by section
  const bySection: Record<string, number> = {};
  const sections = ["Math", "Reading", "Writing", "English", "Science"];
  for (const section of sections) {
    const snapshot = await db.collection("questions")
      .where("section", "==", section)
      .count()
      .get();
    bySection[section] = snapshot.data().count;
  }

  // Get last generation timestamp
  const lastLogSnapshot = await db.collection("generationLogs")
    .orderBy("timestamp", "desc")
    .limit(1)
    .get();

  const lastGeneration = lastLogSnapshot.empty
    ? null
    : lastLogSnapshot.docs[0].data().timestamp;

  return { totalQuestions, byExamType, bySection, lastGeneration };
}
