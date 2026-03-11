/**
 * Trigger the full daily question generation pipeline right now.
 * Uses the same Gemini logic as the scheduled Cloud Function.
 * Automatically detects which skills have a question deficit and fills them.
 *
 * Run from the functions/ directory:
 *   node generate-now.js
 */

process.env.GOOGLE_APPLICATION_CREDENTIALS =
  "../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json";
process.env.GCLOUD_PROJECT = "sat-act-battle-royale";

// Initialize admin BEFORE requiring any module that uses it
const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "sat-act-battle-royale",
});

// Now safe to load compiled generation code
const { runDailyGeneration } = require("./lib/batch/dailyGenerator");

async function main() {
  console.log("=== Gemini Question Generation ===");
  console.log("Scanning Firestore for skill deficits and generating new questions...");
  console.log("This may take 10-30 minutes for a full run.\n");

  const start = Date.now();

  try {
    const result = await runDailyGeneration();

    const elapsed = ((Date.now() - start) / 1000 / 60).toFixed(1);
    console.log("\n=== Done ===");
    console.log(`Time elapsed: ${elapsed} minutes`);
    console.log(`Generated: ${result.totalGenerated}`);
    console.log(`Written to Firestore: ${result.totalWritten}`);

    if (result.results?.length) {
      const successful = result.results.filter((r) => r.written > 0);
      const failed = result.results.filter((r) => r.error);
      console.log(`\nSuccessful skills: ${successful.length}`);
      if (failed.length) {
        console.log(`Failed skills: ${failed.length}`);
        failed.forEach((r) =>
          console.log(`  ✗ ${r.examType}/${r.section}/${r.skill}: ${r.error}`)
        );
      }
      console.log("\nTop results:");
      successful
        .sort((a, b) => b.written - a.written)
        .slice(0, 10)
        .forEach((r) =>
          console.log(`  ✓ ${r.examType}/${r.section}/${r.skill}: +${r.written}`)
        );
    }
  } catch (err) {
    console.error("\nFatal error:", err.message || err);
    process.exit(1);
  }

  process.exit(0);
}

main();
