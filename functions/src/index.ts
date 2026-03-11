/**
 * Prep Royale - Cloud Functions
 *
 * Backend functions for:
 * - Daily batch question generation (Gemini AI)
 * - Real-time battle matchmaking
 * - Leaderboard updates
 * - Widget tips
 */

import * as functions from "firebase-functions";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import {
  runDailyGeneration,
  generateForSpecificSkill,
  getGenerationStats
} from "./batch/dailyGenerator";
import { generateQuestionsWithGemini } from "./utils/geminiHelper";
import { writeQuestionsToFirestore, logGenerationRun } from "./utils/validation";
import { QUESTION_CONFIG } from "./config/questionConfig";
import {
  sendFriendRequestNotification,
  sendFriendRequestAcceptedNotification,
  sendBattleInviteNotification,
  sendStreakWarningNotification,
  sendDailyReminderNotification,
  // sendAchievementNotification, // Not yet implemented
  // sendLeaderboardNotification, // Not yet implemented
} from "./utils/notificationHelper";

admin.initializeApp();

const db = admin.firestore();
const rtdb = admin.database();

/**
 * Guard for unauthenticated HTTP (onRequest) admin endpoints.
 * Checks the X-Admin-Secret header against the ADMIN_SECRET env variable.
 * Set the secret with: firebase functions:config:set admin.secret="<random>"
 * (then access via process.env.ADMIN_SECRET in Functions v2, or
 *  functions.config().admin.secret in v1 — stored in process.env for v2)
 */
function requireAdminSecret(req: Parameters<ReturnType<typeof onRequest>>[0], res: Parameters<ReturnType<typeof onRequest>>[1]): boolean {
  const secret = process.env.ADMIN_SECRET;
  if (!secret) {
    res.status(500).json({ error: "ADMIN_SECRET environment variable is not set on this function." });
    return false;
  }
  const provided = req.headers["x-admin-secret"] as string | undefined;
  if (!provided || provided !== secret) {
    res.status(403).json({ error: "Forbidden: invalid or missing X-Admin-Secret header." });
    return false;
  }
  return true;
}

/**
 * Wraps an async handler as a v2 HTTPS endpoint compatible with the callable payload format.
 *
 * Using onRequest (v2) instead of onCall (v1) BYPASSES Firebase App Check enforcement
 * at the Firebase infrastructure level while still enforcing auth via the Bearer token
 * in code. The client sends the same { "data": ... } body and reads { "result": ... }.
 */
function wrapAsCallable(
  handler: (data: Record<string, unknown>, auth: { userId: string; isAnonymous: boolean }) => Promise<unknown>
): ReturnType<typeof onRequest> {
  return onRequest({ cors: true }, async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: { status: "METHOD_NOT_ALLOWED", message: "Use POST" } });
      return;
    }

    const data = (req.body?.data ?? {}) as Record<string, unknown>;

    // Auth: prefer Authorization header, fall back to data._idToken (Samsung/GMS workaround)
    const authHeader = req.headers.authorization as string | undefined;
    const token = authHeader?.startsWith("Bearer ")
      ? authHeader.slice(7)
      : (data._idToken as string | undefined);

    if (!token) {
      res.status(401).json({ error: { status: "UNAUTHENTICATED", message: "Must be authenticated" } });
      return;
    }

    let userId: string;
    let isAnonymous = false;
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      userId = decoded.uid;
      isAnonymous = (decoded as unknown as { firebase?: { sign_in_provider?: string } })
        .firebase?.sign_in_provider === "anonymous";
      console.log("[wrapAsCallable] Auth succeeded, uid:", userId);
    } catch (e) {
      console.log("[wrapAsCallable] Token verification failed:", (e as Error).message);
      res.status(401).json({ error: { status: "UNAUTHENTICATED", message: "Invalid or expired authentication token" } });
      return;
    }

    try {
      const result = await handler(data, { userId, isAnonymous });
      res.status(200).json({ result });
    } catch (e) {
      if (e instanceof functions.https.HttpsError) {
        const statusMap: Record<string, number> = {
          "unauthenticated": 401, "permission-denied": 403, "not-found": 404,
          "resource-exhausted": 429, "invalid-argument": 400, "already-exists": 409,
          "failed-precondition": 400, "deadline-exceeded": 400, "internal": 500,
        };
        const httpStatus = statusMap[e.code] ?? 500;
        res.status(httpStatus).json({ error: { status: e.code.toUpperCase().replace(/-/g, "_"), message: e.message } });
      } else {
        console.error("[wrapAsCallable] Unhandled error:", e);
        res.status(500).json({ error: { status: "INTERNAL", message: "An internal error occurred" } });
      }
    }
  });
}

// ============ DAILY BATCH GENERATION ============

/**
 * Scheduled function that runs daily at 12 AM UTC (midnight).
 * Generates questions for skills with deficits.
 */
export const dailyQuestionGeneration = onSchedule(
  { schedule: "0 0 * * *", timeZone: "UTC" },
  async (_event) => {
    console.log("Starting scheduled daily question generation...");

    try {
      const result = await runDailyGeneration();

      console.log(`Daily generation complete:
        Total Generated: ${result.totalGenerated}
        Total Written: ${result.totalWritten}
        Skills Processed: ${result.results.length}`);
    } catch (error) {
      console.error("Daily generation failed:", error);
      throw error;
    }
  }
);

/**
 * Manual trigger for generating questions for a specific skill.
 * Admin only - requires admin claim on user token.
 */
export const manualGenerateQuestions = functions.https.onCall(
  async (data: {
    examType: string;
    section: string;
    skill: string;
    count?: number;
  }, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError("permission-denied", "Admin only");
    }

    const { examType, section, skill, count } = data;

    try {
      const result = await generateForSpecificSkill(
        examType,
        section,
        skill,
        count
      );

      return {
        success: true,
        generated: result.generated,
        written: result.written,
        skipped: result.skipped,
        error: result.error
      };
    } catch (error) {
      console.error("Manual generation error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Generation failed: ${(error as Error).message}`
      );
    }
  }
);

/**
 * Manual trigger for full daily generation.
 * Admin only.
 */
export const manualDailyGeneration = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }
    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError("permission-denied", "Admin only");
    }

    try {
      const result = await runDailyGeneration();
      return {
        success: true,
        totalGenerated: result.totalGenerated,
        totalWritten: result.totalWritten,
        skillsProcessed: result.results.length
      };
    } catch (error) {
      console.error("Manual daily generation error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Generation failed: ${(error as Error).message}`
      );
    }
  }
);

/**
 * Get question generation statistics.
 */
export const getQuestionStats = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    try {
      const stats = await getGenerationStats();
      return stats;
    } catch (error) {
      console.error("Stats error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to get stats: ${(error as Error).message}`
      );
    }
  }
);

/**
 * Admin-only callable: purge low-quality questions from Firestore.
 * Deletes:
 *   1. All questions with difficulty == "easy"
 *   2. All passage-section questions (Reading/Writing/English/Science) that have no passage field
 *
 * Safe to run multiple times. Returns counts of deleted documents.
 */
export const purgeEasyQuestions = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }
    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError("permission-denied", "Admin only");
    }

    const db = admin.firestore();
    const BATCH_SIZE = 500;

    let deletedEasy = 0;
    let deletedNoPassage = 0;

    // 1. Delete easy-difficulty questions
    const easySnap = await db.collection("questions").where("difficulty", "==", "easy").get();
    for (let i = 0; i < easySnap.docs.length; i += BATCH_SIZE) {
      const batch = db.batch();
      easySnap.docs.slice(i, i + BATCH_SIZE).forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      deletedEasy += Math.min(BATCH_SIZE, easySnap.docs.length - i);
    }
    console.log(`Purged ${deletedEasy} easy-difficulty questions`);

    // 2. Delete passage-section questions without a passage field
    const passageSections = ["Reading", "Writing", "English", "Science"];
    for (const section of passageSections) {
      const snap = await db.collection("questions").where("section", "==", section).get();
      const toDelete = snap.docs.filter(doc => {
        const data = doc.data();
        return !data.passage || typeof data.passage !== "string" || data.passage.trim().length < 100;
      });
      for (let i = 0; i < toDelete.length; i += BATCH_SIZE) {
        const batch = db.batch();
        toDelete.slice(i, i + BATCH_SIZE).forEach(doc => batch.delete(doc.ref));
        await batch.commit();
        deletedNoPassage += Math.min(BATCH_SIZE, toDelete.length - i);
      }
      console.log(`Purged ${toDelete.length} ${section} questions without passage`);
    }

    const total = deletedEasy + deletedNoPassage;
    console.log(`Purge complete: ${total} total questions deleted`);
    return { deletedEasy, deletedNoPassage, total };
  }
);

/**
 * Admin-only callable: delete the 18 confirmed broken questions identified
 * during the 2026-03 audit. IDs are sourced from functions/flagged_questions.json.
 * Safe to run multiple times (skips missing docs silently).
 */
export const purgeKnownBrokenQuestions = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }
    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError("permission-denied", "Admin only");
    }

    const BROKEN_IDS = [
      "5nHTgU2Id0HQ9WFtPbcy",
      "6ldZMgmyIheGcYBz8A9l",
      "7i2DGyQFOpUjqxMGHygc",
      "FDCtUKKtKr7TAN49GU2j",
      "FFdFnP5SOamGBL8JQVcU",
      "MOCVdUVRnY2VbJyIyZDC",
      "MPhOoEHiGJmxbCuSXaVe",
      "ORUDqkfSbK0TFWhT6oix",
      "OmnpUslGkYGIq1zauPkc",
      "QS5GSjgdh1famCnF8MIC",
      "T7W05jCS99NW7ZqSOQJR",
      "VxDUmaAHu1FfB79wKyxu",
      "ZwQXSIOhdIYyhEUveF1R",
      "b7doMhqy1h5509yReAe6",
      "gUZTqhB3a5aGTcxJvOUn",
      "hHfpC3XRojjqUhGePKb7",
      "ntSkPgXiyPwlJhJOZcjg",
      "omqCIbjKChTuRRt80uj5",
    ];

    const batch = db.batch();
    for (const id of BROKEN_IDS) {
      batch.delete(db.collection("questions").doc(id));
    }
    await batch.commit();

    console.log(`purgeKnownBrokenQuestions: deleted ${BROKEN_IDS.length} flagged questions`);
    return { deleted: BROKEN_IDS.length, ids: BROKEN_IDS };
  }
);

// ============ MATCHMAKING ============

