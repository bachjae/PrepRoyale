import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Service for managing Firebase Cloud Messaging notifications
/// Handles FCM token registration, permission requests, and notification delivery
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;

  // GoRouter instance for navigation
  GoRouter? _router;

  /// Set the router instance for navigation
  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Initialize notification service
  /// Requests permissions, registers FCM token, and sets up message handlers
  Future<void> initialize(String userId) async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Request notification permissions (Android 13+)
      final settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token (web requires VAPID key for push subscription)
        _fcmToken = kIsWeb
            ? await _firebaseMessaging.getToken(
                vapidKey:
                    'BNm2CtxV0arwHuO2Fh-q3ai8GcmaiNQzmo-DajZaIymEvEPM1dQHJcqk_uha5AvdoicCq0uo0unx-4Jt7Aa2F8M',
              )
            : await _firebaseMessaging.getToken();

        if (_fcmToken != null) {
          // Save token to Firestore
          await _saveFCMToken(userId, _fcmToken!);
          debugPrint('FCM Token registered: $_fcmToken');
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveFCMToken(userId, newToken);
          debugPrint('FCM Token refreshed: $newToken');
        });

        // Set up message handlers
        _setupMessageHandlers();
      } else {
        debugPrint('Notification permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermission() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Set up foreground and background message handlers
  void _setupMessageHandlers() {
    // Foreground messages (app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages (app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Terminated state messages (app was closed)
    _checkInitialMessage();
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');

    // In foreground, we could show a snackbar or in-app notification
    // For push-only approach, we do nothing here (notification shows automatically)
  }

  /// Handle messages when app is opened from background
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message opened: ${message.notification?.title}');

    // Handle navigation based on message data
    _handleNotificationTap(message.data);
  }

  /// Check if app was opened from a terminated state notification
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.notification?.title}');
      _handleNotificationTap(initialMessage.data);
    }
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    if (_router == null) {
      debugPrint('Router not set, cannot navigate');
      return;
    }

    // Navigation logic based on notification type
    switch (type) {
      case 'friend_request':
      case 'friend_request_accepted':
        debugPrint('Navigate to friends screen');
        _router!.go('/friends');
        break;
      case 'battle_invite':
        final battleId = data['battleId'] as String?;
        debugPrint('Navigate to battle lobby for invite: $battleId');
        // Route to lobby so the user can accept or decline before entering the game
        _router!.go(battleId != null ? '/battle?battleId=$battleId' : '/battle');
        break;
      case 'streak_warning':
      case 'daily_reminder':
        debugPrint('Navigate to study mode');
        _router!.go('/study');
        break;
      case 'achievement':
        debugPrint('Navigate to achievements');
        _router!.go('/profile/achievements');
        break;
      case 'leaderboard':
        debugPrint('Navigate to leaderboard');
        _router!.go('/leaderboard');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Update notification preferences in Firestore
  Future<void> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationPreferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Reset initialization state (call on logout so next login re-initializes)
  void reset() {
    _initialized = false;
    _fcmToken = null;
  }

  /// Unregister FCM token (e.g., on logout)
  Future<void> unregister(String userId) async {
    try {
      // Delete FCM token from Firestore
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete token from FCM
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;

      debugPrint('FCM token unregistered');
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
/// This handles notifications when the app is completely terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
  // Process background notification
  // Cannot update UI here, only perform background tasks
}
