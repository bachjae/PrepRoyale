/**
 * Notification Helper for Firebase Cloud Messaging
 * Handles sending push notifications to users via FCM
 */

import * as admin from "firebase-admin";

/**
 * Get Firestore instance (lazy initialization)
 */
function getDb() {
  return admin.firestore();
}

/**
 * Notification types supported by the system
 */
export type NotificationType =
  | "friend_request"
  | "battle_invite"
  | "friend_request_accepted"
  | "streak_warning"
  | "daily_reminder"
  | "achievement"
  | "leaderboard";

/**
 * Send a push notification to a user
 * @param userId - Target user ID
 * @param title - Notification title
 * @param body - Notification body
 * @param type - Notification type for routing
 * @param data - Additional data payload
 */
export async function sendNotification(
  userId: string,
  title: string,
  body: string,
  type: NotificationType,
  data?: Record<string, string>
): Promise<void> {
  try {
    // Get user document to check FCM token and preferences
    const userDoc = await getDb().collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.warn(`User ${userId} not found for notification`);
      return;
    }

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken as string | undefined;
    const preferences = userData.notificationPreferences || {};

    // Check if user has FCM token
    if (!fcmToken) {
      console.log(`User ${userId} has no FCM token, skipping notification`);
      return;
    }

    // Check if notification type is enabled in user preferences
    if (!isNotificationEnabled(type, preferences)) {
      console.log(`Notification type ${type} disabled for user ${userId}`);
      return;
    }

    // Construct FCM message
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        type,
        ...(data || {}),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "prep_royale_notifications",
          priority: "high",
          sound: "default",
        },
      },
    };

    // Send notification
    const response = await admin.messaging().send(message);
    console.log(`Notification sent to ${userId}: ${response}`);

    // Log notification in Firestore
    await logNotification(userId, type, title, body, data);
  } catch (error) {
    if ((error as any).code === "messaging/registration-token-not-registered") {
      console.warn(`Invalid FCM token for user ${userId}, clearing token`);
      // Clear invalid token
      await getDb().collection("users").doc(userId).update({
        fcmToken: admin.firestore.FieldValue.delete(),
      });
    } else {
      console.error(`Error sending notification to ${userId}:`, error);
    }
  }
}

/**
 * Check if a notification type is enabled for user
 */
function isNotificationEnabled(
  type: NotificationType,
  preferences: Record<string, any>
): boolean {
  const prefMap: Record<NotificationType, string> = {
    friend_request: "friendRequests",
    battle_invite: "friendBattleInvites",
    friend_request_accepted: "friendRequestAccepted",
    streak_warning: "streakWarnings",
    daily_reminder: "dailyReminder",
    achievement: "achievementUnlocks",
    leaderboard: "leaderboardChanges",
  };

  const prefKey = prefMap[type];
  return preferences[prefKey] !== false; // Default to true if not set
}

/**
 * Log notification to Firestore for tracking
 */
async function logNotification(
  userId: string,
  type: NotificationType,
  title: string,
  body: string,
  metadata?: Record<string, string>
): Promise<void> {
  try {
    await getDb().collection("notificationLogs").add({
      userId,
      type,
      title,
      body,
      metadata: metadata || {},
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("Error logging notification:", error);
    // Don't throw - logging failure shouldn't prevent notification
  }
}

/**
 * Send notification to multiple users
 */
export async function sendNotificationToMultiple(
  userIds: string[],
  title: string,
  body: string,
  type: NotificationType,
  data?: Record<string, string>
): Promise<void> {
  const promises = userIds.map((userId) =>
    sendNotification(userId, title, body, type, data)
  );
  await Promise.allSettled(promises);
}

/**
 * Send friend request notification
 */
export async function sendFriendRequestNotification(
  toUserId: string,
  fromUsername: string,
  fromUserId: string
): Promise<void> {
  await sendNotification(
    toUserId,
    "New Friend Request",
    `${fromUsername} sent you a friend request`,
    "friend_request",
    {
      fromUserId,
      fromUsername,
    }
  );
}

/**
 * Send friend request accepted notification
 */
export async function sendFriendRequestAcceptedNotification(
  toUserId: string,
  acceptedByUsername: string,
  acceptedByUserId: string
): Promise<void> {
  await sendNotification(
    toUserId,
    "Friend Request Accepted",
    `${acceptedByUsername} accepted your friend request!`,
    "friend_request_accepted",
    {
      acceptedByUserId,
      acceptedByUsername,
    }
  );
}

/**
 * Send battle invite notification
 */
export async function sendBattleInviteNotification(
  toUserId: string,
  fromUsername: string,
  battleId: string,
  testType: string
): Promise<void> {
  await sendNotification(
    toUserId,
    "Battle Challenge!",
    `${fromUsername} challenged you to a ${testType} battle!`,
    "battle_invite",
    {
      battleId,
      fromUsername,
      testType,
    }
  );
}

/**
 * Send streak warning notification
 */
export async function sendStreakWarningNotification(
  userId: string,
  streakDays: number
): Promise<void> {
  await sendNotification(
    userId,
    "Don't Break Your Streak!",
    `You haven't studied today. Keep your ${streakDays}-day streak alive!`,
    "streak_warning",
    {
      streakDays: streakDays.toString(),
    }
  );
}

/**
 * Send daily reminder notification
 */
export async function sendDailyReminderNotification(
  userId: string
): Promise<void> {
  await sendNotification(
    userId,
    "Time to Study!",
    "Your daily prep session is waiting. Let's boost that score!",
    "daily_reminder"
  );
}

/**
 * Send achievement unlocked notification
 */
export async function sendAchievementNotification(
  userId: string,
  achievementName: string,
  achievementEmoji: string
): Promise<void> {
  await sendNotification(
    userId,
    "Achievement Unlocked!",
    `${achievementEmoji} You earned: ${achievementName}`,
    "achievement",
    {
      achievementName,
      achievementEmoji,
    }
  );
}

/**
 * Send leaderboard position change notification
 */
export async function sendLeaderboardNotification(
  userId: string,
  newRank: number,
  oldRank?: number
): Promise<void> {
  const message = oldRank
    ? `You moved up from #${oldRank} to #${newRank}!`
    : `You're now ranked #${newRank}!`;

  await sendNotification(
    userId,
    "Leaderboard Update",
    message,
    "leaderboard",
    {
      newRank: newRank.toString(),
      oldRank: oldRank?.toString() || "",
    }
  );
}
