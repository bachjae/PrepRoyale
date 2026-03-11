/**
 * Gemini API helper using Firebase Vertex AI.
 * Uses project credentials automatically - no API key needed!
 */

import { VertexAI, GenerativeModel } from "@google-cloud/vertexai";
import { Difficulty, DIFFICULTY_DISTRIBUTION } from "../config/questionConfig";

// Rate limiting configuration (Vertex AI has higher limits)
const RATE_LIMIT = {
  requestsPerMinute: 60,
  retryDelayMs: 2000,
  maxRetries: 3
};

// Track request counts for rate limiting
let requestsThisMinute = 0;
let lastMinuteReset = Date.now();

// Question interface for generated questions
export interface GeneratedQuestion {
  examType: string;
  section: string;
  skill: string;
  difficulty: Difficulty;
  questionText: string;
  passage?: string; // Optional passage for Reading/Writing/Science questions
  choices: string[];
  correctChoiceIndex: number;  // always 0-3 after normalisation
  correctChoiceLetter?: string; // A/B/C/D — may be present from AI; removed before writing to Firestore
  explanation: string;
}

// Sections that require passage-based questions
const PASSAGE_SECTIONS = new Set([
  "Reading",  // SAT Reading, ACT Reading
  "Writing",  // SAT Writing
  "English",  // ACT English
  "Science",  // ACT Science
]);

// Vertex AI client singleton
let vertexAI: VertexAI | null = null;
let generativeModel: GenerativeModel | null = null;

/**
 * Initialize Vertex AI client using Firebase project credentials.
 * No API key needed - uses the project's service account automatically!
 */
function getGeminiModel(): GenerativeModel {
  if (generativeModel) {
    return generativeModel;
  }

  // Get project ID from environment (automatically set by Firebase)
  let projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;

  // For local development with emulator, we might need a fallback
  if (!projectId || projectId === "undefined") {
    projectId = "sat-act-battle-royale"; // Fallback to the project ID in firebase.json
    console.warn(`Project ID not found in environment. Using fallback: ${projectId}`);
  }

  if (!projectId) {
    throw new Error(
      "Could not determine project ID. Make sure you're running in Firebase environment or set GCLOUD_PROJECT."
    );
  }

  // Initialize Vertex AI with project credentials
  vertexAI = new VertexAI({
    project: projectId,
    location: "us-central1", // You can change this to your preferred region
  });

  // Use Gemini 2.0 Flash for fast, cost-effective generation
  generativeModel = vertexAI.getGenerativeModel({
    model: "gemini-2.0-flash",
    generationConfig: {
      maxOutputTokens: 8192,
      temperature: 0.7,
    },
  });

  return generativeModel;
}

// Check and update rate limits
function checkRateLimits(): { canProceed: boolean; waitMs: number } {
  const now = Date.now();

  // Reset minute counter if a minute has passed
  if (now - lastMinuteReset >= 60000) {
    requestsThisMinute = 0;
    lastMinuteReset = now;
  }

  if (requestsThisMinute >= RATE_LIMIT.requestsPerMinute) {
    const waitMs = 60000 - (now - lastMinuteReset) + 1000;
    return { canProceed: false, waitMs };
  }

  return { canProceed: true, waitMs: 0 };
}

// Sleep helper
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Sections that may need visual elements (graphs, charts, diagrams)
const VISUAL_SECTIONS = new Set(["Math", "Science"]);

// Skills that need visual-element guards even when inside a passage section
const VISUAL_SKILLS = new Set(["GraphAndTableInterpretation"]);

