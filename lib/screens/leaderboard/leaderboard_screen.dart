import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/common/loading_overlay.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Pre-load friends leaderboard so it's ready when the user taps the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currentUserIdProvider) != null) {
        ref.read(leaderboardProvider.notifier).loadFriendsLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final type = _tabController.index == 0
          ? LeaderboardType.global
          : LeaderboardType.friends;

      // Don't trigger friends load while auth is still loading —
      // avoids unauthenticated Cloud Function calls before auth state is ready
      if (type == LeaderboardType.friends &&
          ref.read(currentUserIdProvider) == null) return;

      ref.read(leaderboardProvider.notifier).setLeaderboardType(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Global leaderboard
          _LeaderboardContent(
            entries: leaderboardState.globalEntries,
            isLoading: leaderboardState.isLoading &&
                leaderboardState.currentType == LeaderboardType.global,
            error: leaderboardState.currentType == LeaderboardType.global
                ? leaderboardState.error : null,
            currentUserId: currentUserId,
            emptyTitle: 'No rankings yet',
            emptySubtitle: 'Be the first to climb the leaderboard!',
            onRefresh: () => ref.read(leaderboardProvider.notifier).loadGlobalLeaderboard(),
          ),
          // Friends leaderboard - require sign-in
          if (currentUserId == null)
            _SignInRequired(
              message: 'Sign in to see how you rank among your friends.',
              onSignIn: () => context.go(Routes.login),
            )
          else
            _LeaderboardContent(
              entries: leaderboardState.friendsEntries,
              isLoading: leaderboardState.isLoading &&
                  leaderboardState.currentType == LeaderboardType.friends,
              error: leaderboardState.currentType == LeaderboardType.friends
                  ? leaderboardState.error : null,
              currentUserId: currentUserId,
              emptyTitle: 'No friends yet',
              emptySubtitle: 'Add friends to see how you compare!',
              onRefresh: () => ref.read(leaderboardProvider.notifier).loadFriendsLeaderboard(),
            ),
        ],
      ),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final String? currentUserId;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  const _LeaderboardContent({
    required this.entries,
    required this.isLoading,
    this.error,
    this.currentUserId,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && entries.isEmpty) {
      return ErrorDisplay(
        message: error!,
        onRetry: onRefresh,
      );
    }

    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.leaderboard,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    // Only show podium when there are at least 3 entries
    final hasPodium = entries.length >= 3;
    final podiumCount = hasPodium ? 3 : 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          // Top 3 podium (only when 3+ players)
          if (hasPodium)
            _TopThreePodium(
              first: entries[0],
              second: entries[1],
              third: entries[2],
              currentUserId: currentUserId,
            ),

          // All remaining entries (or all entries if no podium)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length - podiumCount,
              itemBuilder: (context, index) {
                final entry = entries[index + podiumCount];
                final isCurrentUser = entry.odId == currentUserId;

                return _LeaderboardTile(
                  entry: entry,
                  isCurrentUser: isCurrentUser,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopThreePodium extends StatelessWidget {
  final LeaderboardEntry first;
  final LeaderboardEntry second;
  final LeaderboardEntry third;
  final String? currentUserId;

  const _TopThreePodium({
    required this.first,
    required this.second,
    required this.third,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          _PodiumItem(
            entry: second,
            rank: 2,
            height: 100,
            color: const Color(0xFFC0C0C0),
            isCurrentUser: second.odId == currentUserId,
          ),
          const SizedBox(width: 8),
          // 1st place
          _PodiumItem(
            entry: first,
            rank: 1,
            height: 130,
            color: const Color(0xFFFFD700),
            isCurrentUser: first.odId == currentUserId,
          ),
          const SizedBox(width: 8),
          // 3rd place
          _PodiumItem(
            entry: third,
            rank: 3,
            height: 80,
            color: const Color(0xFFCD7F32),
            isCurrentUser: third.odId == currentUserId,
          ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color color;
  final bool isCurrentUser;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final rankEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile picture
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentUser ? AppTheme.primaryColor : color,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: entry.profilePictureUrl != null
                ? CachedNetworkImage(
                    imageUrl: entry.profilePictureUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.person),
                    errorWidget: (_, __, ___) => const Icon(Icons.person),
                  )
                : const Icon(Icons.person, color: AppTheme.textTertiary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.username,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isCurrentUser ? AppTheme.primaryColor : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.totalXp} XP',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              rankEmoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInRequired extends StatelessWidget {
  final String message;
  final VoidCallback onSignIn;

  const _SignInRequired({required this.message, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 44,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign In Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onSignIn,
                child: const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ),

          // Profile picture
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: entry.profilePictureUrl != null
                  ? CachedNetworkImage(
                      imageUrl: entry.profilePictureUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.person, size: 24),
                      errorWidget: (_, __, ___) => const Icon(Icons.person, size: 24),
                    )
                  : const Icon(Icons.person, size: 24, color: AppTheme.textTertiary),
            ),
          ),

          // Username and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser ? AppTheme.primaryColor : null,
                  ),
                ),
                Text(
                  'Level ${entry.level}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // XP
          Text(
            '${entry.totalXp} XP',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
