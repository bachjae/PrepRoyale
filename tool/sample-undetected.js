/**
 * Samples explanations from questions where no letter was detected.
 * Helps tune the regex patterns before deleting 842 questions.
 */
const admin = require("firebase-admin");
const serviceAccount = require("../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const PATTERNS = [
  /(?:the\s+)?correct\s+answer\s+is\s+([A-D])\b/i,
  /\banswer[:\s]+([A-D])\b/i,
  /\b(?:option|choice)\s+([A-D])\b/i,
  /^([A-D])[.)]\s/,
  /\b([A-D])\s+is\s+(?:the\s+)?correct/i,
  /\(([A-D])\)/,
];

function extractAnswerLetter(explanation) {
  for (const pattern of PATTERNS) {
    const m = pattern.exec(explanation);
    if (m) return m[1].toUpperCase();
  }
  return null;
}

async function main() {
  const snapshot = await db.collection("questions").limit(2000).get();

  const undetected = [];
  for (const doc of snapshot.docs) {
    const q = doc.data();
    const letter = extractAnswerLetter(q.explanation || "");
    if (!letter) {
      undetected.push({ id: doc.id, explanation: q.explanation || "(empty)", section: q.section });
    }
  }

  console.log(`Undetected: ${undetected.length}`);
  console.log("\n=== Sample explanations (first 15) ===\n");

  for (const q of undetected.slice(0, 15)) {
    console.log(`[${q.id}] ${q.section}`);
    console.log(`  ${q.explanation.substring(0, 200)}`);
    console.log();
  }
  process.exit(0);
}

main().catch(err => { console.error(err.message); process.exit(1); });
