import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/battle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/local_stats_service.dart';

class BattleResults extends ConsumerStatefulWidget {
  final String battleId;

  const BattleResults({super.key, required this.battleId});

  @override
  ConsumerState<BattleResults> createState() => _BattleResultsState();
}

class _BattleResultsState extends ConsumerState<BattleResults> {
  bool _statsUpdated = false;

  @override
  void initState() {
    super.initState();
  }

  /// Update local stats for guest users after battle completion
  Future<void> _updateGuestBattleStats(bool isWinner) async {
    if (_statsUpdated) return;
    _statsUpdated = true;

    final isGuest = ref.read(isGuestModeProvider);
    if (!isGuest) return;

    final localStatsService = ref.read(localStatsServiceProvider);

    // Update battle stats
    await localStatsService.updateGuestBattleStats(isWinner: isWinner);

    // Award XP (50 for win, 20 for loss)
    final xpAmount = isWinner ? 50 : 20;
    await localStatsService.addGuestXp(xpAmount);

    // Refresh guest stats
    ref.read(userSessionProvider.notifier).refreshGuestStats();
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    if (battleState.battle == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Battle not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(battleProvider.notifier).leaveBattle();
                  context.go(Routes.home);
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    final battle = battleState.battle!;
    final isPlayer1 = battle.player1.odId == currentUserId;
    final myPlayer = isPlayer1 ? battle.player1 : battle.player2!;
    final opponent = isPlayer1 ? battle.player2! : battle.player1;
    final isWinner = battle.winnerId == currentUserId;
    // A tie is only when the server explicitly sets winnerId to null after completion
    final isTie = battle.status == BattleStatus.completed && battle.winnerId == null;

    // Update local stats for guest users
    if (!_statsUpdated) {
      _updateGuestBattleStats(isWinner);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Result icon and text
              if (isTie) ...[
                Icon(Icons.handshake, size: 64, color: AppTheme.warningColor),
                const SizedBox(height: 16),
                Text(
                  "It's a Tie!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ] else if (isWinner) ...[
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.emoji_events, size: 64, color: AppTheme.successColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Victory!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ] else ...[
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.shield_outlined, size: 64, color: AppTheme.errorColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Defeat',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // XP earned
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '+${isWinner ? 50 : 20} XP',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Health comparison
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // My health
                    Expanded(
                      child: _ResultPlayer(
                        username: 'You',
                        profilePictureUrl: myPlayer.profilePictureUrl,
                        health: myPlayer.health,
                        isWinner: isWinner && !isTie,
                      ),
                    ),
                    // VS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    // Opponent health
                    Expanded(
                      child: _ResultPlayer(
                        username: opponent.username,
                        profilePictureUrl: opponent.profilePictureUrl,
                        health: opponent.health,
                        isWinner: !isWinner && !isTie,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Match stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Questions Answered',
                      value: '${battle.totalQuestions}',
                    ),
                    const Divider(height: 24),
                    _StatRow(
                      label: 'Your HP Remaining',
                      value: '${myPlayer.health} HP',
                    ),
                    const Divider(height: 24),
                    _StatRow(
                      label: 'HP Difference',
                      value: '${(myPlayer.health - opponent.health).abs()}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(battleProvider.notifier).leaveBattle();
                        context.go(Routes.home);
                      },
                      child: const Text('Exit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(battleProvider.notifier).leaveBattle();
                        context.go(Routes.battleLobby);
                      },
                      child: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPlayer extends StatelessWidget {
  final String username;
  final String? profilePictureUrl;
  final int health;
  final bool isWinner;

  const _ResultPlayer({
    required this.username,
    this.profilePictureUrl,
    required this.health,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final healthFraction = (health / 100.0).clamp(0.0, 1.0);
    final Color healthBarColor = isWinner ? AppTheme.successColor : AppTheme.errorColor;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWinner ? AppTheme.successColor : const Color(0xFFE2E8F0),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: profilePictureUrl != null
                    ? CachedNetworkImage(
                        imageUrl: profilePictureUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(Icons.person, size: 36),
                        errorWidget: (_, __, ___) => const Icon(Icons.person, size: 36),
                      )
                    : const Icon(Icons.person, size: 36, color: AppTheme.textTertiary),
              ),
            ),
            if (isWinner)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          username,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$health',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isWinner ? AppTheme.successColor : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: LinearProgressIndicator(
            value: healthFraction,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(healthBarColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'HP',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