export const joinMatchmaking = wrapAsCallable(
  async (data, { userId, isAnonymous }) => {
    try {
      // Rate limiting: max 20 matchmaking joins per 5 minutes (non-anonymous users only)
      if (!isAnonymous) {
        const fiveMinutesAgo = admin.firestore.Timestamp.fromMillis(
          Date.now() - 5 * 60 * 1000
        );

        const recentJoins = await db.collection("matchmakingLogs")
          .where("userId", "==", userId)
          .where("timestamp", ">", fiveMinutesAgo)
          .get();

        if (recentJoins.size >= 20) {
          throw new functions.https.HttpsError(
            "resource-exhausted",
            "Too many matchmaking requests. Please wait a few minutes."
          );
        }

        // Log this matchmaking attempt
        await db.collection("matchmakingLogs").add({
          userId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Get user data - for anonymous users, use defaults
      let userData: { username: string; profilePictureUrl: string | null; level: number };

      if (isAnonymous) {
        // Guest user - use default values
        userData = {
          username: "Guest",
          profilePictureUrl: null,
          level: 1,
        };
      } else {
        // Authenticated user - get from Firestore
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
          throw new functions.https.HttpsError("not-found", "User not found");
        }
        const firestoreData = userDoc.data()!;
        userData = {
          username: firestoreData.username,
          profilePictureUrl: firestoreData.profilePictureUrl || null,
          level: firestoreData.level || 1,
        };
      }

      const userLevel = userData.level;
      const requestedTestType = (data.testType as string) || "SAT";

      // Check for existing match in queue
      const queueRef = rtdb.ref("matchmaking");
      const queueSnapshot = await queueRef.once("value");
      const queue = queueSnapshot.val() || {};

      let matchedUserId: string | null = null;

      // Find opponent within ±3 levels and matching test type
      for (const [queuedUserId, entry] of Object.entries(queue)) {
        if (queuedUserId === userId) continue;

        const queuedEntry = entry as { level: number; joinedAt: number; testType: string };
        if (
          Math.abs(queuedEntry.level - userLevel) <= 3 &&
          queuedEntry.testType === requestedTestType
        ) {
          matchedUserId = queuedUserId;
          break;
        }
      }

      // Helper: add this user to the queue and return
      const addSelfToQueue = async () => {
        await queueRef.child(userId).set({
          username: userData.username,
          profilePictureUrl: userData.profilePictureUrl || null,
          level: userLevel,
          testType: requestedTestType,
          joinedAt: Date.now(),
        });
        return { battleId: null, matched: false, queued: true };
      };

      if (matchedUserId) {
        // Atomically claim the matched opponent's queue entry.
        // If another concurrent caller already claimed it, the transaction aborts
        // (returns null) and we fall through to adding ourselves to the queue.
        const matchedRef = queueRef.child(matchedUserId);
        const claimResult = await matchedRef.transaction((current) => {
          if (current === null) return; // Already claimed — abort
          return null; // Remove atomically
        });

        if (!claimResult.committed) {
          // Race lost — the opponent was already claimed by another caller.
          return await addSelfToQueue();
        }

        // Transaction committed: we exclusively own this match.
        const claimedEntry = claimResult.snapshot.val() as {
          username: string;
          profilePictureUrl: string | null;
          level: number;
          testType: string;
          joinedAt: number;
        };

        const opponentData = {
          username: claimedEntry.username,
          profilePictureUrl: claimedEntry.profilePictureUrl,
          level: claimedEntry.level,
        };

        // Get random questions from Firestore filtered by testType
        const questionsSnapshot = await db
          .collection("questions")
          .where("examType", "==", requestedTestType)
          .limit(500)
          .get();

        // Filter out passage-required questions that have no passage stored
        const PASSAGE_SECTIONS = ["Reading", "Writing", "English", "Science"];
        const allQuestions = questionsSnapshot.docs
          .filter(doc => {
            const d = doc.data();
            if (PASSAGE_SECTIONS.includes(d.section as string)) {
              const passage = d.passage as string | undefined;
              return passage && passage.trim().length > 0;
            }
            return true;
          })
          .map(doc => doc.id);

        if (allQuestions.length === 0) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "No questions available for this test type yet. AI generation might be in progress."
          );
        }

        // Fisher-Yates shuffle
        const shuffled = [...allQuestions];
        for (let i = shuffled.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }
        const questionIds = shuffled.slice(0, Math.min(20, allQuestions.length));

        // Create battle in Realtime Database
        const battleRef = rtdb.ref("battles").push();
        const battleId = battleRef.key!;

        const battleData = {
          player1: {
            id: matchedUserId,
            username: opponentData.username,
            profilePictureUrl: opponentData.profilePictureUrl || null,
            level: opponentData.level || 1,
            health: 100,
            score: 0,
            currentQuestionIndex: 0,
            answers: [],
          },
          player2: {
            id: userId,
            username: userData.username,
            profilePictureUrl: userData.profilePictureUrl || null,
            level: userLevel,
            health: 100,
            score: 0,
            currentQuestionIndex: 0,
            answers: [],
          },
          status: "inProgress",
          questionIds,
          currentQuestionIndex: 0,
          questionTimeLimit: 30,
          questionStartTime: Date.now(),
          winnerId: null,
          createdAt: Date.now(),
          completedAt: null,
        };

        await battleRef.set(battleData);

        // Notify the queued player (player1) of the battle ID
        // so their client can subscribe — they only got { queued: true } earlier.
        await rtdb.ref(`userBattles/${matchedUserId}`).set({ battleId });

        return { battleId, matched: true };
      } else {
        return await addSelfToQueue();
      }
    } catch (error) {
      console.error("Matchmaking error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Matchmaking failed: ${error}`
      );
    }
  }
);

/**
 * Leave matchmaking queue.
 */
export const leaveMatchmaking = wrapAsCallable(
  async (_data, { userId }) => {

    try {
      await rtdb.ref(`matchmaking/${userId}`).remove();
      return { success: true };
    } catch (error) {
      console.error("Leave matchmaking error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to leave queue: ${error}`
      );
    }
  }
);

/**
 * Create a battle between two friends.
 * Validates friendship exists and is accepted before creating battle.
 */
