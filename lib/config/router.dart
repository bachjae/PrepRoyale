import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/profile_picture_selector.dart';
import '../screens/home/home_screen.dart';
import '../screens/study/study_mode_selector.dart';
import '../screens/study/question_screen.dart';
import '../screens/study/answer_feedback_screen.dart';
import '../screens/battle/battle_lobby.dart';
import '../screens/battle/battle_screen.dart';
import '../screens/battle/battle_results.dart';
import '../screens/battle/guest_battle_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/achievements_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/friends/add_friend_screen.dart';
import '../screens/home/detailed_stats_screen.dart';

// Route names
class Routes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profilePicture = '/profile-picture';
  static const String home = '/';
  static const String studySelector = '/study';
  static const String question = '/study/question';
  static const String answerFeedback = '/study/feedback';
  static const String battleLobby = '/battle';
  static const String battleScreen = '/battle/play';
  static const String battleResults = '/battle/results';
  static const String guestBattle = '/battle/guest';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String achievements = '/profile/achievements';
  static const String leaderboard = '/leaderboard';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String friends = '/friends';
  static const String addFriend = '/friends/add';
  static const String stats = '/stats';

  /// Routes that require authentication (not available in guest mode)
  static const Set<String> authOnlyRoutes = {
    friends,
    addFriend,
    editProfile,
  };

  /// Routes that are public (welcome, login, signup)
  static const Set<String> publicRoutes = {
    welcome,
    login,
    signup,
    onboarding,
    profilePicture,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final session = ref.watch(userSessionProvider);

  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isGuest = session?.isGuest ?? false;
      final hasSession = isLoggedIn || isGuest;
      final currentPath = state.matchedLocation;

      // Check if current route is public (no session required)
      final isPublicRoute = Routes.publicRoutes.contains(currentPath);

      // Check if current route requires authentication (not guest-allowed)
      final isAuthOnlyRoute = Routes.authOnlyRoutes.contains(currentPath);

      // No session and not on public route -> redirect to welcome
      if (!hasSession && !isPublicRoute) {
        return Routes.welcome;
      }

      // Authenticated user on welcome/login/signup -> redirect to home
      // Note: We use isLoggedIn (not hasSession) so that guests who exit
      // guest mode can still reach the auth screens to sign up / log in.
      if (isLoggedIn &&
          (currentPath == Routes.welcome ||
              currentPath == Routes.login ||
              currentPath == Routes.signup)) {
        return Routes.home;
      }

      // Guest trying to access auth-only route -> redirect to home
      // (UI will show appropriate prompts)
      if (isGuest && isAuthOnlyRoute) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      // Welcome screen (entry point for new users)
      GoRoute(
        path: Routes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Auth routes
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: Routes.profilePicture,
        name: 'profilePicture',
        builder: (context, state) {
          final isNewUser = state.uri.queryParameters['newUser'] == 'true';
          return ProfilePictureSelector(isNewUser: isNewUser);
        },
      ),

      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Settings
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Main routes
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.stats,
        name: 'stats',
        builder: (context, state) => const DetailedStatsScreen(),
      ),

      // Study routes
      GoRoute(
        path: Routes.studySelector,
        name: 'studySelector',
        builder: (context, state) => const StudyModeSelector(),
      ),
      GoRoute(
        path: Routes.question,
        name: 'question',
        builder: (context, state) => const QuestionScreen(),
      ),
      GoRoute(
        path: Routes.answerFeedback,
        name: 'answerFeedback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AnswerFeedbackScreen(
            isCorrect: extra?['isCorrect'] ?? false,
            selectedAnswer: extra?['selectedAnswer'] ?? 0,
            correctAnswer: extra?['correctAnswer'] ?? 0,
            explanation: extra?['explanation'] ?? '',
            xpEarned: extra?['xpEarned'] ?? 0,
          );
        },
      ),

      // Battle routes
      GoRoute(
        path: Routes.battleLobby,
        name: 'battleLobby',
        builder: (context, state) => const BattleLobby(),
      ),
      GoRoute(
        path: Routes.battleScreen,
        name: 'battleScreen',
        builder: (context, state) {
          final battleId = state.uri.queryParameters['battleId'] ?? '';
          return BattleScreen(battleId: battleId);
        },
      ),
      GoRoute(
        path: Routes.battleResults,
        name: 'battleResults',
        builder: (context, state) {
          final battleId = state.uri.queryParameters['battleId'] ?? '';
          return BattleResults(battleId: battleId);
        },
      ),
      GoRoute(
        path: Routes.guestBattle,
        name: 'guestBattle',
        builder: (context, state) => const GuestBattleScreen(),
      ),

      // Profile routes
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.achievements,
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),

      // Leaderboard
      GoRoute(
        path: Routes.leaderboard,
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // Friends routes
      GoRoute(
        path: Routes.friends,
        name: 'friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: Routes.addFriend,
        name: 'addFriend',
        builder: (context, state) => const AddFriendScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
