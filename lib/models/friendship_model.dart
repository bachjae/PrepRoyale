import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum FriendshipStatus { pending, accepted, blocked }

/// Represents a friendship between two users.
/// Uses normalized user IDs (alphabetically sorted) for consistent document structure.
class FriendshipModel extends Equatable {
  final String id;
  final String user1Id; // Alphabetically smaller user ID
  final String user2Id; // Alphabetically larger user ID
  final FriendshipStatus status;
  final String requesterId; // Who initiated the friend request
  final String? requesterUsername;
  final String? requesterProfilePictureUrl;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const FriendshipModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.requesterId,
    this.requesterUsername,
    this.requesterProfilePictureUrl,
    required this.createdAt,
    this.acceptedAt,
  });

  /// Get the friend's user ID given the current user's ID
  String getFriendId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  /// Check if the current user is the requester
  bool isRequester(String currentUserId) {
    return requesterId == currentUserId;
  }

  /// Check if the current user is the recipient (can respond to request)
  bool isRecipient(String currentUserId) {
    return (user1Id == currentUserId || user2Id == currentUserId) &&
        requesterId != currentUserId;
  }

  factory FriendshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendshipModel(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      requesterId: data['requesterId'] ?? '',
      requesterUsername: data['requesterUsername'],
      requesterProfilePictureUrl: data['requesterProfilePictureUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'status': status.name,
      'requesterId': requesterId,
      'requesterUsername': requesterUsername,
      'requesterProfilePictureUrl': requesterProfilePictureUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
    };
  }

  FriendshipModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    FriendshipStatus? status,
    String? requesterId,
    String? requesterUsername,
    String? requesterProfilePictureUrl,
    DateTime? createdAt,
    DateTime? acceptedAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      status: status ?? this.status,
      requesterId: requesterId ?? this.requesterId,
      requesterUsername: requesterUsername ?? this.requesterUsername,
      requesterProfilePictureUrl:
          requesterProfilePictureUrl ?? this.requesterProfilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        user1Id,
        user2Id,
        status,
        requesterId,
        requesterUsername,
        requesterProfilePictureUrl,
        createdAt,
        acceptedAt,
      ];
}

/// Represents a friend with their full profile information.
/// Used for displaying friends lists with user details.
class FriendWithProfile extends Equatable {
  final String odId; // Friend's user ID
  final String username;
  final String? profilePictureUrl;
  final int level;
  final int totalXp;
  final String friendshipId; // Reference to the FriendshipModel

  const FriendWithProfile({
    required this.odId,
    required this.username,
    this.profilePictureUrl,
    required this.level,
    required this.totalXp,
    required this.friendshipId,
  });

  factory FriendWithProfile.fromMap(Map<String, dynamic> map, String friendshipId) {
    return FriendWithProfile(
      odId: map['odId'] ?? map['userId'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      level: map['level'] ?? 1,
      totalXp: map['totalXp'] ?? 0,
      friendshipId: friendshipId,
    );
  }

  @override
  List<Object?> get props => [
        odId,
        username,
        profilePictureUrl,
        level,
        totalXp,
        friendshipId,
      ];
}

/// Represents a pending friend request for display.
class FriendRequest extends Equatable {
  final String friendshipId;
  final String fromUserId;
  final String fromUsername;
  final String? fromProfilePictureUrl;
  final DateTime createdAt;

  const FriendRequest({
    required this.friendshipId,
    required this.fromUserId,
    required this.fromUsername,
    this.fromProfilePictureUrl,
    required this.createdAt,
  });

  factory FriendRequest.fromFriendship(FriendshipModel friendship) {
    return FriendRequest(
      friendshipId: friendship.id,
      fromUserId: friendship.requesterId,
      fromUsername: friendship.requesterUsername ?? 'Unknown',
      fromProfilePictureUrl: friendship.requesterProfilePictureUrl,
      createdAt: friendship.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        friendshipId,
        fromUserId,
        fromUsername,
        fromProfilePictureUrl,
        createdAt,
      ];
}

/// Represents a user search result.
class UserSearchResult extends Equatable {
  final String odId;
  final String username;
  final String? profilePictureUrl;
  final int level;

  const UserSearchResult({
    required this.odId,
    required this.username,
    this.profilePictureUrl,
    required this.level,
  });

  factory UserSearchResult.fromMap(Map<String, dynamic> map) {
    return UserSearchResult(
      odId: map['odId'] ?? map['userId'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      level: map['level'] ?? 1,
    );
  }

  @override
  List<Object?> get props => [odId, username, profilePictureUrl, level];
}
