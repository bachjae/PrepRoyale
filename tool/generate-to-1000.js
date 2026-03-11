/**
 * Calls the deployed seedTestQuestions Cloud Function to bulk-generate questions.
 * Runs batches sequentially until total Firestore count reaches 1000.
 *
 * Run: node tool/generate-to-1000.js
 */
const https = require("https");
const admin = require("firebase-admin");
const serviceAccount = require("../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const ADMIN_SECRET = "039c637a9717df231fe23e5b9527b21e7aefc8da81f16f495093b6430458cfd5";
const BASE_URL = "seedtestquestions-hwn67xeepa-uc.a.run.app";
const TARGET = 1000;

// Safe batch size — 4 sections × 50 = 200 questions per call; fits in ~300s
const QUESTIONS_PER_SECTION = 50;

async function getCount() {
  const snap = await db.collection("questions").count().get();
  return snap.data().count;
}

function callSeedEndpoint(examType, perSection) {
  return new Promise((resolve, reject) => {
    const path = `/?examType=${examType}&questionsPerSection=${perSection}`;
    console.log(`  → POST ${path}`);

    const options = {
      hostname: BASE_URL,
      path,
      method: "POST",
      headers: { "x-admin-secret": ADMIN_SECRET, "Content-Type": "application/json" },
      timeout: 600_000,
    };

    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", (c) => (body += c));
      res.on("end", () => {
        if (res.statusCode === 200) {
          try { resolve(JSON.parse(body)); } catch { resolve({ raw: body.substring(0, 200) }); }
        } else if (res.statusCode === 504) {
          // Function timed out on Cloud Run side but likely wrote some questions
          resolve({ timedOut: true, statusCode: 504 });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body.substring(0, 300)}`));
        }
      });
    });

    req.on("error", reject);
    req.on("timeout", () => { req.destroy(); resolve({ timedOut: true, localTimeout: true }); });
    req.end();
  });
}

// Wait for the Cloud Function to settle after a 504
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
  let current = await getCount();
  console.log(`Starting count: ${current}  Target: ${TARGET}`);

  let round = 0;

  while (current < TARGET) {
    round++;
    const needed = TARGET - current;
    console.log(`\n--- Round ${round}: need ${needed} more questions ---`);

    // Prioritise ACT sections that are most depleted, then SAT
    const batches = [
      { examType: "ACT", perSection: Math.min(QUESTIONS_PER_SECTION, Math.ceil(needed / 2)) },
      { examType: "SAT", perSection: Math.min(QUESTIONS_PER_SECTION, Math.ceil(needed / 4)) },
    ];

    for (const { examType, perSection } of batches) {
      if (perSection < 1) continue;
      current = await getCount();
      if (current >= TARGET) break;

      const start = Date.now();
      console.log(`[${examType}] Generating ${perSection}/section...`);

      try {
        const result = await callSeedEndpoint(examType, perSection);
        const elapsed = ((Date.now() - start) / 1000).toFixed(1);

        if (result.timedOut) {
          console.log(`  ⚠  Cloud Function timed out (${elapsed}s) — waiting 60s for it to settle...`);
          await sleep(60_000);
        } else if (result.totals) {
          console.log(`  ✅ ${elapsed}s — generated=${result.totals.generated}, written=${result.totals.written}`);
        } else {
          console.log(`  Response (${elapsed}s):`, JSON.stringify(result).substring(0, 200));
        }
      } catch (err) {
        console.error(`  ❌ ${err.message}`);
      }

      // Brief pause before next call
      await sleep(5_000);
    }

    const newCount = await getCount();
    console.log(`Count after round ${round}: ${newCount} (added ${newCount - current})`);
    current = newCount;

    if (round > 10) {
      console.log("Safety stop: 10 rounds reached.");
      break;
    }
  }

  const final = await getCount();
  console.log(`\n✅ Done. Final question count: ${final}`);
  process.exit(0);
}

main().catch((err) => { console.error("Fatal:", err.message); process.exit(1); });
