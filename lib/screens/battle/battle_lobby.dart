import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/battle_model.dart';
import '../../providers/battle_provider.dart';
import '../../providers/session_provider.dart';

class BattleLobby extends ConsumerStatefulWidget {
  const BattleLobby({super.key});

  @override
  ConsumerState<BattleLobby> createState() => _BattleLobbyState();
}

class _BattleLobbyState extends ConsumerState<BattleLobby>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedTestType;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // If opened via a battle invite notification, subscribe to that specific battle.
    // Also falls back to the pendingBattleInviteProvider (handles GoRouter recreation
    // on auth-state changes, which can discard the initial notification navigation).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Primary: battleId from notification URL query param
      final battleId = GoRouterState.of(context).uri.queryParameters['battleId'];
      if (battleId != null && battleId.isNotEmpty) {
        ref.read(battleProvider.notifier).subscribeToInvitedBattle(battleId);
        return;
      }
      // Fallback: subscribe from the current pending invite node in RTDB
      final invite = ref.read(pendingBattleInviteProvider).valueOrNull;
      if (invite != null) {
        final bid = invite['battleId'] as String?;
        if (bid != null) {
          ref.read(battleProvider.notifier).subscribeToInvitedBattle(bid);
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleProvider);
    final userData = ref.watch(effectiveUserDataProvider);

    // Handle battle phase changes
    ref.listen(battleProvider, (previous, next) {
      if (next.phase == BattlePhase.playing && previous?.phase != BattlePhase.playing) {
        context.go('${Routes.battleScreen}?battleId=${next.battle!.id}');
      }
    });

    // Auto-subscribe when a pending invite arrives while the lobby is open
    // (covers cases where the invite arrives after the lobby mounted)
    ref.listen(pendingBattleInviteProvider, (_, next) {
      final invite = next.valueOrNull;
      if (invite != null) {
        final bid = invite['battleId'] as String?;
        if (bid != null) {
          ref.read(battleProvider.notifier).subscribeToInvitedBattle(bid);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(battleProvider.notifier).leaveBattle();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              if (battleState.phase == BattlePhase.invited) ...[
                // Invited friend: show Accept / Decline UI
                Icon(
                  Icons.sports_esports,
                  size: 80,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Battle Challenge!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${battleState.battle?.player1.username ?? "A friend"} challenged you to a battle!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '20 questions • 30 sec each',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: battleState.isSubmitting
                            ? null
                            : () => ref
                                .read(battleProvider.notifier)
                                .declineFriendBattle(battleState.battle!.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: battleState.isSubmitting
                            ? null
                            : () => ref
                                .read(battleProvider.notifier)
                                .acceptFriendBattle(battleState.battle!.id),
                        child: battleState.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ] else if (battleState.phase == BattlePhase.idle) ...[
                // Idle state - show battle info
                const Icon(
                  Icons.flash_on,
                  size: 80,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  '1v1 Quiz Battle',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Challenge another student to a 20-question showdown!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Test type selector
                Text(
                  'Choose Your Exam',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TestTypeCard(
                        label: 'SAT',
                        isSelected: _selectedTestType == 'SAT',
                        onTap: () {
                          setState(() {
                            _selectedTestType = 'SAT';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TestTypeCard(
                        label: 'ACT',
                        isSelected: _selectedTestType == 'ACT',
                        onTap: () {
                          setState(() {
                            _selectedTestType = 'ACT';
                          });
                        },
                      ),
                    ),
                  ],
                ),

                if (_selectedTestType != null) ...[
                  const SizedBox(height: 32),

                  // Battle rules
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _RuleItem(
                          icon: Icons.quiz,
                          text: '20 questions',
                        ),
                        const SizedBox(height: 12),
                        _RuleItem(
                          icon: Icons.timer,
                          text: '30 seconds per question',
                        ),
                        const SizedBox(height: 12),
                        _RuleItem(
                          icon: Icons.favorite,
                          text: 'Health-based combat',
                        ),
                        const SizedBox(height: 12),
                        _RuleItem(
                          icon: Icons.star,
                          text: 'Winner gets 50 XP, loser gets 20 XP',
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (battleState.phase == BattlePhase.matchmaking) ...[
                // Searching for opponent OR waiting for friend to accept
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + (_pulseController.value * 0.1),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 60,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  battleState.battle != null
                      ? 'Waiting for Response...'
                      : 'Finding Opponent...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  battleState.battle != null
                      ? 'Waiting for ${battleState.battle!.player2?.username ?? "your friend"} to accept your challenge'
                      : 'Matching you with a ${_selectedTestType ?? ''} player near your level',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ] else if (battleState.phase == BattlePhase.found) ...[
                // Opponent found
                Text(
                  'Opponent Found!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 32),

                // VS display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current user
                    _PlayerDisplay(
                      username: userData?.username ?? 'You',
                      profilePictureUrl: userData?.profilePictureUrl,
                      level: userData?.level ?? 1,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      'VS',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Opponent
                    _PlayerDisplay(
                      username: battleState.battle?.player2?.username ?? 'Opponent',
                      profilePictureUrl: battleState.battle?.player2?.profilePictureUrl,
                      level: battleState.battle?.player2?.level ?? 1,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Battle starting...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],

              if (battleState.error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    battleState.error!,
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action button — hidden when showing inline Accept/Decline for invitee
              if (battleState.phase != BattlePhase.invited)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: battleState.phase == BattlePhase.idle
                      ? ElevatedButton(
                          onPressed: _selectedTestType == null
                              ? null
                              : () {
                                  ref.read(battleProvider.notifier).joinMatchmaking(
                                    testType: _selectedTestType!,
                                  );
                                },
                          child: const Text('Find Battle'),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            // If waiting for a friend to accept, cancel the invite on the server too
                            if (battleState.battle != null &&
                                battleState.battle!.status == BattleStatus.waiting) {
                              ref.read(battleProvider.notifier).cancelFriendBattleInvite();
                            } else {
                              ref.read(battleProvider.notifier).leaveBattle();
                            }
                          },
                          child: const Text('Cancel'),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestTypeCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TestTypeCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _PlayerDisplay extends StatelessWidget {
  final String username;
  final String? profilePictureUrl;
  final int level;

  const _PlayerDisplay({
    required this.username,
    this.profilePictureUrl,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: profilePictureUrl != null
                ? CachedNetworkImage(
                    imageUrl: profilePictureUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.person, size: 40),
                    errorWidget: (_, __, ___) => const Icon(Icons.person, size: 40),
                  )
                : const Icon(Icons.person, size: 40, color: AppTheme.textTertiary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          username,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Level $level',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