export const createFriendBattle = wrapAsCallable(
  async (data, { userId }) => {
    const friendId = data.friendId as string;
    const testType = (data.testType as string) || "SAT";

    // Validate input
    if (!friendId || typeof friendId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "friendId is required"
      );
    }

    // Prevent self-battle
    if (userId === friendId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot battle yourself"
      );
    }

    try {
      // Validate friendship exists and is accepted
      const [user1Id, user2Id] = [userId, friendId].sort();
      const friendshipQuery = await db.collection("friendships")
        .where("user1Id", "==", user1Id)
        .where("user2Id", "==", user2Id)
        .where("status", "==", "accepted")
        .get();

      if (friendshipQuery.empty) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "You must be friends with this user to start a battle"
        );
      }

      // Get both users' data
      const [userDoc, friendDoc] = await Promise.all([
        db.collection("users").doc(userId).get(),
        db.collection("users").doc(friendId).get(),
      ]);

      if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User not found");
      }
      if (!friendDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Friend not found");
      }

      const userData = userDoc.data()!;
      const friendData = friendDoc.data()!;

      // Get questions for the battle
      // FIXED: Increased limit from 100 to 500 for better randomization
      const questionsSnapshot = await db
        .collection("questions")
        .where("examType", "==", testType)
        .limit(500)
        .get();

      // Filter out passage-required questions that have no passage stored
      const PASSAGE_SECTIONS_FB = ["Reading", "Writing", "English", "Science"];
      const allQuestions = questionsSnapshot.docs
        .filter(doc => {
          const d = doc.data();
          if (PASSAGE_SECTIONS_FB.includes(d.section as string)) {
            const passage = d.passage as string | undefined;
            return passage && passage.trim().length > 0;
          }
          return true;
        })
        .map(doc => doc.id);
      if (allQuestions.length === 0) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "No questions available for this test type yet"
        );
      }

      // FIXED: Use Fisher-Yates shuffle for better randomization
      const shuffled = [...allQuestions];
      for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
      }
      const questionIds = shuffled.slice(0, Math.min(20, allQuestions.length));

      // Create battle in Realtime Database
      const battleRef = rtdb.ref("battles").push();
      const battleId = battleRef.key!;

      const battleData = {
        player1: {
          id: userId,
          username: userData.username || "Player 1",
          profilePictureUrl: userData.profilePictureUrl || null,
          level: userData.level || 1,
          health: 100,
          score: 0,
          currentQuestionIndex: 0,
          answers: [],
        },
        player2: {
          id: friendId,
          username: friendData.username || "Player 2",
          profilePictureUrl: friendData.profilePictureUrl || null,
          level: friendData.level || 1,
          health: 100,
          score: 0,
          currentQuestionIndex: 0,
          answers: [],
        },
        status: "waiting",
        questionIds,
        currentQuestionIndex: 0,
        questionTimeLimit: 30,
        questionStartTime: null,
        winnerId: null,
        createdAt: Date.now(),
        completedAt: null,
        isFriendBattle: true,
      };

      await battleRef.set(battleData);

      // Write pending invite so the friend's device detects it in-app
      await rtdb.ref(`pendingBattleInvites/${friendId}`).set({
        battleId,
        fromUsername: userData.username || "A friend",
        testType,
        createdAt: Date.now(),
      });

      // Send push notification to friend (player2)
      await sendBattleInviteNotification(
        friendId,
        userData.username || "A friend",
        battleId,
        testType
      );

      return { battleId, success: true };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Create friend battle error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to create friend battle: ${error}`
      );
    }
  }
);

/**
 * Accept a friend battle invitation.
 * Only the invited player (player2) can accept.
 */
export const acceptFriendBattle = wrapAsCallable(
  async (data, { userId }) => {
    const battleId = data.battleId as string;
    if (!battleId) throw new functions.https.HttpsError("invalid-argument", "battleId is required");

    const battleRef = rtdb.ref(`battles/${battleId}`);
    const snapshot = await battleRef.once("value");
    const battle = snapshot.val();

    if (!battle) throw new functions.https.HttpsError("not-found", "Battle not found");
    if (battle.player2?.id !== userId) throw new functions.https.HttpsError("permission-denied", "You are not the invited player");
    if (battle.status !== "waiting") throw new functions.https.HttpsError("failed-precondition", "Battle is no longer pending");

    await battleRef.update({ status: "inProgress", questionStartTime: Date.now() });
    // Clean up the pending invite
    await rtdb.ref(`pendingBattleInvites/${userId}`).remove();

    return { success: true };
  }
);

/**
 * Decline a friend battle invitation.
 * Only the invited player (player2) can decline — deletes the battle.
 */
export const declineFriendBattle = wrapAsCallable(
  async (data, { userId }) => {
    const battleId = data.battleId as string;
    if (!battleId) throw new functions.https.HttpsError("invalid-argument", "battleId is required");

    const battleRef = rtdb.ref(`battles/${battleId}`);
    const snapshot = await battleRef.once("value");
    const battle = snapshot.val();

    if (!battle) return { success: true }; // already gone
    if (battle.player2?.id !== userId) throw new functions.https.HttpsError("permission-denied", "You are not the invited player");
    if (battle.status !== "waiting") throw new functions.https.HttpsError("failed-precondition", "Battle is no longer pending");

    // Mark as declined so both clients' RTDB listeners fire (rule uses existing data).
    // The battle doc is left for the scheduled cleanup; only the invite node is removed.
    await battleRef.update({ status: "declined" });
    await rtdb.ref(`pendingBattleInvites/${userId}`).remove();

    return { success: true };
  }
);

/**
 * Cancel a friend battle invite before the friend accepts.
 * Only the challenger (player1) can cancel.
 */
export const cancelFriendBattle = wrapAsCallable(
  async (data, { userId }) => {
    const battleId = data.battleId as string;
    if (!battleId) throw new functions.https.HttpsError("invalid-argument", "battleId is required");

    const battleRef = rtdb.ref(`battles/${battleId}`);
    const snapshot = await battleRef.once("value");
    const battle = snapshot.val();

    if (!battle) return { success: true }; // already gone
    if (battle.player1?.id !== userId) throw new functions.https.HttpsError("permission-denied", "You are not the challenger");
    if (battle.status !== "waiting") throw new functions.https.HttpsError("failed-precondition", "Battle already started");

    const friendId = battle.player2?.id;
    // Mark as declined so the invitee's RTDB listener fires (rule uses existing data).
    await battleRef.update({ status: "declined" });
    if (friendId) await rtdb.ref(`pendingBattleInvites/${friendId}`).remove();

    return { success: true };
  }
);

/**
 * Forfeit an active battle.
 * Either player can forfeit — opponent is declared winner immediately.
 */
export const forfeitBattle = wrapAsCallable(
  async (data, { userId }) => {
    const battleId = data.battleId as string;
    if (!battleId) throw new functions.https.HttpsError("invalid-argument", "battleId is required");

    const battleRef = rtdb.ref(`battles/${battleId}`);
    const snapshot = await battleRef.once("value");
    const battle = snapshot.val();

    if (!battle) throw new functions.https.HttpsError("not-found", "Battle not found");
    if (battle.status !== "inProgress") throw new functions.https.HttpsError("failed-precondition", "Battle is not in progress");

    const isPlayer1 = battle.player1?.id === userId;
    const isPlayer2 = battle.player2?.id === userId;
    if (!isPlayer1 && !isPlayer2) throw new functions.https.HttpsError("permission-denied", "You are not in this battle");

    const opponentId = isPlayer1 ? battle.player2.id : battle.player1.id;
    const player1Id = battle.player1.id;
    const player2Id = battle.player2.id;

    await battleRef.update({
      status: "completed",
      winnerId: opponentId,
      completedAt: Date.now(),
    });

    await db.collection("battleResults").add({
      battleId,
      player1Id,
      player1Health: battle.player1.health ?? 0,
      player2Id,
      player2Health: battle.player2.health ?? 0,
      winnerId: opponentId,
      forfeitedBy: userId,
      completedAt: FieldValue.serverTimestamp(),
    });

    // Forfeiter gets 0 XP; victor gets XP proportional to questions answered
    const victorKey = isPlayer1 ? "player2" : "player1";
    const victorAnswers = (battle[victorKey]?.answers as unknown[]) || [];
    const totalQuestions = (battle.questionIds as string[])?.length || 20;
    const victorXp = Math.max(10, Math.ceil(50 * victorAnswers.length / totalQuestions));

    await updateBattleStats(userId, false, 0);         // forfeiter: 0 XP, +1 loss
    await updateBattleStats(opponentId, true, victorXp); // victor: proportional XP

    return { success: true };
  }
);

/**
 * Scheduled cleanup of stale matchmaking entries.
 * Removes users who have been in queue for more than 5 minutes.
 * Runs every 5 minutes.
 */
export const cleanupStaleMatchmaking = onSchedule("every 5 minutes", async (_event) => {
    const fiveMinutesAgo = Date.now() - 5 * 60 * 1000;

    try {
      const queueRef = rtdb.ref("matchmaking");
      const queueSnapshot = await queueRef.once("value");
      const queue = queueSnapshot.val();

      if (!queue) {
        console.log("Matchmaking queue is empty, nothing to clean up");
        return;
      }

      const staleUserIds: string[] = [];

      for (const [odUserId, entry] of Object.entries(queue)) {
        const queuedEntry = entry as { joinedAt: number };
        if (queuedEntry.joinedAt < fiveMinutesAgo) {
          staleUserIds.push(odUserId);
        }
      }

      if (staleUserIds.length === 0) {
        console.log("No stale matchmaking entries found");
        return;
      }

      // Remove all stale entries
      const updates: Record<string, null> = {};
      for (const odUserId of staleUserIds) {
        updates[odUserId] = null;
      }

      await queueRef.update(updates);
      console.log(`Cleaned up ${staleUserIds.length} stale matchmaking entries`);
    } catch (error) {
      console.error("Matchmaking cleanup error:", error);
    }
  });

/**
 * Scheduled cleanup of completed/abandoned battles.
 * Removes battles that have been completed or inactive for more than 24 hours.
 * Runs daily at 4 AM UTC.
 */
export const cleanupOldBattles = onSchedule(
  { schedule: "0 4 * * *", timeZone: "UTC" },
  async (_event) => {
    const twentyFourHoursAgo = Date.now() - 24 * 60 * 60 * 1000;

    try {
      const battlesRef = rtdb.ref("battles");
      const battlesSnapshot = await battlesRef.once("value");
      const battles = battlesSnapshot.val();

      if (!battles) {
        console.log("No battles to clean up");
        return;
      }

      const staleBattleIds: string[] = [];
      const timeoutUpdates: Record<string, any> = {};

      for (const [battleId, battle] of Object.entries(battles)) {
        const battleData = battle as {
          status: string;
          completedAt?: number;
          createdAt: number;
          questionStartTime?: number;
        };

        // SECURITY FIX: Auto-complete battles stuck in "inProgress" for > 1 hour
        if (battleData.status === "inProgress") {
          const battleAge = Date.now() - battleData.createdAt;
          if (battleAge > 3600000) { // 1 hour
            console.log(`Abandoning stale battle: ${battleId}`);
            timeoutUpdates[`${battleId}/status`] = "abandoned";
            timeoutUpdates[`${battleId}/completedAt`] = Date.now();
            continue; // Don't delete yet, mark as abandoned first
          }
        }

        // Remove completed battles older than 24 hours
        if (battleData.status === "completed" && battleData.completedAt) {
          if (battleData.completedAt < twentyFourHoursAgo) {
            staleBattleIds.push(battleId);
          }
        }
        // Remove abandoned/aborted battles older than 24 hours
        else if ((battleData.status === "abandoned" || battleData.status === "aborted")
                 && battleData.completedAt && battleData.completedAt < twentyFourHoursAgo) {
          staleBattleIds.push(battleId);
        }
        // Remove very old uncompleted battles (created >24 hours ago)
        else if (battleData.createdAt < twentyFourHoursAgo) {
          staleBattleIds.push(battleId);
        }
      }

      // Apply timeout updates first
      if (Object.keys(timeoutUpdates).length > 0) {
        await battlesRef.update(timeoutUpdates);
        console.log(`Marked ${Object.keys(timeoutUpdates).length / 2} battles as abandoned`);
      }

      if (staleBattleIds.length === 0) {
        console.log("No old battles to clean up");
        return;
      }

      // Remove all stale battles
      const updates: Record<string, null> = {};
      for (const battleId of staleBattleIds) {
        updates[battleId] = null;
      }

      await battlesRef.update(updates);
      console.log(`Cleaned up ${staleBattleIds.length} old battles`);
    } catch (error) {
      console.error("Battle cleanup error:", error);
    }
  });

// ============ BATTLE ANSWER SUBMISSION ============

// Server-side damage calculation functions (moved from client for security)
function calculateServerDamage(isCorrect: boolean, timeSpentSeconds: number): number {
  if (!isCorrect) return 0;
  if (timeSpentSeconds <= 15) return 15;
  if (timeSpentSeconds <= 30) return 12;
  return 10;
}

function calculateServerSelfDamage(isCorrect: boolean, timedOut: boolean): number {
  if (timedOut) return 15;
  if (!isCorrect) return 8;
  return 0;
}


export const submitBattleAnswer = wrapAsCallable(
  async (data, { userId }) => {
    const battleId = data.battleId as string;
    const questionIndex = data.questionIndex as number;
    const answer = data.answer as number;

    // Validate answer range
    if (answer < -1 || answer > 3) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Answer must be -1 (timeout) or 0-3"
      );
    }

    try {
      const battleRef = rtdb.ref(`battles/${battleId}`);
      const battleSnapshot = await battleRef.once("value");
      const battle = battleSnapshot.val();

      if (!battle) {
        throw new functions.https.HttpsError("not-found", "Battle not found");
      }

      // Verify user is actually a participant in this battle
      const isPlayer1 = battle.player1.id === userId;
      const isPlayer2 = battle.player2?.id === userId;
      if (!isPlayer1 && !isPlayer2) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You are not a participant in this battle"
        );
      }

      // Determine player keys
      const playerKey = isPlayer1 ? "player1" : "player2";
      const opponentKey = isPlayer1 ? "player2" : "player1";

      // Per-player validation: questionIndex must match THIS player's answer count
      const currentAnswers: number[] = battle[playerKey].answers || [];
      if (questionIndex !== currentAnswers.length) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Invalid question index for this player"
        );
      }

      // Bounds check
      const totalQuestions = (battle.questionIds as string[]).length;
      if (questionIndex >= totalQuestions) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "All questions already answered"
        );
      }

      // SERVER-SIDE: Fetch question from Firestore to validate answer
      const questionId = battle.questionIds[questionIndex];
      const questionDoc = await db.collection("questions").doc(questionId).get();

      if (!questionDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Question not found"
        );
      }

      const question = questionDoc.data()!;

      // SERVER-SIDE: Calculate damage based on correct answer
      // Support both field names: legacy "correctAnswer" and newer "correctChoiceIndex"
      const correctAnswer = question.correctAnswer ?? question.correctChoiceIndex;
      const timedOut = answer === -1;

      // The client shuffles choices for display, so the submitted index may not
      // match the original stored index. Compare by choice TEXT when available
      // (answerText is sent from the client with the actual displayed text of
      // the selected choice). Fall back to index comparison for legacy clients.
      const answerText = data.answerText as string | null | undefined;
      const correctText: string | undefined =
        Array.isArray(question.choices) ? question.choices[correctAnswer] : undefined;
      const isCorrect =
        !timedOut &&
        (typeof answerText === "string" && correctText !== undefined
          ? answerText === correctText   // text-based comparison (shuffle-safe)
          : answer === correctAnswer);   // legacy index fallback
      // Use a fixed time value since timing is per-player and not tracked server-side
      const timeSpent = 15; // treat all answers as mid-range for damage calculation

      const damage = calculateServerDamage(isCorrect, timeSpent);
      const selfDamage = calculateServerSelfDamage(isCorrect, timedOut);

      const currentPlayerHealth = battle[playerKey].health ?? 100;
      const currentOpponentHealth = battle[opponentKey].health ?? 100;

      const newPlayerHealth = Math.max(0, currentPlayerHealth - selfDamage);
      const newOpponentHealth = Math.max(0, currentOpponentHealth - damage);

      // Update player health and record answer
      const updates: Record<string, unknown> = {};
      updates[`${playerKey}/health`] = newPlayerHealth;
      updates[`${opponentKey}/health`] = newOpponentHealth;
      updates[`${playerKey}/answers`] = [
        ...(battle[playerKey].answers || []),
        answer,
      ];

      await battleRef.update(updates);

      // Check if either player's health reached 0 - end battle immediately
      if (newPlayerHealth <= 0 || newOpponentHealth <= 0) {
        let winnerId: string | null = null;
        if (newPlayerHealth > newOpponentHealth) {
          winnerId = battle[playerKey].id;
        } else if (newOpponentHealth > newPlayerHealth) {
          winnerId = battle[opponentKey].id;
        }

        await battleRef.update({
          status: "completed",
          winnerId,
          completedAt: Date.now(),
        });

        // Re-fetch updated battle for history record
        const finalSnapshot = await battleRef.once("value");
        const finalBattle = finalSnapshot.val();

        await db.collection("battleResults").add({
          battleId,
          player1Id: finalBattle.player1.id,
          player1Health: finalBattle.player1.health ?? 0,
          player2Id: finalBattle.player2.id,
          player2Health: finalBattle.player2.health ?? 0,
          winnerId,
          completedAt: FieldValue.serverTimestamp(),
        });

        await updateBattleStats(finalBattle.player1.id, winnerId === finalBattle.player1.id);
        await updateBattleStats(finalBattle.player2.id, winnerId === finalBattle.player2.id);

        return { success: true };
      }

      // Check if both players have now answered ALL questions — end battle
      const updatedSnapshot = await battleRef.once("value");
      const updatedBattle = updatedSnapshot.val();

      const p1Answers = updatedBattle.player1.answers?.length || 0;
      const p2Answers = updatedBattle.player2.answers?.length || 0;

      if (p1Answers >= totalQuestions && p2Answers >= totalQuestions) {
        // Both players finished all 20 questions
        const p1Health = updatedBattle.player1.health ?? 0;
        const p2Health = updatedBattle.player2.health ?? 0;
        let winnerId: string | null = null;

        if (p1Health > p2Health) {
          winnerId = updatedBattle.player1.id;
        } else if (p2Health > p1Health) {
          winnerId = updatedBattle.player2.id;
        }

        await battleRef.update({
          status: "completed",
          winnerId,
          completedAt: Date.now(),
        });

        // Store battle result in Firestore for history
        await db.collection("battleResults").add({
          battleId,
          player1Id: updatedBattle.player1.id,
          player1Health: p1Health,
          player2Id: updatedBattle.player2.id,
          player2Health: p2Health,
          winnerId,
          completedAt: FieldValue.serverTimestamp(),
        });

        // Update battle stats for both players
        await updateBattleStats(updatedBattle.player1.id, winnerId === updatedBattle.player1.id);
        await updateBattleStats(updatedBattle.player2.id, winnerId === updatedBattle.player2.id);
      }

      return { success: true };
    } catch (error) {
      console.error("Submit answer error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to submit answer: ${error}`
      );
    }
  }
);

