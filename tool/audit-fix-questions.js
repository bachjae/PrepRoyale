/**
 * Audits all Firestore questions for structural validity.
 *
 * Strategy (value-based explanation format — no letter cross-check):
 *  1. Validate correctChoiceIndex is 0–3
 *  2. Validate choices is an array of exactly 4 non-empty strings
 *  3. Validate explanation is non-empty (>= 30 chars)
 *  4. Delete anything that fails structural validation
 *
 * Run: node tool/audit-fix-questions.js
 */

const admin = require("firebase-admin");
const serviceAccount = require("../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log("Fetching all questions from Firestore ...\n");

  const snapshot = await db.collection("questions").get();
  console.log(`Total questions: ${snapshot.size}\n`);

  const deletes = [];  // { id, reason }
  const ok      = [];  // ids

  for (const doc of snapshot.docs) {
    const q  = doc.data();
    const id = doc.id;

    // 1. Valid correctChoiceIndex
    if (typeof q.correctChoiceIndex !== "number" || q.correctChoiceIndex < 0 || q.correctChoiceIndex > 3) {
      deletes.push({ id, reason: `Invalid correctChoiceIndex: ${q.correctChoiceIndex}` });
      continue;
    }

    // 2. Exactly 4 non-empty choices
    if (!Array.isArray(q.choices) || q.choices.length !== 4 ||
        q.choices.some(c => typeof c !== "string" || c.trim().length === 0)) {
      deletes.push({ id, reason: `Invalid choices array (length=${q.choices?.length})` });
      continue;
    }

    // 3. Substantive explanation
    if (typeof q.explanation !== "string" || q.explanation.trim().length < 30) {
      deletes.push({ id, reason: `Explanation too short or missing` });
      continue;
    }

    ok.push(id);
  }

  console.log(`✅  OK:         ${ok.length}`);
  console.log(`🗑️   To delete:  ${deletes.length}\n`);

  if (deletes.length > 0) {
    console.log("--- DELETES ---");
    for (const d of deletes) {
      console.log(`  [${d.id}] ${d.reason}`);
    }
    console.log();

    console.log(`Deleting ${deletes.length} invalid questions ...`);
    const BATCH_SIZE = 500;
    for (let i = 0; i < deletes.length; i += BATCH_SIZE) {
      const batch = db.batch();
      for (const d of deletes.slice(i, i + BATCH_SIZE)) {
        batch.delete(db.collection("questions").doc(d.id));
      }
      await batch.commit();
    }
    console.log("✅  Deletes applied.\n");
  }

  console.log("Done.");
  process.exit(0);
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
