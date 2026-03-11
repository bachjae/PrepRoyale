/**
 * Admin script: purge low-quality questions from Firestore.
 * Run from project root:  node purge-questions.js
 *
 * Deletes:
 *   1. All questions with difficulty == "easy"
 *   2. All passage-section questions (Reading/Writing/English/Science) with no/short passage
 */

const admin = require("firebase-admin");
const serviceAccount = require("./sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const BATCH_SIZE = 500;
const PASSAGE_SECTIONS = ["Reading", "Writing", "English", "Science"];
// Minimum passage length (chars). 600 ≈ 100 words — rejects empty/stub passages.
const MIN_PASSAGE_LENGTH = 100;

async function deleteDocs(docs, label) {
  let deleted = 0;
  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    docs.slice(i, i + BATCH_SIZE).forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += Math.min(BATCH_SIZE, docs.length - i);
    process.stdout.write(`\r  ${label}: ${deleted}/${docs.length} deleted...`);
  }
  if (docs.length > 0) console.log();
  return deleted;
}

async function main() {
  console.log("=== Purge Questions ===\n");

  // 1. Easy-difficulty questions
  console.log('Fetching easy-difficulty questions...');
  const easySnap = await db.collection("questions").where("difficulty", "==", "easy").get();
  console.log(`  Found ${easySnap.size} easy questions`);
  const deletedEasy = await deleteDocs(easySnap.docs, "Easy");

  // 2. Passage-section questions without adequate passages
  let deletedNoPassage = 0;
  for (const section of PASSAGE_SECTIONS) {
    console.log(`Fetching ${section} questions without passage...`);
    const snap = await db.collection("questions").where("section", "==", section).get();
    const toDelete = snap.docs.filter((doc) => {
      const p = doc.data().passage;
      return !p || typeof p !== "string" || p.trim().length < MIN_PASSAGE_LENGTH;
    });
    console.log(`  Found ${toDelete.length} / ${snap.size} ${section} questions missing passage`);
    deletedNoPassage += await deleteDocs(toDelete, section);
  }

  const total = deletedEasy + deletedNoPassage;
  console.log(`\n✓ Done. Deleted ${deletedEasy} easy + ${deletedNoPassage} no-passage = ${total} total questions.`);
  process.exit(0);
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