/**
 * Update battle stats and XP for a user.
 * Uses wins/losses fields to match client-side BattleStats model.
 * Awards 50 XP for win, 20 XP for loss.
 */
async function updateBattleStats(userId: string, won: boolean, xpOverride?: number): Promise<void> {
  const userRef = db.collection("users").doc(userId);
  const xpAmount = xpOverride !== undefined ? xpOverride : (won ? 50 : 20);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) return;

    const data = userDoc.data()!;
    const battleStats = data.battleStats || { wins: 0, losses: 0 };
    const currentTotalXp = data.totalXp || 0;
    const currentLevel = data.level || 1;
    const currentUnlocked: string[] = data.unlockedAchievements || [];

    const newWins = won ? (battleStats.wins || 0) + 1 : (battleStats.wins || 0);
    const newLosses = won ? (battleStats.losses || 0) : (battleStats.losses || 0) + 1;
    const newTotalBattles = newWins + newLosses;

    // Calculate new XP and level
    const newTotalXp = currentTotalXp + xpAmount;
    let newLevel = currentLevel;
    // Level formula: 100 * level * level
    while (newTotalXp >= 100 * (newLevel + 1) * (newLevel + 1)) {
      newLevel++;
    }

    // Check which achievements to unlock
    const unlockedSet = new Set(currentUnlocked);
    const toUnlock: string[] = [];

    // Battle count achievements
    if (newTotalBattles >= 1 && !unlockedSet.has("battle_ready")) toUnlock.push("battle_ready");
    // Battle win achievements
    if (newWins >= 10 && !unlockedSet.has("victor")) toUnlock.push("victor");
    if (newWins >= 50 && !unlockedSet.has("champion")) toUnlock.push("champion");
    if (newWins >= 100 && !unlockedSet.has("legend")) toUnlock.push("legend");
    // Level achievements
    if (newLevel >= 5 && !unlockedSet.has("rising_star")) toUnlock.push("rising_star");
    if (newLevel >= 20 && !unlockedSet.has("expert")) toUnlock.push("expert");
    if (newLevel >= 50 && !unlockedSet.has("titan")) toUnlock.push("titan");

    const updates: Record<string, unknown> = {
      "battleStats.wins": newWins,
      "battleStats.losses": newLosses,
      "totalXp": newTotalXp,
      "level": newLevel,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (toUnlock.length > 0) {
      updates["unlockedAchievements"] = FieldValue.arrayUnion(...toUnlock);
    }

    transaction.update(userRef, updates);
  });
}

// ============ LEADERBOARD UPDATE ============

export const updateLeaderboard = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    // Only update if XP changed
    if (before.totalXp === after.totalXp) {
      return null;
    }

    try {
      const leaderboardRef = db
        .collection("leaderboards")
        .doc("global")
        .collection("entries")
        .doc(userId);

      await leaderboardRef.set({
        userId,
        username: after.username,
        profilePictureUrl: after.profilePictureUrl || null,
        level: after.level || 1,
        totalXp: after.totalXp || 0,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error("Leaderboard update error:", error);
      return null;
    }
  });

// ============ FRIENDS SYSTEM ============

// Rate limiting: max 10 friend requests per hour per user
const FRIEND_REQUEST_LIMIT = 10;
const FRIEND_REQUEST_WINDOW_MS = 60 * 60 * 1000; // 1 hour

/**
 * Send a friend request to another user.
 * Creates a friendship document with status 'pending'.
 * Rate limited to 10 requests per hour.
 */
export const sendFriendRequest = wrapAsCallable(
  async (data, { userId: fromUserId }) => {
    const toUserId = data.toUserId as string;

    // Validate input
    if (!toUserId || typeof toUserId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "toUserId is required"
      );
    }

    // Rate limiting: check recent friend requests from this user
    const oneHourAgo = new Date(Date.now() - FRIEND_REQUEST_WINDOW_MS);
    const recentRequestsQuery = await db.collection("friendships")
      .where("requesterId", "==", fromUserId)
      .where("createdAt", ">=", oneHourAgo)
      .get();

    if (recentRequestsQuery.size >= FRIEND_REQUEST_LIMIT) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Too many friend requests. Please wait before sending more."
      );
    }

    // Prevent self-friending
    if (fromUserId === toUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot send friend request to yourself"
      );
    }

    try {
      // Check if target user exists
      const targetUserDoc = await db.collection("users").doc(toUserId).get();
      if (!targetUserDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User not found"
        );
      }

      // Normalize user IDs for consistent document structure
      // (alphabetically sorted to prevent duplicate friendships)
      const [user1Id, user2Id] = [fromUserId, toUserId].sort();

      // Check for existing friendship
      const existingQuery = await db.collection("friendships")
        .where("user1Id", "==", user1Id)
        .where("user2Id", "==", user2Id)
        .get();

      if (!existingQuery.empty) {
        const existing = existingQuery.docs[0].data();
        if (existing.status === "accepted") {
          throw new functions.https.HttpsError(
            "already-exists",
            "You are already friends with this user"
          );
        } else if (existing.status === "pending") {
          throw new functions.https.HttpsError(
            "already-exists",
            "A friend request already exists"
          );
        } else if (existing.status === "blocked") {
          throw new functions.https.HttpsError(
            "permission-denied",
            "Cannot send friend request to this user"
          );
        }
      }

      // Get sender's username for notifications
      const fromUserDoc = await db.collection("users").doc(fromUserId).get();
      const fromUsername = fromUserDoc.data()?.username || "Unknown";
      const fromProfilePictureUrl = fromUserDoc.data()?.profilePictureUrl || null;

      // Create friendship document
      const friendshipRef = await db.collection("friendships").add({
        user1Id,
        user2Id,
        status: "pending",
        requesterId: fromUserId,
        requesterUsername: fromUsername,
        requesterProfilePictureUrl: fromProfilePictureUrl,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Send notification to recipient
      await sendFriendRequestNotification(toUserId, fromUsername, fromUserId);

      return { success: true, friendshipId: friendshipRef.id };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Send friend request error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to send friend request: ${error}`
      );
    }
  }
);

/**
 * Respond to a friend request (accept or decline).
 */
export const respondToFriendRequest = wrapAsCallable(
  async (data, { userId }) => {
    const friendshipId = data.friendshipId as string;
    const accept = data.accept as boolean;

    if (!friendshipId || typeof friendshipId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "friendshipId is required"
      );
    }

    try {
      const friendshipRef = db.collection("friendships").doc(friendshipId);
      const friendshipDoc = await friendshipRef.get();

      if (!friendshipDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Friend request not found"
        );
      }

      const friendship = friendshipDoc.data()!;

      // Verify user is the recipient (not the requester)
      if (friendship.requesterId === userId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Cannot respond to your own friend request"
        );
      }

      // Verify user is part of this friendship
      if (friendship.user1Id !== userId && friendship.user2Id !== userId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You are not part of this friend request"
        );
      }

      // Verify it's still pending
      if (friendship.status !== "pending") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This friend request has already been responded to"
        );
      }

      if (accept) {
        await friendshipRef.update({
          status: "accepted",
          acceptedAt: FieldValue.serverTimestamp(),
        });

        // Send notification to requester that their request was accepted
        const accepterDoc = await db.collection("users").doc(userId).get();
        const accepterUsername = accepterDoc.data()?.username || "Someone";
        await sendFriendRequestAcceptedNotification(
          friendship.requesterId,
          accepterUsername,
          userId
        );
      } else {
        // Delete the friendship document if declined
        await friendshipRef.delete();
      }

      return { success: true, accepted: accept };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Respond to friend request error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to respond to friend request: ${error}`
      );
    }
  }
);

/**
 * Remove a friend (delete the friendship).
 */
