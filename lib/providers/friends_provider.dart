import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friendship_model.dart';
import '../providers/auth_provider.dart';
import '../services/cloud_fn.dart';

/// Stream of all accepted friendships for the current user.
/// Uses two independent real-time queries (user1Id and user2Id) merged via a
/// StreamController so that updates fire regardless of which field matches.
final friendshipsStreamProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;
  final controller = StreamController<List<FriendshipModel>>();

  List<QueryDocumentSnapshot> docs1 = [];
  List<QueryDocumentSnapshot> docs2 = [];

  void emitCombined() {
    final all = [...docs1, ...docs2];
    controller.add(all.map((d) => FriendshipModel.fromFirestore(d)).toList());
  }

  final sub1 = firestore
      .collection('friendships')
      .where('user1Id', isEqualTo: userId)
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .listen((s) { docs1 = s.docs; emitCombined(); });

  final sub2 = firestore
      .collection('friendships')
      .where('user2Id', isEqualTo: userId)
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .listen((s) { docs2 = s.docs; emitCombined(); });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Stream of pending friend requests received by the current user.
/// Uses two independent real-time queries so requests appear regardless of
/// whether the current user is user1 or user2 in the friendship document.
final pendingRequestsStreamProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;
  final controller = StreamController<List<FriendRequest>>();

  List<QueryDocumentSnapshot> docs1 = [];
  List<QueryDocumentSnapshot> docs2 = [];

  void emitCombined() {
    final requests = <FriendRequest>[];
    for (final doc in [...docs1, ...docs2]) {
      final friendship = FriendshipModel.fromFirestore(doc);
      if (friendship.isRecipient(userId)) {
        requests.add(FriendRequest.fromFriendship(friendship));
      }
    }
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    controller.add(requests);
  }

  final sub1 = firestore
      .collection('friendships')
      .where('user1Id', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((s) { docs1 = s.docs; emitCombined(); });

  final sub2 = firestore
      .collection('friendships')
      .where('user2Id', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((s) { docs2 = s.docs; emitCombined(); });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Stream of friends with their full profile information
final friendsWithProfilesProvider =
    StreamProvider<List<FriendWithProfile>>((ref) {
  final friendshipsAsync = ref.watch(friendshipsStreamProvider);
  final userId = ref.watch(currentUserIdProvider);

  return friendshipsAsync.when(
    data: (friendships) async* {
      if (userId == null || friendships.isEmpty) {
        yield [];
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // Fetch friend profiles
      final friendProfiles = <FriendWithProfile>[];

      for (final friendship in friendships) {
        final friendId = friendship.getFriendId(userId);
        final userDoc = await firestore.collection('users').doc(friendId).get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          friendProfiles.add(FriendWithProfile(
            odId: friendId,
            username: data['username'] ?? '',
            profilePictureUrl: data['profilePictureUrl'],
            level: data['level'] ?? 1,
            totalXp: data['totalXp'] ?? 0,
            friendshipId: friendship.id,
          ));
        }
      }

      // Sort by level (highest first)
      friendProfiles.sort((a, b) => b.level.compareTo(a.level));
      yield friendProfiles;
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Friends Leaderboard Provider
final friendsLeaderboardProvider =
    FutureProvider<List<FriendWithProfile>>((ref) async {
  try {
    final result = await callFn('getFriendsLeaderboard');
    final entries = ((result as Map<String, dynamic>)['entries'] as List);

    return entries.map((e) {
      final map = Map<String, dynamic>.from(e);
      return FriendWithProfile(
        odId: map['odUserId'] ?? map['userId'] ?? '',
        username: map['username'] ?? '',
        profilePictureUrl: map['profilePictureUrl'],
        level: map['level'] ?? 1,
        totalXp: map['totalXp'] ?? 0,
        friendshipId: '',
      );
    }).toList();
  } catch (e) {
    return [];
  }
});

/// Count of pending friend requests
final pendingRequestsCountProvider = Provider<int>((ref) {
  final requestsAsync = ref.watch(pendingRequestsStreamProvider);
  return requestsAsync.when(
    data: (requests) => requests.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Result from looking up a user by friend code
class FriendCodeLookupResult {
  final String odId;
  final String username;
  final String? profilePictureUrl;
  final int level;

  const FriendCodeLookupResult({
    required this.odId,
    required this.username,
    this.profilePictureUrl,
    required this.level,
  });

  factory FriendCodeLookupResult.fromMap(Map<String, dynamic> map) {
    return FriendCodeLookupResult(
      odId: map['odId'] ?? map['userId'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      level: map['level'] ?? 1,
    );
  }
}

/// State for friend operations
class FriendsState {
  final bool isLoading;
  final String? error;
  final List<UserSearchResult> searchResults;
  final bool isSearching;
  final String? myFriendCode;
  final bool isLoadingFriendCode;
  final FriendCodeLookupResult? friendCodeLookupResult;
  final bool isLookingUpFriendCode;

  const FriendsState({
    this.isLoading = false,
    this.error,
    this.searchResults = const [],
    this.isSearching = false,
    this.myFriendCode,
    this.isLoadingFriendCode = false,
    this.friendCodeLookupResult,
    this.isLookingUpFriendCode = false,
  });

  FriendsState copyWith({
    bool? isLoading,
    String? error,
    List<UserSearchResult>? searchResults,
    bool? isSearching,
    String? myFriendCode,
    bool? isLoadingFriendCode,
    FriendCodeLookupResult? friendCodeLookupResult,
    bool? isLookingUpFriendCode,
    bool clearFriendCodeLookup = false,
  }) {
    return FriendsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      myFriendCode: myFriendCode ?? this.myFriendCode,
      isLoadingFriendCode: isLoadingFriendCode ?? this.isLoadingFriendCode,
      friendCodeLookupResult: clearFriendCodeLookup
          ? null
          : (friendCodeLookupResult ?? this.friendCodeLookupResult),
      isLookingUpFriendCode:
          isLookingUpFriendCode ?? this.isLookingUpFriendCode,
    );
  }
}

/// Notifier for friend operations
class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier() : super(const FriendsState());

  /// Search for users by username
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, error: null);

    try {
      final result = await callFn('searchUsers', {'query': query, 'limit': 10});
      final users = ((result as Map<String, dynamic>)['users'] as List)
          .map((u) => UserSearchResult.fromMap(Map<String, dynamic>.from(u)))
          .toList();

      state = state.copyWith(searchResults: users, isSearching: false);
    } on CloudFnException catch (e) {
      state = state.copyWith(
        error: e.message ?? 'Failed to search users',
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to search users',
        isSearching: false,
      );
    }
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: [], isSearching: false, error: null);
  }

  /// Send a friend request
  Future<bool> sendFriendRequest(String toUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await callFn('sendFriendRequest', {'toUserId': toUserId});
      state = state.copyWith(isLoading: false);
      return true;
    } on CloudFnException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.message ?? 'Failed to send friend request');
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to send friend request');
      return false;
    }
  }

  /// Respond to a friend request
  Future<bool> respondToFriendRequest(String friendshipId, bool accept) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await callFn('respondToFriendRequest',
          {'friendshipId': friendshipId, 'accept': accept});
      state = state.copyWith(isLoading: false);
      return true;
    } on CloudFnException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ??
            (accept ? 'Failed to accept request' : 'Failed to decline request'),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: accept ? 'Failed to accept request' : 'Failed to decline request',
      );
      return false;
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(String friendshipId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await callFn('removeFriend', {'friendshipId': friendshipId});
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove friend',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get the current user's friend code
  Future<void> getMyFriendCode() async {
    if (state.myFriendCode != null) return; // Already loaded

    state = state.copyWith(isLoadingFriendCode: true, error: null);

    try {
      final result = await callFn('getMyFriendCode');
      final friendCode =
          (result as Map<String, dynamic>)['friendCode'] as String?;
      state = state.copyWith(
        myFriendCode: friendCode,
        isLoadingFriendCode: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFriendCode: false,
        error: 'Failed to get friend code',
      );
    }
  }

  /// Look up a user by their friend code
  Future<void> lookupUserByFriendCode(String friendCode) async {
    if (friendCode.length != 8) {
      state = state.copyWith(
        error: 'Friend code must be 8 characters',
        isLookingUpFriendCode: false,
        clearFriendCodeLookup: true,
      );
      return;
    }

    state = state.copyWith(
      isLookingUpFriendCode: true,
      error: null,
      clearFriendCodeLookup: true,
    );

    try {
      final result = await callFn(
          'getUserByFriendCode', {'friendCode': friendCode.toUpperCase()});
      final userData = result as Map<String, dynamic>?;
      if (userData == null || userData['userId'] == null) {
        state = state.copyWith(
          isLookingUpFriendCode: false,
          error: 'No user found with this friend code',
          clearFriendCodeLookup: true,
        );
        return;
      }

      final lookupResult = FriendCodeLookupResult.fromMap(userData);
      state = state.copyWith(
        friendCodeLookupResult: lookupResult,
        isLookingUpFriendCode: false,
      );
    } on CloudFnException catch (e) {
      state = state.copyWith(
        isLookingUpFriendCode: false,
        error: e.message ?? 'Failed to look up friend code',
        clearFriendCodeLookup: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLookingUpFriendCode: false,
        error: 'Failed to look up friend code',
        clearFriendCodeLookup: true,
      );
    }
  }

  /// Send a friend request using a friend code
  Future<bool> sendFriendRequestByCode(String friendCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await callFn('sendFriendRequestByCode',
          {'friendCode': friendCode.toUpperCase()});
      state = state.copyWith(isLoading: false, clearFriendCodeLookup: true);
      return true;
    } on CloudFnException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.message ?? 'Failed to send friend request');
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to send friend request');
      return false;
    }
  }

  /// Clear the friend code lookup result
  void clearFriendCodeLookup() {
    state = state.copyWith(clearFriendCodeLookup: true);
  }
}

/// Provider for friend operations
final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});