// Build the prompt for question generation
function buildPrompt(
  examType: string,
  section: string,
  skill: string,
  count: number,
  difficultyDistribution: Record<Difficulty, number> = DIFFICULTY_DISTRIBUTION
): string {
  const easyCount = Math.round(count * difficultyDistribution.easy);
  const mediumCount = Math.round(count * difficultyDistribution.medium);
  const hardCount = count - easyCount - mediumCount;

  // Check if this section requires passage-based questions
  const requiresPassage = PASSAGE_SECTIONS.has(section);

  // Check if this section/skill may need visual elements
  // Fix 8: GraphAndTableInterpretation is in Reading but requires visual guards
  const mayNeedVisuals = VISUAL_SECTIONS.has(section) || VISUAL_SKILLS.has(skill);

  // Fix 9: Science passages must never use numbered figure/table labels
  const scienceExtraGuard = section === "Science" ? `
- NEVER use numbered figure or table labels such as "Figure 1", "Table 2", "Graph A", etc.
- Refer to embedded data as "the table above", "the data above", or "the passage" — because the data IS part of the passage text
` : "";

  // Build visual element instructions for Math/Science/GraphAndTableInterpretation
  const visualInstructions = mayNeedVisuals ? `
VISUAL ELEMENTS (CRITICAL):
- If a question involves a graph, chart, table, or diagram, you MUST include it as a text-based representation — never reference external figures
- For graphs: Describe using exact coordinates/data points. Example:
  "The graph shows a line passing through points (0, 2) and (4, 10), representing the equation y = 2x + 2"
- For tables: Use pipe-formatted tables with a header separator row. Example:
  "| Time (s) | Distance (m) |
   | -------- | ------------ |
   |    0     |      0       |
   |    2     |     10       |
   |    4     |     25       |"
- For charts: Describe the data in full detail. Example:
  "Bar chart data: Category A = 45, Category B = 32, Category C = 58, Category D = 21"
- For geometry diagrams: Provide a complete textual description with all measurements, angles, and labels
- NEVER reference "the figure below", "see the graph", "as shown in the diagram", or any similar phrase without embedding the full data inline
- NEVER use numbered figure or table labels ("Figure 1", "Table 2", "Graph A") — there is no rendering for these labels in the app
- All visual information MUST be self-contained in the question text or passage${scienceExtraGuard}
` : "";

  // Writing/English underline support: the app renders __text__ as underlined text.
  // Use this markup so questions can reference underlined portions naturally.
  const writingEnglishGuard = (section === "Writing" || section === "English") ? `
UNDERLINE MARKUP (CRITICAL — read carefully):
- The app renders __text__ (double underscores) as visually underlined text. Use this markup whenever a question refers to an underlined portion of a passage.
- In the passage, wrap the targeted word, phrase, or sentence with double underscores: __like this__
- In the questionText, refer to it naturally: "Which choice best replaces the underlined word?" or "The underlined sentence would be most improved by..."
- CORRECT pattern:
    passage: "…The experiment yielded __unexpected results__, challenging prior assumptions…"
    questionText: "Which choice best replaces the underlined phrase?"
- NEVER use the word "underlined" in questionText or choices WITHOUT having the corresponding __markup__ in the passage.
- Do NOT underline entire sentences unless the question specifically requires a full-sentence revision.
` : "";

  // Build passage-specific instructions
  const passageInstructions = requiresPassage ? `
PASSAGE REQUIREMENTS (CRITICAL):
- Each question MUST include a "passage" field containing an original passage of text
- Passage length requirements: Reading = 300-500 words, Writing/English = 150-250 words, Science = 200-350 words
- For Reading: Write sophisticated, literary-quality passages drawn from genres such as historical primary sources, literary fiction, social science research, or advanced scientific commentary. Use complex sentence structures, varied vocabulary, and layered arguments that demand careful reading. Inference and author-purpose questions must require genuine textual analysis — not surface-level reading.
- For Reading / GraphAndTableInterpretation: The passage MUST include a pipe-formatted data table or explicitly described graph data embedded in the passage text. The question must refer to this inline data — never to an external figure.
- For Writing/English: Write passages that contain targeted grammar, punctuation, style, or rhetoric problems embedded naturally in otherwise coherent prose. The error must be identifiable only through careful analysis. Avoid trivially obvious mistakes.
- For Science: Write passages that fully present an experiment or research scenario, including a complete data table formatted in plain text (pipe format), hypotheses, methods, and results. Questions must require interpretation of the data or reconciliation of conflicting viewpoints — not just recall of stated facts.
- The question must directly require understanding or analysis of the passage — not general knowledge
- Do NOT create standalone questions — every question must be passage-based
${writingEnglishGuard}` : writingEnglishGuard;

  // Build the JSON schema example with or without passage field
  const jsonSchema = requiresPassage ? `{
  "examType": "${examType}",
  "section": "${section}",
  "skill": "${skill}",
  "difficulty": "easy" | "medium" | "hard",
  "passage": "Full passage text (300-500 words for Reading, 150-250 for Writing/English, 200-350 for Science — include complete data tables for Science)",
  "questionText": "The question about the passage",
  "choices": ["first choice", "second choice", "third choice", "fourth choice"],
  "correctChoiceLetter": "A" | "B" | "C" | "D",
  "explanation": "[Correct choice text] is correct because [reason]. [Wrong choice text 1] is incorrect because [reason]. [Wrong choice text 2] is incorrect because [reason]. [Wrong choice text 3] is incorrect because [reason]."
}` : `{
  "examType": "${examType}",
  "section": "${section}",
  "skill": "${skill}",
  "difficulty": "easy" | "medium" | "hard",
  "questionText": "The full question text",
  "choices": ["first choice", "second choice", "third choice", "fourth choice"],
  "correctChoiceLetter": "A" | "B" | "C" | "D",
  "explanation": "[Correct choice text] is correct because [reason]. [Wrong choice text 1] is incorrect because [reason]. [Wrong choice text 2] is incorrect because [reason]. [Wrong choice text 3] is incorrect because [reason]."
}`;

  // Build difficulty distribution lines (skip difficulty if count is 0)
  const distributionLines: string[] = [];
  if (easyCount > 0) distributionLines.push(`- ${easyCount} questions at "easy" difficulty`);
  if (mediumCount > 0) distributionLines.push(`- ${mediumCount} questions at "medium" difficulty`);
  if (hardCount > 0) distributionLines.push(`- ${hardCount} questions at "hard" difficulty`);

  return `You are an expert test-prep content writer creating challenging, original practice questions for an SAT/ACT prep app called Prep Royale.

Generate exactly ${count} unique ${section} questions that test the skill: "${skill}".

DIFFICULTY STANDARD — CRITICAL:
All questions must match the rigor of real SAT and ACT college entrance exams. This means:
- Questions must demand genuine reasoning, not just recall or basic application
- Wrong answer choices must be carefully crafted to be plausible — reflecting real student misconceptions, common calculation errors, or partially correct logic
- Medium questions: require multi-step reasoning, nuanced reading comprehension, or application of a concept in an unfamiliar context
- Hard questions: require integration of multiple concepts, advanced inference from subtle textual or quantitative evidence, or careful elimination of highly convincing distractors — matching the difficulty of the hardest questions on a real SAT/ACT
${visualInstructions}${passageInstructions}
Distribution:
${distributionLines.join("\n")}

Requirements for each question:
1. Match the exact format, question phrasing style, and answer-choice structure used in real ${section} sections of the SAT and ACT
2. Use entirely original, invented content — your own passages, scenarios, data sets, and wording (do NOT reproduce or closely paraphrase any real exam content)
3. Include exactly 4 answer choices. The choices array is 0-indexed: choices[0] = A, choices[1] = B, choices[2] = C, choices[3] = D
4. Have exactly one correct answer
5. Set correctChoiceLetter to the letter (A, B, C, or D) of the correct answer
6. Distractors must be sophisticated — targeting real misconceptions, incomplete reasoning, or common errors specific to "${skill}"
7. EXPLANATION FORMAT (CRITICAL — read carefully):
   - NEVER mention letters (A, B, C, D) anywhere in the explanation. Only refer to the actual text/value of each choice.
   - Start by stating the correct choice's exact text and why it is correct: "[exact correct choice text] is correct because [reason]."
   - Then for each WRONG choice: "[exact wrong choice text] is incorrect because [reason]."
   - This way the explanation is always accurate even if choices appear in a different order.
   - NEVER say any choice "is correct" unless it IS the correct answer.
   - Do NOT include internal monologue, trial-and-error, or phrases like "Let's try", "Something is wrong", or "Oh".
   - Example for a math question where choices are ["10", "20", "30", "40"] and "30" is correct:
     "30 is correct because [calculation]. 10 is incorrect because [reason]. 20 is incorrect because [reason]. 40 is incorrect because [reason]."
   - Example for a grammar question where choices are ["run quickly", "runs quickly", "ran quickly", "running quickly"] and "runs quickly" is correct:
     "runs quickly is correct because the subject is singular third-person, requiring the -s ending. run quickly is incorrect because it lacks subject-verb agreement. ran quickly is incorrect because the past tense does not match the present context. running quickly is incorrect because it creates a sentence fragment."

CRITICAL: Respond ONLY with a valid JSON array. No markdown, no code blocks, no explanation text.

Each element must have exactly these fields:
${jsonSchema}

Generate the JSON array now:`;
}