export const removeFriend = wrapAsCallable(
  async (data, { userId }) => {
    const friendshipId = data.friendshipId as string;

    if (!friendshipId || typeof friendshipId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "friendshipId is required"
      );
    }

    try {
      const friendshipRef = db.collection("friendships").doc(friendshipId);
      const friendshipDoc = await friendshipRef.get();

      if (!friendshipDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Friendship not found"
        );
      }

      const friendship = friendshipDoc.data()!;

      // Verify user is part of this friendship
      if (friendship.user1Id !== userId && friendship.user2Id !== userId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You are not part of this friendship"
        );
      }

      await friendshipRef.delete();

      return { success: true };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Remove friend error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to remove friend: ${error}`
      );
    }
  }
);

/**
 * Search for users by username.
 * Returns users matching the search query (case-insensitive prefix match).
 */
export const searchUsers = wrapAsCallable(
  async (data, { userId }) => {
    const query = data.query as string;
    const limit = (data.limit as number) || 10;

    if (!query || typeof query !== "string" || query.length < 2) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Search query must be at least 2 characters"
      );
    }

    try {
      // Firestore doesn't support case-insensitive queries natively,
      // so we search for prefix matches
      const searchQuery = query.toLowerCase();
      const endQuery = searchQuery + "\uf8ff";

      const usersSnapshot = await db.collection("users")
        .where("usernameLower", ">=", searchQuery)
        .where("usernameLower", "<=", endQuery)
        .limit(Math.min(limit, 20))
        .get();

      const users = usersSnapshot.docs
        .filter(doc => doc.id !== userId) // Exclude self
        .map(doc => ({
          odId: doc.id,
          username: doc.data().username,
          profilePictureUrl: doc.data().profilePictureUrl || null,
          level: doc.data().level || 1,
        }));

      return { users };
    } catch (error) {
      console.error("Search users error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to search users: ${error}`
      );
    }
  }
);

/**
 * Look up a user by their unique friend code.
 * Returns basic user info if found.
 */
export const getUserByFriendCode = wrapAsCallable(
  async (data, { userId }) => {
    const friendCode = data.friendCode as string;

    // Validate input
    if (!friendCode || typeof friendCode !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "friendCode is required"
      );
    }

    // Normalize friend code (uppercase, trim whitespace)
    const normalizedCode = friendCode.trim().toUpperCase();

    // Validate format: 8 alphanumeric characters (excluding 0, O, 1, I)
    if (!/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/.test(normalizedCode)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid friend code format"
      );
    }

    try {
      const usersSnapshot = await db.collection("users")
        .where("friendCode", "==", normalizedCode)
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "No user found with that friend code"
        );
      }

      const userDoc = usersSnapshot.docs[0];
      const userData = userDoc.data();

      // Prevent looking up yourself
      if (userDoc.id === userId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "This is your own friend code"
        );
      }

      return {
        userId: userDoc.id,
        username: userData.username,
        profilePictureUrl: userData.profilePictureUrl || null,
        level: userData.level || 1,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Get user by friend code error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to look up friend code: ${error}`
      );
    }
  }
);

/**
 * Send a friend request using a friend code.
 * Looks up the user by code and creates a friend request.
 */
export const sendFriendRequestByCode = wrapAsCallable(
  async (data, { userId: fromUserId }) => {
    const friendCode = data.friendCode as string;

    // Validate input
    if (!friendCode || typeof friendCode !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "friendCode is required"
      );
    }

    // Normalize friend code (uppercase, trim whitespace)
    const normalizedCode = friendCode.trim().toUpperCase();

    // Validate format: 8 alphanumeric characters (excluding 0, O, 1, I)
    if (!/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/.test(normalizedCode)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid friend code format"
      );
    }

    try {
      // Look up user by friend code
      const usersSnapshot = await db.collection("users")
        .where("friendCode", "==", normalizedCode)
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "No user found with that friend code"
        );
      }

      const targetUserDoc = usersSnapshot.docs[0];
      const toUserId = targetUserDoc.id;
      const targetUserData = targetUserDoc.data();

      // Prevent self-friending
      if (fromUserId === toUserId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Cannot send friend request to yourself"
        );
      }

      // Normalize user IDs for consistent document structure
      // (alphabetically sorted to prevent duplicate friendships)
      const [user1Id, user2Id] = [fromUserId, toUserId].sort();

      // Check for existing friendship
      const existingQuery = await db.collection("friendships")
        .where("user1Id", "==", user1Id)
        .where("user2Id", "==", user2Id)
        .get();

      if (!existingQuery.empty) {
        const existing = existingQuery.docs[0].data();
        if (existing.status === "accepted") {
          throw new functions.https.HttpsError(
            "already-exists",
            "You are already friends with this user"
          );
        } else if (existing.status === "pending") {
          throw new functions.https.HttpsError(
            "already-exists",
            "A friend request already exists"
          );
        } else if (existing.status === "blocked") {
          throw new functions.https.HttpsError(
            "permission-denied",
            "Cannot send friend request to this user"
          );
        }
      }

      // Get sender's username for notifications
      const fromUserDoc = await db.collection("users").doc(fromUserId).get();
      const fromUsername = fromUserDoc.data()?.username || "Unknown";
      const fromProfilePictureUrl = fromUserDoc.data()?.profilePictureUrl || null;

      // Create friendship document
      const friendshipRef = await db.collection("friendships").add({
        user1Id,
        user2Id,
        status: "pending",
        requesterId: fromUserId,
        requesterUsername: fromUsername,
        requesterProfilePictureUrl: fromProfilePictureUrl,
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        friendshipId: friendshipRef.id,
        targetUsername: targetUserData.username,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Send friend request by code error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to send friend request: ${error}`
      );
    }
  }
);

/**
 * Get friends leaderboard for the current user.
 * Returns leaderboard entries for user's friends and self.
 */
export const getFriendsLeaderboard = wrapAsCallable(
  async (_data, { userId }) => {

    try {
      // Get all accepted friendships where user is a participant
      const friendships1 = await db.collection("friendships")
        .where("user1Id", "==", userId)
        .where("status", "==", "accepted")
        .get();

      const friendships2 = await db.collection("friendships")
        .where("user2Id", "==", userId)
        .where("status", "==", "accepted")
        .get();

      // Collect friend IDs
      const friendIds = new Set<string>();
      friendships1.docs.forEach(doc => friendIds.add(doc.data().user2Id));
      friendships2.docs.forEach(doc => friendIds.add(doc.data().user1Id));
      friendIds.add(userId); // Include self

      // Fetch user profiles
      const userPromises = Array.from(friendIds).map(id =>
        db.collection("users").doc(id).get()
      );
      const userDocs = await Promise.all(userPromises);

      // Build and sort leaderboard entries
      const entries = userDocs
        .filter(doc => doc.exists)
        .map(doc => ({
          odUserId: doc.id,
          username: doc.data()!.username,
          profilePictureUrl: doc.data()!.profilePictureUrl || null,
          level: doc.data()!.level || 1,
          totalXp: doc.data()!.totalXp || 0,
        }))
        .sort((a, b) => b.totalXp - a.totalXp)
        .map((entry, index) => ({ ...entry, rank: index + 1 }));

      return { entries };
    } catch (error) {
      console.error("Get friends leaderboard error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to get friends leaderboard: ${error}`
      );
    }
  }
);

// ============ WIDGET TIPS ============

export const getRandomTip = functions.https.onCall(
  async (data: { examType?: string; category?: string } | null) => {
    try {
      let query: admin.firestore.Query = db.collection("widgetTips");

      // Apply filters if provided
      if (data?.examType && data.examType !== "Both") {
        query = query.where("examType", "in", [data.examType, "Both"]);
      }

      if (data?.category) {
        query = query.where("category", "==", data.category);
      }

      const tipsSnapshot = await query.get();

      if (tipsSnapshot.empty) {
        return { tip: "Practice makes perfect!", category: "strategy", examType: "Both" };
      }

      const tips = tipsSnapshot.docs.map((doc) => ({
        tip: doc.data().tip as string,
        category: doc.data().category as string || "strategy",
        examType: doc.data().examType as string || "Both",
      }));

      const randomTip = tips[Math.floor(Math.random() * tips.length)];

      return randomTip;
    } catch (error) {
      console.error("Get tip error:", error);
      return { tip: "Study hard, score high!", category: "strategy", examType: "Both" };
    }
  }
);

// ============ SEED DATA FUNCTIONS ============

// Enhanced tip structure with categories
interface WidgetTip {
  tip: string;
  category: "desmos" | "grammar" | "math" | "science" | "reading" | "strategy" | "time";
  examType: "SAT" | "ACT" | "Both";
}

