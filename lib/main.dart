import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/theme.dart';
import 'config/router.dart';
import 'config/firebase_config.dart';
import 'services/widget_service.dart';
import 'services/notification_service.dart';

/// Background message handler for FCM (native platforms only — web uses service worker)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseConfig.initialize();
  debugPrint('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation lock is mobile-only (no-op on web but wrapped for clarity)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Initialize Firebase with proper configuration
  await FirebaseConfig.initialize();

  // Register background message handler — native only; web uses firebase-messaging-sw.js
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Create a ProviderContainer to access providers before the widget tree is built
  final container = ProviderContainer();

  // Initialize widget service for home screen widgets (mobile only)
  if (!kIsWeb) {
    await container.read(widgetServiceProvider).initialize();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PrepRoyaleApp(),
    ),
  );
}

class PrepRoyaleApp extends ConsumerWidget {
  const PrepRoyaleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Set router instance in NotificationService for navigation from notifications
    NotificationService().setRouter(router);

    return MaterialApp.router(
      title: 'Prep Royale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
