import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_stats.dart';
import '../models/user_model.dart';
import '../models/user_session.dart';
import '../services/firebase_service.dart';
import '../services/local_stats_service.dart';
import 'auth_provider.dart';

/// Provider for the current user session (guest or authenticated)
final userSessionProvider = StateNotifierProvider<UserSessionNotifier, UserSession?>((ref) {
  return UserSessionNotifier(ref);
});

/// Provider that indicates if the user is in guest mode
final isGuestModeProvider = Provider<bool>((ref) {
  final session = ref.watch(userSessionProvider);
  return session?.isGuest ?? false;
});

/// Provider that indicates if the user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final session = ref.watch(userSessionProvider);
  return session?.isAuthenticated ?? false;
});

/// Provider for guest stats (only valid in guest mode)
final guestStatsProvider = FutureProvider<LocalStats?>((ref) async {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return null;

  final localStatsService = ref.read(localStatsServiceProvider);
  return localStatsService.getGuestStats();
});

/// Stream provider for guest stats (refreshes when stats change)
final guestStatsStreamProvider = StreamProvider<LocalStats?>((ref) async* {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) {
    yield null;
    return;
  }

  final localStatsService = ref.read(localStatsServiceProvider);

  // Initial yield
  yield await localStatsService.getGuestStats();

  // This is a simple polling approach; could be improved with a proper stream
  // For now, we'll rely on manual refreshes
});

/// Combined provider that returns either authenticated user or guest stats
final effectiveUserDataProvider = Provider<EffectiveUserData?>((ref) {
  final session = ref.watch(userSessionProvider);
  if (session == null) return null;

  if (session.isAuthenticated) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return null;
    return EffectiveUserData.fromAuthenticatedUser(user);
  } else {
    final stats = ref.watch(guestStatsProvider).valueOrNull;
    return EffectiveUserData.fromGuestStats(stats ?? const LocalStats());
  }
});

/// Unified skill stats that works for both guest and authenticated users
class EffectiveSkillStats {
  final int totalAttempts;
  final int correctAnswers;

  const EffectiveSkillStats({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
  });

  double get accuracy => totalAttempts == 0 ? 0.0 : correctAnswers / totalAttempts;
}

/// Unified user data that works for both guest and authenticated users
class EffectiveUserData {
  final bool isGuest;
  final String? odUserId;
  final String username;
  final String? profilePictureUrl;
  final int level;
  final int totalXp;
  final int totalQuestionsAnswered;
  final int totalCorrect;
  final double overallAccuracy;
  final int dailyStreak;
  final int bestDailyStreak;
  final int currentAccuracyStreak;
  final int bestAccuracyStreak;
  final int battlesWon;
  final int battlesPlayed;
  final Map<String, double> sectionAccuracy;
  final Map<String, EffectiveSkillStats> skillStats;

  const EffectiveUserData({
    required this.isGuest,
    this.odUserId,
    required this.username,
    this.profilePictureUrl,
    required this.level,
    required this.totalXp,
    required this.totalQuestionsAnswered,
    required this.totalCorrect,
    required this.overallAccuracy,
    required this.dailyStreak,
    required this.bestDailyStreak,
    required this.currentAccuracyStreak,
    required this.bestAccuracyStreak,
    required this.battlesWon,
    required this.battlesPlayed,
    required this.sectionAccuracy,
    required this.skillStats,
  });

  /// Get skill stats for a specific section (e.g., 'SAT_Math' returns all SAT_Math_* skills)
  Map<String, EffectiveSkillStats> getSkillsForSection(String sectionKey) {
    return Map.fromEntries(
      skillStats.entries.where((e) => e.key.startsWith('${sectionKey}_')),
    );
  }

  /// Get formatted skill name (e.g., 'SAT_Math_LinearEquations' -> 'Linear Equations')
  static String formatSkillName(String skillKey) {
    final parts = skillKey.split('_');
    if (parts.length < 3) return skillKey;

    final skillName = parts.sublist(2).join('_');
    return skillName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }

  /// Get formatted section name (e.g., 'SAT_Math' -> 'SAT Math')
  static String formatSectionName(String sectionKey) {
    return sectionKey.replaceAll('_', ' ');
  }