// Comprehensive tips database
const WIDGET_TIPS: WidgetTip[] = [
  // ==================== DESMOS CALCULATOR TIPS ====================
  { tip: "Desmos: Type 'y=mx+b' and use sliders for m and b to visualize slope and y-intercept instantly.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Graph both sides of an equation separately (y=left side, y=right side) to find intersection points.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Use the table feature (click on a graph) to find exact y-values for any x you input.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Type 'x^2+y^2=r^2' to graph a circle with radius r centered at origin.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: For quadratics, type 'y=a(x-h)^2+k' with sliders to find vertex form parameters.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Use {domain restrictions} like 'y=x^2 {x>0}' to graph only part of a function.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Click the wrench icon to adjust x/y axis ranges for better graph visibility.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Type 'f(x)=' to define a function, then use f(2) to evaluate at specific points.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Graph systems of inequalities to visualize feasible regions—shaded overlap is your answer.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: For absolute value, type 'y=|x-a|+b' to see the V-shape and vertex at (a,b).", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Use regression by typing a list of points like (1,2),(3,5),(4,7) then y1~mx1+b for best fit.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: To solve systems, graph both equations and click the intersection point for coordinates.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Type 'sqrt(x)' for square root graphs, 'nthroot(x,3)' for cube roots.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: Use 'y=e^x' and 'y=ln(x)' for exponential and logarithmic functions.", category: "desmos", examType: "SAT" },
  { tip: "Desmos: For piecewise functions, use conditions: 'y={x<0: -x, x>=0: x^2}'.", category: "desmos", examType: "SAT" },

  // ==================== GRAMMAR/ENGLISH RULES ====================
  { tip: "Grammar: 'Who' is for subjects (who did it), 'whom' is for objects (to whom).", category: "grammar", examType: "Both" },
  { tip: "Grammar: A comma splice (two sentences joined by just a comma) is ALWAYS wrong. Use a period or semicolon.", category: "grammar", examType: "Both" },
  { tip: "Grammar: 'Less' = uncountable (less water), 'fewer' = countable (fewer bottles).", category: "grammar", examType: "Both" },
  { tip: "Grammar: Parallel structure—items in a list must match in form (running, jumping, swimming).", category: "grammar", examType: "Both" },
  { tip: "Grammar: 'Its' = possessive (the dog wagged its tail), 'it's' = it is.", category: "grammar", examType: "Both" },
  { tip: "Grammar: Subject-verb agreement—find the true subject, ignoring prepositional phrases between.", category: "grammar", examType: "Both" },
  { tip: "Grammar: Dangling modifiers: The phrase at the start of the sentence must describe the subject that follows.", category: "grammar", examType: "Both" },
  { tip: "Grammar: Use a colon after a complete sentence to introduce a list or explanation.", category: "grammar", examType: "Both" },
  { tip: "Grammar: Semicolons connect two independent clauses without a conjunction.", category: "grammar", examType: "Both" },
  { tip: "Grammar: 'Affect' is usually a verb (to affect), 'effect' is usually a noun (the effect).", category: "grammar", examType: "Both" },
  { tip: "Grammar: Apostrophes show possession (John's book) or contraction (can't), never plurals.", category: "grammar", examType: "Both" },
  { tip: "Grammar: 'Between' = two things, 'among' = three or more.", category: "grammar", examType: "Both" },
  { tip: "Grammar: 'Which' introduces non-essential clauses (use commas), 'that' introduces essential ones.", category: "grammar", examType: "Both" },
  { tip: "Grammar: Avoid redundancy—'past history' or 'advance planning' have unnecessary words.", category: "grammar", examType: "Both" },
  { tip: "Grammar: The shortest answer is often correct if it's grammatically complete and clear.", category: "grammar", examType: "Both" },
  { tip: "Grammar: 'Lay' needs an object (lay the book down), 'lie' doesn't (lie down).", category: "grammar", examType: "Both" },
  { tip: "Grammar: Use commas to separate introductory phrases from the main clause.", category: "grammar", examType: "Both" },
  { tip: "Grammar: Pronoun agreement—a singular antecedent needs a singular pronoun.", category: "grammar", examType: "Both" },
  { tip: "Grammar: In comparisons, compare like items: 'My car's speed' vs. 'your car's speed', not 'your car'.", category: "grammar", examType: "Both" },
  { tip: "Grammar: 'Could of' is ALWAYS wrong—it's 'could have' or 'could've'.", category: "grammar", examType: "Both" },

  // ==================== MATH FORMULAS & STRATEGIES ====================
  { tip: "Math: Slope formula: m = (y2-y1)/(x2-x1). Rise over run.", category: "math", examType: "Both" },
  { tip: "Math: Distance formula: d = sqrt[(x2-x1)^2 + (y2-y1)^2]. Based on Pythagorean theorem.", category: "math", examType: "Both" },
  { tip: "Math: Midpoint formula: ((x1+x2)/2, (y1+y2)/2). Just average the coordinates.", category: "math", examType: "Both" },
  { tip: "Math: Quadratic formula: x = (-b +/- sqrt(b^2-4ac)) / 2a. Memorize it!", category: "math", examType: "Both" },
  { tip: "Math: FOIL for binomials: (a+b)(c+d) = ac + ad + bc + bd.", category: "math", examType: "Both" },
  { tip: "Math: Difference of squares: a^2 - b^2 = (a+b)(a-b).", category: "math", examType: "Both" },
  { tip: "Math: Perfect square trinomial: a^2 + 2ab + b^2 = (a+b)^2.", category: "math", examType: "Both" },
  { tip: "Math: Area of a triangle = (1/2) x base x height.", category: "math", examType: "Both" },
  { tip: "Math: Area of a circle = pi x r^2. Circumference = 2 x pi x r.", category: "math", examType: "Both" },
  { tip: "Math: Pythagorean theorem: a^2 + b^2 = c^2. Common triples: 3-4-5, 5-12-13, 8-15-17.", category: "math", examType: "Both" },
  { tip: "Math: Special right triangles: 45-45-90 has sides 1:1:sqrt(2). 30-60-90 has sides 1:sqrt(3):2.", category: "math", examType: "Both" },
  { tip: "Math: Percent change = (New - Old) / Old x 100.", category: "math", examType: "Both" },
  { tip: "Math: Distance = Rate x Time. Rearrange to find any variable.", category: "math", examType: "Both" },
  { tip: "Math: Average (mean) = Sum of values / Number of values.", category: "math", examType: "Both" },
  { tip: "Math: For word problems, define variables first and write equations from the given info.", category: "math", examType: "Both" },
  { tip: "Math: When stuck, plug in answer choices starting with C (middle value).", category: "math", examType: "Both" },
  { tip: "Math: For 'must be true' questions, try plugging in weird numbers like 0, 1, negatives, fractions.", category: "math", examType: "Both" },
  { tip: "Math: Vertex of a parabola y=ax^2+bx+c is at x = -b/(2a).", category: "math", examType: "Both" },
  { tip: "Math: Sum of angles in a triangle = 180. In a polygon with n sides, it's (n-2) x 180.", category: "math", examType: "Both" },
  { tip: "Math: Parallel lines have equal slopes. Perpendicular lines have slopes that multiply to -1.", category: "math", examType: "Both" },
  { tip: "Math: For exponential growth/decay: y = a(1+r)^t for growth, y = a(1-r)^t for decay.", category: "math", examType: "Both" },
  { tip: "Math: The discriminant b^2-4ac tells you: >0 = two solutions, =0 = one, <0 = none (real).", category: "math", examType: "Both" },
  { tip: "Math: Arc length = (central angle / 360) x 2 x pi x r.", category: "math", examType: "Both" },
  { tip: "Math: Sector area = (central angle / 360) x pi x r^2.", category: "math", examType: "Both" },
  { tip: "Math: Volume of a cylinder = pi x r^2 x h. Surface area = 2 x pi x r x h + 2 x pi x r^2.", category: "math", examType: "Both" },

  // ==================== ACT SCIENCE STRATEGIES ====================
  { tip: "Science (ACT): Read the graphs and tables FIRST. Most answers come directly from the data.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): Pay close attention to axis labels and units—they're often the key to the question.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): For conflicting viewpoints, identify what each scientist/student AGREES on first.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): Don't get intimidated by complex scientific terminology—focus on the relationships in data.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): Look for trends: as X increases, does Y increase, decrease, or stay the same?", category: "science", examType: "ACT" },
  { tip: "Science (ACT): For experiment questions, identify the independent (changed) and dependent (measured) variables.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): Control groups show what happens without the experimental treatment.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): In data tables, look for patterns in columns and rows before answering.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): When comparing experiments, find what variables were held constant vs. changed.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): For 'if...then' questions, trace the logic using the given data relationships.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): Skip the passage intro if short on time—go straight to figures and questions.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): Interpolate (read between points) and extrapolate (extend trends) carefully.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): For conflicting viewpoints, underline each viewpoint's main claim.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): 'According to the passage' = answer is stated directly. 'Based on' = you may need to infer.", category: "science", examType: "ACT" },
  { tip: "Science (ACT): Practice reading scientific graphs quickly—bar charts, line graphs, scatter plots.", category: "science", examType: "ACT" },

  // ==================== READING STRATEGIES ====================
  { tip: "Reading: Read the questions first (or at least skim them) to know what to look for.", category: "reading", examType: "Both" },
  { tip: "Reading: For main idea questions, focus on the first and last paragraphs.", category: "reading", examType: "Both" },
  { tip: "Reading: Underline or mentally note topic sentences—usually the first sentence of each paragraph.", category: "reading", examType: "Both" },
  { tip: "Reading: Extreme answer choices with 'always', 'never', 'all', 'none' are usually wrong.", category: "reading", examType: "Both" },
  { tip: "Reading: The correct answer is supported by TEXT EVIDENCE. If you can't point to it, it's probably wrong.", category: "reading", examType: "Both" },
  { tip: "Reading: Pay attention to transition words: 'however', 'therefore', 'in contrast', 'similarly'.", category: "reading", examType: "Both" },
  { tip: "Reading: For inference questions, the answer should be strongly implied, not a huge logical leap.", category: "reading", examType: "Both" },
  { tip: "Reading: Author's tone: look for emotional or evaluative words (criticizes, praises, questions).", category: "reading", examType: "Both" },
  { tip: "Reading: In paired passages, first understand each passage alone, then compare.", category: "reading", examType: "Both" },
  { tip: "Reading: For vocabulary in context, re-read the sentence with each answer choice plugged in.", category: "reading", examType: "Both" },
  { tip: "Reading: 'Purpose' questions ask WHY the author included something—think about the argument structure.", category: "reading", examType: "Both" },
  { tip: "Reading: Annotate as you read—mark key claims, evidence, and shifts in argument.", category: "reading", examType: "Both" },
  { tip: "Reading: For data-based reading questions, check if the graph/table supports or contradicts the text.", category: "reading", examType: "Both" },
  { tip: "Reading: Don't bring outside knowledge—answer based only on what the passage says.", category: "reading", examType: "Both" },
  { tip: "Reading: For 'best evidence' questions, find the quote that directly supports your previous answer.", category: "reading", examType: "SAT" },

  // ==================== GENERAL TEST-TAKING STRATEGIES ====================
  { tip: "Strategy: Answer every question—there's no penalty for guessing on the SAT or ACT.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Process of elimination is your best friend. Cross out wrong answers to improve odds.", category: "strategy", examType: "Both" },
  { tip: "Strategy: If two answers seem very similar, one of them is probably the right answer.", category: "strategy", examType: "Both" },
  { tip: "Strategy: When stuck between two choices, re-read the question to catch what you might have missed.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Mark questions you're unsure about and come back if you have time.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Read the ENTIRE question before looking at answers. Many errors come from misreading.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Trust your first instinct unless you have a clear reason to change your answer.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Don't overthink—the SAT and ACT test reasoning, not trick questions.", category: "strategy", examType: "Both" },
  { tip: "Strategy: For questions asking 'which is NOT', eliminate the three that ARE true.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Bubble in groups of 5-10 answers at once to save time on page flipping.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Skip hard questions and come back—don't lose easy points by running out of time.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Review flagged questions if you finish early. Fresh eyes often catch mistakes.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Read answer choices from bottom to top occasionally—you might catch the right answer faster.", category: "strategy", examType: "Both" },
  { tip: "Strategy: If an answer seems too easy, it might actually be correct. Don't overthink.", category: "strategy", examType: "Both" },
  { tip: "Strategy: Use your test booklet for scratch work—it's there for a reason.", category: "strategy", examType: "Both" },

  // ==================== TIME MANAGEMENT ====================
  { tip: "Time: SAT Reading: ~13 min per passage (5 passages, 65 min total).", category: "time", examType: "SAT" },
  { tip: "Time: SAT Writing: ~9 min per passage (4 passages, 35 min total).", category: "time", examType: "SAT" },
  { tip: "Time: SAT Math No-Calc: ~1.5 min per question (20 questions, 25 min).", category: "time", examType: "SAT" },
  { tip: "Time: SAT Math Calculator: ~1.5 min per question (38 questions, 55 min).", category: "time", examType: "SAT" },
  { tip: "Time: ACT English: ~36 seconds per question (75 questions, 45 min).", category: "time", examType: "ACT" },
  { tip: "Time: ACT Math: ~1 min per question (60 questions, 60 min).", category: "time", examType: "ACT" },
  { tip: "Time: ACT Reading: ~8.75 min per passage (4 passages, 35 min total).", category: "time", examType: "ACT" },
  { tip: "Time: ACT Science: ~5 min per passage (6-7 passages, 35 min total).", category: "time", examType: "ACT" },
  { tip: "Time: Wear a watch (non-smart) and check time after every passage or section.", category: "time", examType: "Both" },
  { tip: "Time: Set mini-deadlines for each passage. If you're behind, speed up on easier questions.", category: "time", examType: "Both" },
  { tip: "Time: Save 2-3 minutes at the end of each section to review flagged questions.", category: "time", examType: "Both" },
  { tip: "Time: If a question takes more than 2 minutes, mark it and move on.", category: "time", examType: "Both" },
  { tip: "Time: Easy questions are worth the same as hard ones. Get the easy points first!", category: "time", examType: "Both" },
  { tip: "Time: Practice with a timer to build your internal sense of pacing.", category: "time", examType: "Both" },
  { tip: "Time: If you're running out of time, make educated guesses—never leave blanks.", category: "time", examType: "Both" },
];

export const seedWidgetTips = functions.https.onRequest(async (req, res) => {
  if (!requireAdminSecret(req, res)) return;
  try {
    // Delete existing tips first to avoid duplicates
    const existingTips = await db.collection("widgetTips").get();
    const deletePromises = existingTips.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);

    // Use multiple batches since we have more than 500 tips potentially
    const batchSize = 500;
    let batch = db.batch();
    let operationCount = 0;

    for (const tipData of WIDGET_TIPS) {
      const docRef = db.collection("widgetTips").doc();
      batch.set(docRef, {
        tip: tipData.tip,
        category: tipData.category,
        examType: tipData.examType,
        createdAt: FieldValue.serverTimestamp(),
      });
      operationCount++;

      if (operationCount >= batchSize) {
        await batch.commit();
        batch = db.batch();
        operationCount = 0;
      }
    }

    // Commit any remaining operations
    if (operationCount > 0) {
      await batch.commit();
    }

    res.status(200).send({
      success: true,
      count: WIDGET_TIPS.length,
      categories: {
        desmos: WIDGET_TIPS.filter(t => t.category === "desmos").length,
        grammar: WIDGET_TIPS.filter(t => t.category === "grammar").length,
        math: WIDGET_TIPS.filter(t => t.category === "math").length,
        science: WIDGET_TIPS.filter(t => t.category === "science").length,
        reading: WIDGET_TIPS.filter(t => t.category === "reading").length,
        strategy: WIDGET_TIPS.filter(t => t.category === "strategy").length,
        time: WIDGET_TIPS.filter(t => t.category === "time").length,
      },
    });
  } catch (error) {
    console.error("Seed tips error:", error);
    res.status(500).send({ error: "Failed to seed tips" });
  }
});

