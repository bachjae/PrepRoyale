/**
 * Deletes all questions whose explanation uses the OLD letter-based format
 * (starts with "The correct answer is [A-D]").
 * Run BEFORE regenerating with the new value-based explanation format.
 *
 * Run: node tool/purge-old-format-questions.js
 */

const admin = require("firebase-admin");
const serviceAccount = require("../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const OLD_FORMAT = /^the\s+correct\s+answer\s+is\s+[A-D]\b/i;

async function main() {
  console.log("Fetching all questions ...\n");
  const snapshot = await db.collection("questions").get();
  console.log(`Total: ${snapshot.size}`);

  const toDelete = snapshot.docs.filter(doc => OLD_FORMAT.test(doc.data().explanation || ""));
  const toKeep   = snapshot.size - toDelete.length;

  console.log(`Old-format (letter-based): ${toDelete.length}  → will DELETE`);
  console.log(`New-format (value-based):  ${toKeep}          → will KEEP\n`);

  if (toDelete.length === 0) {
    console.log("Nothing to delete.");
    process.exit(0);
  }

  const BATCH_SIZE = 500;
  let deleted = 0;
  for (let i = 0; i < toDelete.length; i += BATCH_SIZE) {
    const batch = db.batch();
    for (const doc of toDelete.slice(i, i + BATCH_SIZE)) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += Math.min(BATCH_SIZE, toDelete.length - i);
    process.stdout.write(`\r  Deleted ${deleted}/${toDelete.length} ...`);
  }

  console.log(`\n\n✅ Done. Deleted ${deleted} old-format questions. ${toKeep} value-based questions remain.`);
  process.exit(0);
}

main().catch(err => { console.error("Error:", err.message); process.exit(1); });