  factory EffectiveUserData.fromAuthenticatedUser(UserModel user) {
    // Convert UserModel skill stats to EffectiveSkillStats
    final effectiveSkillStats = <String, EffectiveSkillStats>{};
    for (final entry in user.stats.skillStats.entries) {
      effectiveSkillStats[entry.key] = EffectiveSkillStats(
        totalAttempts: entry.value.totalAttempts,
        correctAnswers: entry.value.correctAnswers,
      );
    }

    return EffectiveUserData(
      isGuest: false,
      odUserId: user.id,
      username: user.username,
      profilePictureUrl: user.profilePictureUrl,
      level: user.level,
      totalXp: user.totalXp,
      totalQuestionsAnswered: user.stats.totalQuestions,
      totalCorrect: (user.stats.overallAccuracy * user.stats.totalQuestions).round(),
      overallAccuracy: user.stats.overallAccuracy,
      dailyStreak: user.dailyStreak.count,
      bestDailyStreak: user.dailyStreak.best,
      currentAccuracyStreak: user.accuracyStreak.current,
      bestAccuracyStreak: user.accuracyStreak.best,
      battlesWon: user.battleStats.wins,
      battlesPlayed: user.battleStats.wins + user.battleStats.losses,
      sectionAccuracy: Map<String, double>.from(user.stats.sectionAccuracy),
      skillStats: effectiveSkillStats,
    );
  }

  factory EffectiveUserData.fromGuestStats(LocalStats stats) {
    // Convert LocalStats skill stats to EffectiveSkillStats
    final effectiveSkillStats = <String, EffectiveSkillStats>{};
    for (final entry in stats.skillStats.entries) {
      effectiveSkillStats[entry.key] = EffectiveSkillStats(
        totalAttempts: entry.value.totalAttempts,
        correctAnswers: entry.value.correctAnswers,
      );
    }

    return EffectiveUserData(
      isGuest: true,
      odUserId: null,
      username: 'Guest',
      profilePictureUrl: null,
      level: stats.level,
      totalXp: stats.totalXp,
      totalQuestionsAnswered: stats.totalQuestionsAnswered,
      totalCorrect: stats.totalCorrect,
      overallAccuracy: stats.overallAccuracy,
      dailyStreak: stats.dailyStreakCount,
      bestDailyStreak: stats.bestDailyStreak,
      currentAccuracyStreak: stats.currentAccuracyStreak,
      bestAccuracyStreak: stats.bestAccuracyStreak,
      battlesWon: stats.battlesWon,
      battlesPlayed: stats.battlesPlayed,
      sectionAccuracy: Map<String, double>.from(stats.sectionAccuracy),
      skillStats: effectiveSkillStats,
    );
  }
}

/// Notifier for managing user session state
class UserSessionNotifier extends StateNotifier<UserSession?> {
  final Ref _ref;
  bool _initialized = false;
  StreamSubscription<User?>? _authSubscription;

  UserSessionNotifier(this._ref) : super(null) {
    _initialize();
    listenToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Initialize the session based on Firebase Auth and local preferences
  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    final localStatsService = _ref.read(localStatsServiceProvider);

    // Check if there's an authenticated Firebase user
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // Check if this is an anonymous user (guest with live battle support)
      if (firebaseUser.isAnonymous) {
        // Anonymous user = guest mode with live battles
        final isGuestMode = await localStatsService.isGuestModeEnabled();
        if (isGuestMode) {
          final guestId = await localStatsService.getOrCreateGuestId();
          state = UserSession.guest(guestId);
          return;
        }
        // Anonymous user but guest mode not enabled - sign out and continue
        await FirebaseAuth.instance.signOut();
      } else {
        // Regular authenticated user
        state = UserSession.authenticated(firebaseUser.uid);
        await localStatsService.disableGuestMode();
        return;
      }
    }

