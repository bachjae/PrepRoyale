import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Set to true to use local emulators for testing
  static const bool useEmulators = false;

  // Android emulator uses 10.0.2.2 to reach host's localhost
  // iOS simulator and physical devices use different addresses
  static String get emulatorHost {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: defaultPlatformOptions,
    );

    // Connect to emulators in debug mode
    if (useEmulators && kDebugMode) {
      await _connectToEmulators();
    }
  }

  static Future<void> _connectToEmulators() async {
    debugPrint('🔧 Connecting to Firebase Emulators at $emulatorHost...');

    // Auth emulator (needed for guest anonymous auth)
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    debugPrint('  ✓ Auth emulator connected (port 9099)');

    // Firestore emulator
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    debugPrint('  ✓ Firestore emulator connected (port 8080)');

    // Realtime Database emulator
    FirebaseDatabase.instance.useDatabaseEmulator(emulatorHost, 9000);
    debugPrint('  ✓ Database emulator connected (port 9000)');

    debugPrint('🔧 Firebase Emulators connected successfully!');
  }

  static FirebaseOptions get defaultPlatformOptions {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not supported');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyDflI82-vGURsAY_D9ILccZ-mSGrOy15Cg',
          appId: '1:722112363962:android:7803d378e1c44ee4863183',
          messagingSenderId: '722112363962',
          projectId: 'sat-act-battle-royale',
          storageBucket: 'sat-act-battle-royale.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        // iOS not configured yet - add iOS app in Firebase Console if needed
        return const FirebaseOptions(
          apiKey: 'AIzaSyDflI82-vGURsAY_D9ILccZ-mSGrOy15Cg',
          appId: '1:722112363962:android:7803d378e1c44ee4863183',
          messagingSenderId: '722112363962',
          projectId: 'sat-act-battle-royale',
          storageBucket: 'sat-act-battle-royale.firebasestorage.app',
          iosBundleId: 'com.example.satActApp',
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