// Parse and validate JSON response from Gemini
function parseGeminiResponse(responseText: string): GeneratedQuestion[] {
  let jsonText = responseText.trim();

  // Remove markdown code blocks if present
  if (jsonText.startsWith("```json")) {
    jsonText = jsonText.slice(7);
  } else if (jsonText.startsWith("```")) {
    jsonText = jsonText.slice(3);
  }
  if (jsonText.endsWith("```")) {
    jsonText = jsonText.slice(0, -3);
  }
  jsonText = jsonText.trim();

  // Try to find JSON array in response
  const arrayMatch = jsonText.match(/\[[\s\S]*\]/);
  if (arrayMatch) {
    jsonText = arrayMatch[0];
  }

  try {
    const parsed = JSON.parse(jsonText);

    if (!Array.isArray(parsed)) {
      throw new Error("Response is not an array");
    }

    return parsed;
  } catch (error) {
    console.error("Failed to parse Gemini response:", error);
    console.error("Raw response:", responseText.substring(0, 500));
    throw new Error(`JSON parse error: ${error}`);
  }
}

// Regex patterns to extract the stated answer letter from explanation text
// Validate a single question object
export function validateQuestion(q: unknown): q is GeneratedQuestion {
  if (!q || typeof q !== "object") return false;

  const question = q as Record<string, unknown>;

  // Accept either correctChoiceLetter (new prompt) or correctChoiceIndex (legacy)
  const hasLetter = "correctChoiceLetter" in question;
  const hasIndex  = "correctChoiceIndex"  in question;

  const baseRequired = [
    "examType", "section", "skill", "difficulty",
    "questionText", "choices", "explanation"
  ];

  for (const field of baseRequired) {
    if (!(field in question)) {
      console.warn(`Missing field: ${field}`);
      return false;
    }
  }
  if (!hasLetter && !hasIndex) {
    console.warn("Missing both correctChoiceLetter and correctChoiceIndex");
    return false;
  }

  if (typeof question.examType !== "string") return false;
  if (typeof question.section !== "string") return false;
  if (typeof question.skill !== "string") return false;
  if (!["easy", "medium", "hard"].includes(question.difficulty as string)) return false;
  if (typeof question.questionText !== "string" || question.questionText.length < 10) return false;
  if (!Array.isArray(question.choices) || question.choices.length !== 4) return false;
  if (typeof question.explanation !== "string" || question.explanation.length < 5) return false;

  for (const choice of question.choices as unknown[]) {
    if (typeof choice !== "string" || (choice as string).length === 0) return false;
  }

  // ── Resolve correctChoiceIndex ────────────────────────────────────────────
  let resolvedIndex: number;

  if (hasLetter) {
    const letter = (question.correctChoiceLetter as string).trim().toUpperCase();
    if (!["A", "B", "C", "D"].includes(letter)) {
      console.warn(`Invalid correctChoiceLetter: ${letter}`);
      return false;
    }
    resolvedIndex = letter.charCodeAt(0) - 65; // A=0, B=1, C=2, D=3
  } else {
    resolvedIndex = question.correctChoiceIndex as number;
    if (typeof resolvedIndex !== "number" || resolvedIndex < 0 || resolvedIndex > 3) {
      console.warn(`Invalid correctChoiceIndex: ${resolvedIndex}`);
      return false;
    }
  }

  // Require a substantive explanation (new format: value-based, no letters)
  if ((question.explanation as string).length < 30) {
    console.warn(`Explanation too short. Rejecting question.`);
    return false;
  }

  // ── Normalise to correctChoiceIndex ───────────────────────────────────────
  question.correctChoiceIndex = resolvedIndex;
  delete question.correctChoiceLetter; // clean up before writing to Firestore

  // ── Passage validation ────────────────────────────────────────────────────
  const section = question.section as string;
  if (PASSAGE_SECTIONS.has(section)) {
    if (!question.passage || typeof question.passage !== "string" || question.passage.length < 600) {
      console.warn(`Passage required for ${section} section but missing or too short (${(question.passage as string | undefined)?.length ?? 0} chars)`);
      return false;
    }
  }

  if (question.passage !== undefined && typeof question.passage !== "string") {
    return false;
  }

  return true;
}