    // Check if guest mode was previously enabled
    final isGuestMode = await localStatsService.isGuestModeEnabled();
    if (isGuestMode) {
      final guestId = await localStatsService.getOrCreateGuestId();
      // Try to restore anonymous auth for live battles
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        print('Failed to restore anonymous auth: $e');
      }
      state = UserSession.guest(guestId);
      return;
    }

    // No session - user needs to choose
    state = null;
  }

  /// Listen to Firebase Auth state changes
  void listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      final localStatsService = _ref.read(localStatsServiceProvider);

      if (user != null) {
        if (user.isAnonymous) {
          // Anonymous user - this is guest mode with live battle support
          // Don't change session state, it's already handled by enterGuestMode
        } else {
          // Real authenticated user logged in
          if (!mounted) return;
          state = UserSession.authenticated(user.uid);
          await localStatsService.disableGuestMode();
        }
      } else if (state?.isAuthenticated == true) {
        // User logged out from authenticated state
        if (!mounted) return;
        state = null;
      }
    });
  }

  /// Enter guest mode
  /// Uses Firebase Anonymous Auth to enable live battles while keeping stats local
  Future<void> enterGuestMode() async {
    final localStatsService = _ref.read(localStatsServiceProvider);
    await localStatsService.enableGuestMode();
    final guestId = await localStatsService.getOrCreateGuestId();

    // Sign in anonymously to Firebase Auth for matchmaking support
    // This allows guests to use live battle matchmaking
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      // Continue in guest mode even if anonymous auth fails
      // Bot battles will still work
      print('Anonymous auth failed: $e');
    }

    state = UserSession.guest(guestId);
  }

  /// Exit guest mode (for when user wants to sign up/login)
  Future<void> exitGuestMode() async {
    final localStatsService = _ref.read(localStatsServiceProvider);
    await localStatsService.disableGuestMode();

    // Sign out the anonymous user if one exists
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      await FirebaseAuth.instance.signOut();
    }

    state = null;
  }

  /// Transition from guest to authenticated after login
  Future<void> transitionToAuthenticated(String userId) async {
    final localStatsService = _ref.read(localStatsServiceProvider);
    await localStatsService.disableGuestMode();
    state = UserSession.authenticated(userId);
  }

  /// Get guest stats for migration
  Future<Map<String, dynamic>?> getGuestStatsForMigration() async {
    final localStatsService = _ref.read(localStatsServiceProvider);
    final isGuestMode = await localStatsService.isGuestModeEnabled();
    if (!isGuestMode) return null;

    return localStatsService.exportGuestStatsForMigration();
  }

  /// Clear guest stats after successful migration
  Future<void> clearGuestStats() async {
    final localStatsService = _ref.read(localStatsServiceProvider);
    await localStatsService.clearGuestStats();
  }

  /// Refresh guest stats (force re-read from storage)
  Future<void> refreshGuestStats() async {
    if (state?.isGuest != true) return;
    // Invalidate the guest stats provider
    _ref.invalidate(guestStatsProvider);
  }
}

/// Provider for managing session transitions
final sessionControllerProvider = Provider<SessionController>((ref) {
  return SessionController(ref);
});

class SessionController {
  final Ref _ref;

  SessionController(this._ref);

  UserSessionNotifier get _sessionNotifier => _ref.read(userSessionProvider.notifier);
  AuthController get _authController => _ref.read(authControllerProvider);
  FirebaseService get _firebaseService => _ref.read(firebaseServiceProvider);

  /// Start as guest
  Future<void> continueAsGuest() async {
    await _sessionNotifier.enterGuestMode();
  }

  /// Sign up and optionally migrate guest stats
  Future<AuthResult> signUpWithMigration({
    required String email,
    required String password,
    required String username,
    bool migrateGuestStats = false,
  }) async {
    // Get guest stats before signup if migration is requested
    Map<String, dynamic>? guestStats;
    if (migrateGuestStats) {
      guestStats = await _sessionNotifier.getGuestStatsForMigration();
    }

    // Perform signup
    final result = await _authController.signUp(
      email: email,
      password: password,
      username: username,
    );

    if (result.isSuccess && guestStats != null) {
      // Migrate guest stats to the new account
      try {
        await _migrateGuestStats(result.userId!, guestStats);
        await _sessionNotifier.clearGuestStats();
      } catch (e) {
        // Migration failed, but account was created successfully
        // Log error but don't fail the signup
        print('Guest stats migration failed: $e');
      }
    }

    if (result.isSuccess) {
      await _sessionNotifier.transitionToAuthenticated(result.userId!);
    }

    return result;
  }

  /// Sign in from guest mode
  Future<AuthResult> signInFromGuest({
    required String email,
    required String password,
    bool migrateGuestStats = false,
  }) async {
    // Get guest stats before login if migration is requested
    Map<String, dynamic>? guestStats;
    if (migrateGuestStats) {
      guestStats = await _sessionNotifier.getGuestStatsForMigration();
    }

    // Perform login
    final result = await _authController.signIn(
      email: email,
      password: password,
    );

    if (result.isSuccess && guestStats != null) {
      // Migrate guest stats to the existing account
      try {
        await _migrateGuestStats(result.userId!, guestStats);
        await _sessionNotifier.clearGuestStats();
      } catch (e) {
        // Migration failed, but login was successful
        print('Guest stats migration failed: $e');
      }
    }

    if (result.isSuccess) {
      await _sessionNotifier.transitionToAuthenticated(result.userId!);
    }

    return result;
  }

  /// Migrate guest stats to authenticated account
  Future<void> _migrateGuestStats(String userId, Map<String, dynamic> guestStats) async {
    // Add XP from guest mode
    final totalXp = guestStats['totalXp'] as int? ?? 0;
    if (totalXp > 0) {
      await _firebaseService.addXp(userId, totalXp);
    }

    // Note: More sophisticated migration could merge section accuracy,
    // skill stats, etc. For now, we just add XP as a simple migration.
    // The user starts fresh with cloud-based progress tracking.
  }

  /// Sign out
  Future<void> signOut() async {
    await _authController.signOut();
    // Session will be updated by auth state listener
  }
}