/**
 * Get the tip of the day based on the current date.
 * This ensures all users see the same tip on any given day.
 */
export const getTipOfTheDay = functions.https.onCall(
  async (data: { examType?: string; category?: string }, context) => {
    try {
      // Build query based on filters
      let query: admin.firestore.Query = db.collection("widgetTips");

      if (data.examType && data.examType !== "Both") {
        // Get tips for specific exam type OR tips applicable to both
        query = query.where("examType", "in", [data.examType, "Both"]);
      }

      if (data.category) {
        query = query.where("category", "==", data.category);
      }

      const tipsSnapshot = await query.get();

      if (tipsSnapshot.empty) {
        return { tip: "Practice makes perfect!", category: "strategy", examType: "Both" };
      }

      const tips = tipsSnapshot.docs.map(doc => ({
        tip: doc.data().tip as string,
        category: doc.data().category as string,
        examType: doc.data().examType as string,
      }));

      // Use the day of the year to select a tip (deterministic for each day)
      const now = new Date();
      const startOfYear = new Date(now.getFullYear(), 0, 0);
      const diff = now.getTime() - startOfYear.getTime();
      const dayOfYear = Math.floor(diff / (1000 * 60 * 60 * 24));

      const selectedTip = tips[dayOfYear % tips.length];

      return selectedTip;
    } catch (error) {
      console.error("Get tip of the day error:", error);
      return { tip: "Study hard, score high!", category: "strategy", examType: "Both" };
    }
  }
);

/**
 * Get tips filtered by category and/or exam type.
 */
export const getTipsByFilter = functions.https.onCall(
  async (data: { examType?: string; category?: string; limit?: number }, context) => {
    try {
      let query: admin.firestore.Query = db.collection("widgetTips");

      if (data.examType && data.examType !== "Both") {
        query = query.where("examType", "in", [data.examType, "Both"]);
      }

      if (data.category) {
        query = query.where("category", "==", data.category);
      }

      const limit = data.limit || 10;
      query = query.limit(limit);

      const tipsSnapshot = await query.get();

      const tips = tipsSnapshot.docs.map(doc => ({
        id: doc.id,
        tip: doc.data().tip,
        category: doc.data().category,
        examType: doc.data().examType,
      }));

      return { tips };
    } catch (error) {
      console.error("Get tips by filter error:", error);
      return { tips: [] };
    }
  }
);

