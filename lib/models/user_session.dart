import 'package:equatable/equatable.dart';

/// Represents the current user session mode
enum SessionMode {
  /// User is logged in with Firebase Auth
  authenticated,

  /// User is using the app without logging in
  guest,
}

/// Unified session model that works for both authenticated and guest users
class UserSession extends Equatable {
  final SessionMode mode;
  final String? odUserId; // Firebase Auth UID (null for guests)
  final String? guestId; // Local guest ID (null for authenticated)
  final DateTime sessionStarted;

  const UserSession({
    required this.mode,
    this.odUserId,
    this.guestId,
    required this.sessionStarted,
  });

  /// True if the user is logged in with Firebase Auth
  bool get isAuthenticated => mode == SessionMode.authenticated;

  /// True if the user is using guest mode
  bool get isGuest => mode == SessionMode.guest;

  /// Get the effective user ID (Firebase UID or local guest ID)
  String? get effectiveUserId => isAuthenticated ? odUserId : guestId;

  /// Create an authenticated session
  factory UserSession.authenticated(String userId) {
    return UserSession(
      mode: SessionMode.authenticated,
      odUserId: userId,
      guestId: null,
      sessionStarted: DateTime.now(),
    );
  }

  /// Create a guest session
  factory UserSession.guest(String guestId) {
    return UserSession(
      mode: SessionMode.guest,
      odUserId: null,
      guestId: guestId,
      sessionStarted: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [mode, odUserId, guestId, sessionStarted];
}
