import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../services/firebase_service.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Current user ID provider
// Falls back to synchronous currentUser to avoid null during stream loading
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid
      ?? FirebaseAuth.instance.currentUser?.uid;
});

// Current user data provider (from Firestore)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getUserStream(userId);
});

// Auth controller for login/signup/logout actions
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);
  FirebaseService get _firebaseService => _ref.read(firebaseServiceProvider);

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Check if username is available
      final isAvailable = await _firebaseService.isUsernameAvailable(username);
      if (!isAvailable) {
        return AuthResult.failure('Username is already taken');
      }

      // Create auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to create account');
      }

      // Create user profile in Firestore
      await _firebaseService.createUser(
        userId: credential.user!.uid,
        email: email,
        username: username,
      );

      return AuthResult.success(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to sign in');
      }

      return AuthResult.success(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success('');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      // Web requires the OAuth Web Client ID so the popup can redirect back
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: kIsWeb
            ? '722112363962-1ln0t1a9akidetepl2lop52nmoq00jg1.apps.googleusercontent.com'
            : null,
      ).signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return AuthResult.failure('Sign in cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return AuthResult.failure('Failed to sign in with Google');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Helper to build username from Google profile
      String _buildUsername() {
        final email = userCredential.user!.email ?? '';
        final displayName = userCredential.user!.displayName ?? '';
        return displayName.isNotEmpty
            ? displayName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase()
            : email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      }

      if (isNewUser) {
        // Brand new Firebase Auth account — always create the Firestore document
        String username = _buildUsername();
        if (!await _firebaseService.isUsernameAvailable(username)) {
          username = '${username}_${DateTime.now().millisecondsSinceEpoch % 10000}';
        }
        await _firebaseService.createUser(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          username: username,
          profilePictureUrl: userCredential.user!.photoURL,
        );
      } else {
        // Existing Firebase Auth account — check that the Firestore doc exists
        // (edge case: auth record exists but doc was never created or was deleted)
        final existingUser = await _firebaseService.getUser(userCredential.user!.uid);
        if (existingUser == null) {
          String username = _buildUsername();
          if (!await _firebaseService.isUsernameAvailable(username)) {
            username = '${username}_${DateTime.now().millisecondsSinceEpoch % 10000}';
          }
          await _firebaseService.createUser(
            userId: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            username: username,
            profilePictureUrl: userCredential.user!.photoURL,
          );
          // Treat as new user so they go through profile setup
          return AuthResult.success(userCredential.user!.uid, isNewUser: true);
        }
      }

      return AuthResult.success(userCredential.user!.uid, isNewUser: isNewUser);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Google sign in failed: ${e.toString()}');
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

// Result class for auth operations
class AuthResult {
  final bool isSuccess;
  final String? userId;
  final String? errorMessage;
  final bool isNewUser;

  AuthResult._({
    required this.isSuccess,
    this.userId,
    this.errorMessage,
    this.isNewUser = false,
  });

  factory AuthResult.success(String userId, {bool isNewUser = false}) {
    return AuthResult._(isSuccess: true, userId: userId, isNewUser: isNewUser);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