/**
 * Generate questions using Vertex AI Gemini with rate limiting and retry logic.
 */
export async function generateQuestionsWithGemini(
  examType: string,
  section: string,
  skill: string,
  count: number = 10
): Promise<GeneratedQuestion[]> {
  const model = getGeminiModel();
  const prompt = buildPrompt(examType, section, skill, count);

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < RATE_LIMIT.maxRetries; attempt++) {
    const rateCheck = checkRateLimits();

    if (!rateCheck.canProceed) {
      console.log(`Rate limited. Waiting ${rateCheck.waitMs}ms before retry...`);
      await sleep(rateCheck.waitMs);
      continue;
    }

    try {
      console.log(`Generating ${count} questions for ${examType}/${section}/${skill} (attempt ${attempt + 1})`);

      requestsThisMinute++;

      // Make the API call using Vertex AI
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
      });

      console.log("Gemini API call successful. Parsing response...");

      const response = result.response;
      const text = response.candidates?.[0]?.content?.parts?.[0]?.text;

      if (!text) {
        throw new Error("Empty response from Gemini");
      }

      const questions = parseGeminiResponse(text);
      const validQuestions = questions.filter(validateQuestion);

      if (validQuestions.length === 0) {
        throw new Error("No valid questions in response");
      }

      console.log(`Successfully generated ${validQuestions.length}/${questions.length} valid questions`);
      return validQuestions;

    } catch (error) {
      lastError = error as Error;
      const errorMessage = lastError.message || String(error);

      if (errorMessage.includes("429") || errorMessage.includes("rate limit") ||
          errorMessage.includes("RESOURCE_EXHAUSTED")) {
        console.warn(`Rate limit hit on attempt ${attempt + 1}. Backing off...`);
        await sleep(RATE_LIMIT.retryDelayMs * (attempt + 1));
        continue;
      }

      console.error(`Attempt ${attempt + 1} failed:`, errorMessage);
      if (attempt < RATE_LIMIT.maxRetries - 1) {
        await sleep(RATE_LIMIT.retryDelayMs * (attempt + 1));
      }
    }
  }

  throw lastError || new Error("Failed to generate questions after max retries");
}

/**
 * Generate questions in batches to handle large counts.
 */
export async function generateQuestionsBatch(
  examType: string,
  section: string,
  skill: string,
  totalCount: number,
  batchSize: number = 10
): Promise<GeneratedQuestion[]> {
  const allQuestions: GeneratedQuestion[] = [];
  const batches = Math.ceil(totalCount / batchSize);

  console.log(`Generating ${totalCount} questions in ${batches} batches for ${examType}/${section}/${skill}`);

  for (let i = 0; i < batches; i++) {
    const remaining = totalCount - allQuestions.length;
    const count = Math.min(batchSize, remaining);

    if (count <= 0) break;

    try {
      const questions = await generateQuestionsWithGemini(examType, section, skill, count);
      allQuestions.push(...questions);

      console.log(`Batch ${i + 1}/${batches}: Generated ${questions.length} questions (total: ${allQuestions.length})`);

      if (i < batches - 1) {
        await sleep(2000); // 2 second delay between batches
      }

    } catch (error) {
      console.error(`Batch ${i + 1} failed:`, error);
      if ((error as Error).message?.includes("quota") ||
          (error as Error).message?.includes("RESOURCE_EXHAUSTED")) {
        break;
      }
    }
  }

  return allQuestions;
}
