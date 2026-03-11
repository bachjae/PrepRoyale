/**
 * Admin script: purge medium + legacy-numeric questions, then trigger one
 * full generation cycle via the deployed manualDailyGeneration Cloud Function.
 *
 * Run from project root:  node purge-and-generate.js
 *
 * Steps:
 *  1. Delete all "medium" difficulty questions
 *  2. Delete questions stored with numeric difficulty (1-5, legacy format)
 *  3. Mint a Firebase custom auth token → exchange for ID token
 *  4. POST to manualDailyGeneration callable (runs server-side with CF
 *     service account, so Vertex AI works correctly)
 */

const admin = require("firebase-admin");
const serviceAccount = require("./sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();
const BATCH_SIZE = 500;
const FIREBASE_API_KEY = "AIzaSyDflI82-vGURsAY_D9ILccZ-mSGrOy15Cg";
const CF_BASE = "https://us-central1-sat-act-battle-royale.cloudfunctions.net";

// ─── helpers ────────────────────────────────────────────────────────────────

async function batchDelete(docs, label) {
  let deleted = 0;
  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    docs.slice(i, i + BATCH_SIZE).forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted += Math.min(BATCH_SIZE, docs.length - i);
    process.stdout.write(`\r  ${label}: ${deleted}/${docs.length} deleted...`);
  }
  if (docs.length > 0) console.log();
  return deleted;
}

// ─── Step 1 & 2: purge ──────────────────────────────────────────────────────

async function purge() {
  console.log("=== Step 1: Purge medium difficulty questions ===");
  const medSnap = await db
    .collection("questions")
    .where("difficulty", "==", "medium")
    .get();
  console.log(`  Found ${medSnap.size} medium questions`);
  const deletedMedium = await batchDelete(medSnap.docs, "Medium");

  console.log("\n=== Step 2: Purge legacy numeric-difficulty questions ===");
  let deletedNumeric = 0;
  for (const val of [1, 2, 3, 4, 5]) {
    const snap = await db
      .collection("questions")
      .where("difficulty", "==", val)
      .get();
    if (snap.size > 0) {
      console.log(`  Found ${snap.size} questions with difficulty=${val}`);
      deletedNumeric += await batchDelete(snap.docs, `difficulty=${val}`);
    }
  }
  if (deletedNumeric === 0) console.log("  None found.");

  console.log(
    `\n✓ Purge complete: ${deletedMedium} medium + ${deletedNumeric} numeric = ${
      deletedMedium + deletedNumeric
    } deleted.\n`
  );
}

// ─── Step 3: get ID token ────────────────────────────────────────────────────

async function getIdToken() {
  // Mint a custom token (any UID is fine — CF only checks that auth exists)
  const customToken = await admin
    .auth()
    .createCustomToken("purge-script-admin");

  // Exchange custom token for a Firebase ID token via REST API
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${FIREBASE_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    }
  );
  const json = await res.json();
  if (!json.idToken) {
    throw new Error(
      `Failed to get ID token: ${JSON.stringify(json)}`
    );
  }
  return json.idToken;
}

// ─── Step 4: trigger generation ─────────────────────────────────────────────

async function triggerGeneration(idToken) {
  console.log("=== Step 3: Calling manualDailyGeneration (server-side) ===");
  console.log(
    "  This runs Gemini on Cloud Functions — may take several minutes...\n"
  );

  const res = await fetch(`${CF_BASE}/manualDailyGeneration`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ data: {} }),
  });

  const body = await res.json();

  if (res.status !== 200) {
    const err = body.error || body;
    throw new Error(
      `manualDailyGeneration failed (${res.status}): ${JSON.stringify(err)}`
    );
  }

  const result = body.result || body;
  console.log("✓ Generation complete!");
  console.log(
    `  Skills processed : ${result.skillsProcessed ?? "?"}`
  );
  console.log(
    `  Questions generated : ${result.totalGenerated ?? "?"}`
  );
  console.log(
    `  Questions written   : ${result.totalWritten ?? "?"}`
  );
}

// ─── main ────────────────────────────────────────────────────────────────────

async function main() {
  try {
    await purge();

    console.log("=== Step 2: Obtaining auth token ===");
    const idToken = await getIdToken();
    console.log("  Token obtained.\n");

    await triggerGeneration(idToken);

    console.log(
      "\n✓ All done. The nightly scheduler (3 AM UTC) will continue filling remaining deficits."
    );
    process.exit(0);
  } catch (err) {
    console.error("\nFatal error:", err.message || err);
    process.exit(1);
  }
}

main();
