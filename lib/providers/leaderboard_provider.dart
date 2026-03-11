import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/cloud_fn.dart';

enum LeaderboardType { global, friends }

class LeaderboardEntry {
  final String odId; // User ID - using odId for backwards compatibility
  final String username;
  final String? profilePictureUrl;
  final int level;
  final int totalXp;
  final int rank;

  LeaderboardEntry({
    required this.odId,
    required this.username,
    this.profilePictureUrl,
    required this.level,
    required this.totalXp,
    required this.rank,
  });

  // Alias getter for clarity
  String get odIdAlias => odId;

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      odId: doc.id,
      username: data['username'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      level: data['level'] ?? 1,
      totalXp: data['totalXp'] ?? 0,
      rank: rank,
    );
  }
}

class LeaderboardState {
  final List<LeaderboardEntry> globalEntries;
  final List<LeaderboardEntry> friendsEntries;
  final LeaderboardType currentType;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.globalEntries = const [],
    this.friendsEntries = const [],
    this.currentType = LeaderboardType.global,
    this.isLoading = false,
    this.error,
  });

  /// Get current entries based on selected type
  List<LeaderboardEntry> get entries =>
      currentType == LeaderboardType.global ? globalEntries : friendsEntries;

  LeaderboardState copyWith({
    List<LeaderboardEntry>? globalEntries,
    List<LeaderboardEntry>? friendsEntries,
    LeaderboardType? currentType,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      globalEntries: globalEntries ?? this.globalEntries,
      friendsEntries: friendsEntries ?? this.friendsEntries,
      currentType: currentType ?? this.currentType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LeaderboardNotifier(this._ref) : super(const LeaderboardState());

  /// Switch between global and friends leaderboard
  void setLeaderboardType(LeaderboardType type) {
    if (type == state.currentType) return;
    state = state.copyWith(currentType: type);

    if (type == LeaderboardType.global) {
      if (state.globalEntries.isEmpty) loadGlobalLeaderboard();
    } else {
      // Always refresh friends data when switching to the tab
      // so newly added friends appear without a full app restart
      loadFriendsLeaderboard();
    }
  }

  Future<void> loadGlobalLeaderboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get top 100 users by totalXp
      final query = await _firestore
          .collection('users')
          .orderBy('totalXp', descending: true)
          .limit(100)
          .get();

      final entries = <LeaderboardEntry>[];
      int rank = 1;
      for (final doc in query.docs) {
        entries.add(LeaderboardEntry.fromFirestore(doc, rank));
        rank++;
      }

      state = state.copyWith(globalEntries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load leaderboard: $e',
      );
    }
  }

  Future<void> loadFriendsLeaderboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use direct HTTP call to bypass Firebase callable SDK's App Check blocker
      final result = await callFn('getFriendsLeaderboard');

      final entriesData = (result as Map<String, dynamic>)['entries'] as List;
      final entries = entriesData.asMap().entries.map((e) {
        final data = Map<String, dynamic>.from(e.value as Map);
        // Cloud function returns 'odUserId', fallback to 'userId' for compatibility
        final userId = data['odUserId'] ?? data['userId'] ?? data['id'] ?? '';
        return LeaderboardEntry(
          odId: userId,
          username: data['username'] ?? 'Unknown',
          profilePictureUrl: data['profilePictureUrl'],
          level: data['level'] ?? 1,
          totalXp: data['totalXp'] ?? 0,
          rank: data['rank'] ?? (e.key + 1),
        );
      }).toList();

      state = state.copyWith(friendsEntries: entries, isLoading: false);
    } on CloudFnException catch (e) {
      final message = e.code == 'unauthenticated'
          ? 'Could not verify your account. Please sign out and sign back in.'
          : 'Could not load friends leaderboard. Please try again.';
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load friends leaderboard. Please try again.',
      );
    }
  }

  Future<void> refresh() async {
    if (state.currentType == LeaderboardType.global) {
      await loadGlobalLeaderboard();
    } else {
      await loadFriendsLeaderboard();
    }
  }

  int? getCurrentUserRank() {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return null;

    final entries = state.entries;
    final index = entries.indexWhere((e) => e.odId == userId);
    return index >= 0 ? index + 1 : null;
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  final notifier = LeaderboardNotifier(ref);
  notifier.loadGlobalLeaderboard();
  return notifier;
});
