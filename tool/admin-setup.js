/**
 * One-time admin setup script.
 * - Sets admin custom claim on bachjae08@gmail.com
 * - Purges 18 known broken Math questions from Firestore
 */
const admin = require("firebase-admin");
const serviceAccount = require("../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const BROKEN_IDS = [
  "5nHTgU2Id0HQ9WFtPbcy", "6ldZMgmyIheGcYBz8A9l", "7i2DGyQFOpUjqxMGHygc",
  "FDCtUKKtKr7TAN49GU2j", "FFdFnP5SOamGBL8JQVcU", "MOCVdUVRnY2VbJyIyZDC",
  "MPhOoEHiGJmxbCuSXaVe", "ORUDqkfSbK0TFWhT6oix", "OmnpUslGkYGIq1zauPkc",
  "QS5GSjgdh1famCnF8MIC", "T7W05jCS99NW7ZqSOQJR", "VxDUmaAHu1FfB79wKyxu",
  "ZwQXSIOhdIYyhEUveF1R", "b7doMhqy1h5509yReAe6", "gUZTqhB3a5aGTcxJvOUn",
  "hHfpC3XRojjqUhGePKb7", "ntSkPgXiyPwlJhJOZcjg", "omqCIbjKChTuRRt80uj5",
];

async function main() {
  // 1. Set admin claim
  console.log("Looking up bachjae08@gmail.com ...");
  const user = await admin.auth().getUserByEmail("bachjae08@gmail.com");
  console.log("UID:", user.uid);
  await admin.auth().setCustomUserClaims(user.uid, { admin: true });
  console.log("✅ Admin claim set on", user.email);

  // 2. Purge broken questions
  console.log("\nPurging", BROKEN_IDS.length, "broken questions ...");
  const batch = db.batch();
  for (const id of BROKEN_IDS) {
    batch.delete(db.collection("questions").doc(id));
  }
  await batch.commit();
  console.log("✅ Purged", BROKEN_IDS.length, "broken questions");

  console.log("\nDone. Sign out and back in on the app to pick up the admin claim.");
  process.exit(0);
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
