import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/friendship_model.dart';
import '../../providers/friends_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/battle_provider.dart';
import '../../widgets/guest_mode_prompt.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh friend code when screen is opened
    Future.microtask(() {
      ref.read(friendsProvider.notifier).getMyFriendCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(isGuestModeProvider);

    // Show restricted screen for guests
    if (isGuest) {
      return const GuestRestrictedScreen(
        featureName: 'Friends',
        description:
            'Sign up to add friends, send challenges, and compete on the friends leaderboard!',
        icon: Icons.people_outline,
      );
    }

    final friendsAsync = ref.watch(friendsWithProfilesProvider);
    final pendingRequestsAsync = ref.watch(pendingRequestsStreamProvider);
    final friendsState = ref.watch(friendsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Friends'),
              const Tab(text: 'Leaderboard'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    pendingRequestsAsync.when(
                      data: (requests) => requests.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${requests.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => context.push('/friends/add'),
              tooltip: 'Add Friend',
            ),
          ],
        ),
        body: Column(
          children: [
            // My Friend Code card
            _MyFriendCodeCard(friendsState: friendsState),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  // Friends list tab
                  friendsAsync.when(
                    data: (friends) => friends.isEmpty
                        ? _buildEmptyFriends(context)
                        : _buildFriendsList(context, ref, friends),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  // Leaderboard tab
                  _buildLeaderboardTab(context, ref),
                  // Requests tab
                  pendingRequestsAsync.when(
                    data: (requests) => requests.isEmpty
                        ? _buildEmptyRequests(context)
                        : _buildRequestsList(
                            context, ref, requests, friendsState),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFriends(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to compete together!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/friends/add'),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friends'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequests(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No pending requests',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Friend requests will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    WidgetRef ref,
    List<FriendWithProfile> friends,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _FriendListTile(
          friend: friend,
          onChallenge: () => _challengeFriend(context, ref, friend),
        );
      },
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    WidgetRef ref,
    List<FriendRequest> requests,
    FriendsState state,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _FriendRequestTile(
          request: request,
          isLoading: state.isLoading,
        );
      },
    );
  }

  Widget _buildLeaderboardTab(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(friendsLeaderboardProvider);

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No leaderboard data found'));
        }
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              leading: Text('#${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              title: Text(entry.username),
              subtitle: Text('Level ${entry.level} • ${entry.totalXp} XP'),
              trailing: CircleAvatar(
                radius: 16,
                backgroundImage: entry.profilePictureUrl != null
                    ? CachedNetworkImageProvider(entry.profilePictureUrl!)
                    : null,
                child: entry.profilePictureUrl == null
                    ? Text(entry.username.isNotEmpty
                        ? entry.username[0].toUpperCase()
                        : '?')
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading leaderboard: $e')),
    );
  }

  Future<void> _challengeFriend(
      BuildContext context, WidgetRef ref, FriendWithProfile friend) async {
    final testType = await _showTestTypePicker(context);
    if (testType != null) {
      // Start the friend battle — this subscribes to RTDB internally.
      // Don't try to read battle?.id immediately; the RTDB listener hasn't
      // fired yet so it will be null. Navigate to the lobby instead —
      // it listens for phase == playing and auto-navigates to the battle screen.
      await ref.read(battleProvider.notifier).startFriendBattle(
            friendId: friend.odId,
            testType: testType,
          );
      if (context.mounted) {
        context.push(Routes.battleLobby);
      }
    }
  }

  Future<String?> _showTestTypePicker(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Challenge Friend'),
        content: const Text('Select the exam type for this battle:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'SAT'),
            child: const Text('SAT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'ACT'),
            child: const Text('ACT'),
          ),
        ],
      ),
    );
  }
}

class _MyFriendCodeCard extends StatelessWidget {
  final FriendsState friendsState;

  const _MyFriendCodeCard({required this.friendsState});

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'My Friend Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (friendsState.isLoadingFriendCode)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (friendsState.myFriendCode != null)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      friendsState.myFriendCode!,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                fontFamily: 'monospace',
                              ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () =>
                      _copyToClipboard(context, friendsState.myFriendCode!),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy code',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          else
            Text(
              'Unable to load friend code',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          const SizedBox(height: 8),
          Text(
            'Share this code with friends so they can add you!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _FriendListTile extends ConsumerWidget {
  final FriendWithProfile friend;
  final VoidCallback onChallenge;

  const _FriendListTile({
    required this.friend,
    required this.onChallenge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: friend.profilePictureUrl != null
            ? CachedNetworkImageProvider(friend.profilePictureUrl!)
            : null,
        child: friend.profilePictureUrl == null
            ? Text(friend.username.isNotEmpty
                ? friend.username[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Text(friend.username),
      subtitle: Text('Level ${friend.level}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visible challenge button
          Tooltip(
            message: 'Challenge to Battle',
            child: IconButton(
              icon: const Icon(Icons.sports_esports),
              color: AppTheme.secondaryColor,
              onPressed: onChallenge,
            ),
          ),
          // Three-dot menu for remove
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'remove') {
                final confirmed = await _showRemoveConfirmation(context);
                if (confirmed == true) {
                  ref
                      .read(friendsProvider.notifier)
                      .removeFriend(friend.friendshipId);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showRemoveConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove ${friend.username} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestTile extends ConsumerWidget {
  final FriendRequest request;
  final bool isLoading;

  const _FriendRequestTile({
    required this.request,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: request.fromProfilePictureUrl != null
            ? CachedNetworkImageProvider(request.fromProfilePictureUrl!)
            : null,
        child: request.fromProfilePictureUrl == null
            ? Text(request.fromUsername.isNotEmpty
                ? request.fromUsername[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Text(request.fromUsername),
      subtitle: Text('Sent ${request.createdAt.toLocal()}'),
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => ref
                      .read(friendsProvider.notifier)
                      .respondToFriendRequest(request.friendshipId, true),
                  tooltip: 'Accept',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => ref
                      .read(friendsProvider.notifier)
                      .respondToFriendRequest(request.friendshipId, false),
                  tooltip: 'Reject',
                ),
              ],
            ),
    );
  }
}