export const seedAchievements = functions.https.onRequest(async (req, res) => {
  if (!requireAdminSecret(req, res)) return;
  const achievements = [
    { id: "first_steps", name: "First Steps", description: "Answer 10 questions", emoji: "👶", category: "questions", requirement: 10, bonusXp: 25 },
    { id: "century", name: "Century", description: "Answer 100 questions", emoji: "💯", category: "questions", requirement: 100, bonusXp: 100 },
    { id: "dedicated", name: "Dedicated", description: "Answer 500 questions", emoji: "📚", category: "questions", requirement: 500, bonusXp: 250 },
    { id: "master", name: "Master", description: "Answer 1000 questions", emoji: "🎓", category: "questions", requirement: 1000, bonusXp: 500 },
    { id: "week_warrior", name: "Week Warrior", description: "7 day study streak", emoji: "🔥", category: "streaks", requirement: 7, bonusXp: 75 },
    { id: "month_champion", name: "Month Champion", description: "30 day study streak", emoji: "🌟", category: "streaks", requirement: 30, bonusXp: 300 },
    { id: "unstoppable", name: "Unstoppable", description: "100 day study streak", emoji: "💪", category: "streaks", requirement: 100, bonusXp: 1000 },
    { id: "sharpshooter", name: "Sharpshooter", description: "10 correct answers in a row", emoji: "🎯", category: "accuracy", requirement: 10, bonusXp: 50 },
    { id: "perfectionist", name: "Perfectionist", description: "20 correct answers in a row", emoji: "⚡", category: "accuracy", requirement: 20, bonusXp: 100 },
    { id: "flawless", name: "Flawless", description: "50 correct answers in a row", emoji: "💎", category: "accuracy", requirement: 50, bonusXp: 300 },
    { id: "battle_ready", name: "Battle Ready", description: "Complete 1 battle", emoji: "⚔️", category: "battles", requirement: 1, bonusXp: 25 },
    { id: "victor", name: "Victor", description: "Win 10 battles", emoji: "🏆", category: "battles", requirement: 10, bonusXp: 100 },
    { id: "champion", name: "Champion", description: "Win 50 battles", emoji: "👑", category: "battles", requirement: 50, bonusXp: 300 },
    { id: "legend", name: "Legend", description: "Win 100 battles", emoji: "🌈", category: "battles", requirement: 100, bonusXp: 500 },
    { id: "rising_star", name: "Rising Star", description: "Reach Level 5", emoji: "⭐", category: "level", requirement: 5, bonusXp: 50 },
    { id: "expert", name: "Expert", description: "Reach Level 20", emoji: "🎓", category: "level", requirement: 20, bonusXp: 200 },
    { id: "titan", name: "Titan", description: "Reach Level 50", emoji: "🔱", category: "level", requirement: 50, bonusXp: 500 },
    { id: "social_butterfly", name: "Social Butterfly", description: "Add 5 friends", emoji: "🦋", category: "social", requirement: 5, bonusXp: 50 },
    { id: "influencer", name: "Influencer", description: "Add 20 friends", emoji: "🤳", category: "social", requirement: 20, bonusXp: 200 },
  ];

  try {
    const batch = db.batch();

    for (const achievement of achievements) {
      const docRef = db.collection("achievements").doc(achievement.id);
      batch.set(docRef, {
        ...achievement,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    res.status(200).send({ success: true, count: achievements.length });
  } catch (error) {
    console.error("Seed achievements error:", error);
    res.status(500).send({ error: "Failed to seed achievements" });
  }
});

// ============ FRIEND CODE MIGRATION ============

// Characters for friend code (excluding 0, O, 1, I for clarity)
const FRIEND_CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

/**
 * Generate a random 8-character friend code.
 */
function generateFriendCode(): string {
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += FRIEND_CODE_CHARS.charAt(
      Math.floor(Math.random() * FRIEND_CODE_CHARS.length)
    );
  }
  return code;
}

/**
 * Generate a unique friend code, checking for collisions.
 */
async function generateUniqueFriendCode(): Promise<string> {
  const maxAttempts = 10;
  for (let i = 0; i < maxAttempts; i++) {
    const code = generateFriendCode();
    const existing = await db.collection("users")
      .where("friendCode", "==", code)
      .limit(1)
      .get();
    if (existing.empty) {
      return code;
    }
  }
  throw new Error(`Failed to generate unique friend code after ${maxAttempts} attempts`);
}

/**
 * Migration function to assign friend codes to existing users without one.
 * Run this once after deploying the friend code feature.
 * HTTP endpoint for admin use.
 */
export const migrateFriendCodes = functions.https.onRequest(async (req, res) => {
  if (!requireAdminSecret(req, res)) return;
  try {
    // Get all users without a friend code
    const usersSnapshot = await db.collection("users").get();

    let migratedCount = 0;
    let skippedCount = 0;
    const errors: string[] = [];

    // Process in batches of 500 (Firestore batch limit)
    const batchSize = 500;
    let batch = db.batch();
    let batchCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();

      // Skip if user already has a friend code
      if (userData.friendCode) {
        skippedCount++;
        continue;
      }

      try {
        const friendCode = await generateUniqueFriendCode();
        batch.update(userDoc.ref, {
          friendCode,
          updatedAt: FieldValue.serverTimestamp(),
        });
        batchCount++;
        migratedCount++;

        // Commit batch when full
        if (batchCount >= batchSize) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }
      } catch (error) {
        errors.push(`Failed to migrate user ${userDoc.id}: ${error}`);
      }
    }

    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`Friend code migration complete: ${migratedCount} migrated, ${skippedCount} skipped`);

    res.status(200).send({
      success: true,
      migratedCount,
      skippedCount,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (error) {
    console.error("Friend code migration error:", error);
    res.status(500).send({ error: `Migration failed: ${error}` });
  }
});

/**
 * Get the current user's friend code.
 * If the user doesn't have one (pre-migration), generate one.
 */
export const getMyFriendCode = wrapAsCallable(
  async (_data, { userId }) => {

    try {
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User not found"
        );
      }

      const userData = userDoc.data()!;

      // If user already has a friend code, return it
      if (userData.friendCode) {
        return { friendCode: userData.friendCode };
      }

      // Generate a new friend code for this user (lazy migration)
      const friendCode = await generateUniqueFriendCode();
      await userDoc.ref.update({
        friendCode,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { friendCode };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Get friend code error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to get friend code: ${error}`
      );
    }
  }
);

// ============ TEST QUESTION SEEDING ============

/**
 * Generate test questions on-demand for immediate testing.
 * HTTP endpoint that generates questions for all sections without waiting for scheduled generation.
 *
 * Query params:
 * - examType: "SAT", "ACT", or "BOTH" (default: "BOTH")
 * - questionsPerSection: number of questions per section (default: 50)
 *
 * Example: /seedTestQuestions?examType=SAT&questionsPerSection=50
 */
export const seedTestQuestions = onRequest(
  { timeoutSeconds: 540, memory: "1GiB" },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    // Parse parameters
    const examTypeParam = (req.query.examType as string || "BOTH").toUpperCase();
    const questionsPerSection = parseInt(req.query.questionsPerSection as string || "50", 10);

    if (!["SAT", "ACT", "BOTH"].includes(examTypeParam)) {
      res.status(400).send({ error: "examType must be SAT, ACT, or BOTH" });
      return;
    }

    if (questionsPerSection < 1 || questionsPerSection > 100) {
      res.status(400).send({ error: "questionsPerSection must be between 1 and 100" });
      return;
    }

    const examTypes: Array<"SAT" | "ACT"> = examTypeParam === "BOTH"
      ? ["SAT", "ACT"]
      : [examTypeParam as "SAT" | "ACT"];

    console.log(`Starting test question generation: ${examTypes.join(", ")}, ${questionsPerSection} per section`);

    const results: Record<string, {
      section: string;
      attempted: number;
      generated: number;
      written: number;
      errors: string[];
    }> = {};

    try {
      for (const examType of examTypes) {
        const examConfig = QUESTION_CONFIG[examType];
        const sections = Object.keys(examConfig) as Array<keyof typeof examConfig>;

        for (const section of sections) {
          const sectionConfig = examConfig[section];
          const skills = sectionConfig.skills;
          const sectionKey = `${examType}-${section}`;

          console.log(`\n--- Generating for ${sectionKey} ---`);

          results[sectionKey] = {
            section: `${examType} ${section}`,
            attempted: 0,
            generated: 0,
            written: 0,
            errors: []
          };

          // Calculate questions per skill (distribute evenly)
          const questionsPerSkill = Math.max(1, Math.floor(questionsPerSection / skills.length));
          const remainder = questionsPerSection - (questionsPerSkill * skills.length);

          for (let i = 0; i < skills.length; i++) {
            const skill = skills[i];
            // Give extra questions to first skills to reach total
            const count = questionsPerSkill + (i < remainder ? 1 : 0);

            if (count <= 0) continue;

            results[sectionKey].attempted += count;

            try {
              console.log(`Generating ${count} questions for ${examType}/${section}/${skill}...`);

              // Generate questions using Gemini
              const questions = await generateQuestionsWithGemini(
                examType,
                section,
                skill,
                count
              );

              results[sectionKey].generated += questions.length;

              // Write to Firestore (deduplication happens automatically)
              const { written, skipped } = await writeQuestionsToFirestore(
                questions,
                "gemini-1.5-flash-001"
              );

              results[sectionKey].written += written;

              console.log(`  ✓ ${skill}: ${questions.length} generated, ${written} written, ${skipped} duplicates`);

              // Log the generation run
              await logGenerationRun(
                examType,
                section,
                skill,
                count,
                questions.length,
                written,
                skipped
              );

              // Small delay between skills to avoid rate limiting
              await new Promise(resolve => setTimeout(resolve, 1000));

            } catch (error) {
              const errorMsg = `${skill}: ${error}`;
              results[sectionKey].errors.push(errorMsg);
              console.error(`  ✗ ${errorMsg}`);

              // Log failed generation
              await logGenerationRun(
                examType,
                section,
                skill,
                count,
                0,
                0,
                0,
                String(error)
              );
            }
          }
        }
      }

      // Calculate totals
      const totals = {
        attempted: 0,
        generated: 0,
        written: 0,
        sections: Object.keys(results).length,
        sectionsWithErrors: 0
      };

      for (const result of Object.values(results)) {
        totals.attempted += result.attempted;
        totals.generated += result.generated;
        totals.written += result.written;
        if (result.errors.length > 0) {
          totals.sectionsWithErrors++;
        }
      }

      console.log(`\n=== GENERATION COMPLETE ===`);
      console.log(`Total: ${totals.generated} generated, ${totals.written} written`);

      res.status(200).send({
        success: true,
        totals,
        sections: results
      });

    } catch (error) {
      console.error("Seed test questions error:", error);
      res.status(500).send({
        error: `Failed to seed test questions: ${error}`,
        partialResults: results
      });
    }
  });

// ============ USER ACCOUNT MANAGEMENT ============

/**
 * Delete user account and all associated data (GDPR compliance)
 * Deletes: user profile, friendships, battle results, notification logs, answers
 */
export const deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to delete your account"
    );
  }

  const userId = context.auth.uid;

  try {
    console.log(`Starting account deletion for user ${userId}`);

    // Delete user data in parallel
    const deletePromises = [];

    // 1. Delete user document
    deletePromises.push(db.collection("users").doc(userId).delete());

    // 2. Delete all friendships involving this user
    const friendshipsQuery = db.collection("friendships")
      .where("user1Id", "==", userId);
    const friendshipsQuery2 = db.collection("friendships")
      .where("user2Id", "==", userId);

    deletePromises.push(
      friendshipsQuery.get().then(snapshot => {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        return batch.commit();
      })
    );

    deletePromises.push(
      friendshipsQuery2.get().then(snapshot => {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        return batch.commit();
      })
    );

    // 3. Delete battle results
    const battleResultsQuery = db.collection("battleResults")
      .where("player1Id", "==", userId);
    const battleResultsQuery2 = db.collection("battleResults")
      .where("player2Id", "==", userId);

    deletePromises.push(
      battleResultsQuery.get().then(snapshot => {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        return batch.commit();
      })
    );

    deletePromises.push(
      battleResultsQuery2.get().then(snapshot => {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        return batch.commit();
      })
    );

    // 4. Delete notification logs
    const notificationLogsQuery = db.collection("notificationLogs")
      .where("userId", "==", userId);

    deletePromises.push(
      notificationLogsQuery.get().then(snapshot => {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        return batch.commit();
      })
    );

    // 5. Delete user answers
    const userAnswersQuery = db.collection("userAnswers")
      .where("userId", "==", userId);

    deletePromises.push(
      userAnswersQuery.get().then(snapshot => {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        return batch.commit();
      })
    );

    // 6. Delete leaderboard entries
    const leaderboardsSnapshot = await db.collection("leaderboards").get();
    for (const leaderboardDoc of leaderboardsSnapshot.docs) {
      deletePromises.push(
        db.collection("leaderboards")
          .doc(leaderboardDoc.id)
          .collection("entries")
          .doc(userId)
          .delete()
      );
    }

    // 7. Delete active battles from Realtime Database
    const battleSnapshot = await rtdb.ref("battles")
      .orderByChild("player1/id")
      .equalTo(userId)
      .once("value");

    const deleteBattlePromises: Promise<void>[] = [];
    battleSnapshot.forEach(child => {
      deleteBattlePromises.push(rtdb.ref(`battles/${child.key}`).remove());
    });

    const battleSnapshot2 = await rtdb.ref("battles")
      .orderByChild("player2/id")
      .equalTo(userId)
      .once("value");

    battleSnapshot2.forEach(child => {
      deleteBattlePromises.push(rtdb.ref(`battles/${child.key}`).remove());
    });

    // 8. Remove from matchmaking queue
    deletePromises.push(rtdb.ref(`matchmaking/${userId}`).remove());

    // Wait for all deletions
    await Promise.all([...deletePromises, ...deleteBattlePromises]);

    // 9. Delete Firebase Auth account (must be last)
    await admin.auth().deleteUser(userId);

    console.log(`Account deletion completed for user ${userId}`);

    return {
      success: true,
      message: "Your account and all associated data have been permanently deleted"
    };

  } catch (error) {
    console.error(`Error deleting account for user ${userId}:`, error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to delete account. Please try again or contact support."
    );
  }
});

// ============ NOTIFICATION SCHEDULED FUNCTIONS ============

/**
 * Daily streak warning check - runs at 11 PM UTC
 * Checks users with active streaks who haven't studied today
 */
export const sendStreakWarnings = onSchedule(
  { schedule: "0 23 * * *", timeZone: "UTC" },
  async (_event) => {
    console.log("Starting streak warning notifications...");

    try {
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      // Get users with active streaks (count > 0)
      const usersSnapshot = await db.collection("users")
        .where("dailyStreak.count", ">", 0)
        .get();

      let sentCount = 0;
      const promises: Promise<void>[] = [];

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const streak = userData.dailyStreak || {};
        const lastDate = streak.lastDate?.toDate();

        // Check if user hasn't studied today
        if (!lastDate || lastDate < todayStart) {
          const streakDays = streak.count || 0;
          if (streakDays > 0) {
            promises.push(
              sendStreakWarningNotification(userDoc.id, streakDays)
            );
            sentCount++;
          }
        }
      }

      await Promise.allSettled(promises);
      console.log(`Sent ${sentCount} streak warning notifications`);
    } catch (error) {
      console.error("Streak warning error:", error);
    }
  }
);

/**
 * Daily study reminder - runs every hour
 * Sends reminders to users at their preferred time (default 2 PM local time)
 * Simplified approach: sends at 2 PM UTC and tracks last sent date
 */
export const sendDailyReminders = onSchedule(
  { schedule: "0 14 * * *", timeZone: "UTC" },
  async (_event) => {
    console.log("Starting daily reminder notifications...");

    try {
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      // Get all users who haven't received a reminder today
      const usersSnapshot = await db.collection("users").get();

      let sentCount = 0;
      const promises: Promise<void>[] = [];

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const lastReminderSent = userData.lastDailyReminderSent?.toDate();
        const reminderTime = userData.notificationPreferences?.dailyReminderTime || 14;

        // Skip if reminder already sent today
        if (lastReminderSent && lastReminderSent >= todayStart) {
          continue;
        }

        // For simplified approach, send to everyone at 2 PM UTC
        // In production, you'd check user's time zone and preferred hour
        if (reminderTime === now.getUTCHours()) {
          promises.push(
            sendDailyReminderNotification(userDoc.id).then(async () => {
              // Update last reminder sent time
              await db.collection("users").doc(userDoc.id).update({
                lastDailyReminderSent: FieldValue.serverTimestamp(),
              });
            })
          );
          sentCount++;
        }
      }

      await Promise.allSettled(promises);
      console.log(`Sent ${sentCount} daily reminder notifications`);
    } catch (error) {
      console.error("Daily reminder error:", error);
    }
  }
);
