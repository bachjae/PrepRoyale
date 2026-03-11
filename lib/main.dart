import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/theme.dart';
import 'config/router.dart';
import 'config/firebase_config.dart';
import 'services/widget_service.dart';
import 'services/notification_service.dart';

/// Background message handler for FCM (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseConfig.initialize();
  debugPrint('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Draw behind system navigation bar so SafeArea handles insets correctly
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Firebase with proper configuration
  await FirebaseConfig.initialize();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create a ProviderContainer to access providers before the widget tree is built
  final container = ProviderContainer();

  // Initialize widget service for home screen widgets (WorkManager + HomeWidget)
  // This now uses the provider which handles the Ref dependency correctly
  await container.read(widgetServiceProvider).initialize();

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
