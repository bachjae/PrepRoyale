import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/formatted_text.dart';

class BattleScreen extends ConsumerWidget {
  final String battleId;

  const BattleScreen({super.key, required this.battleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battleState = ref.watch(battleProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // Handle battle completion
    ref.listen(battleProvider, (previous, next) {
      if (next.phase == BattlePhase.finished && previous?.phase != BattlePhase.finished) {
        context.go('${Routes.battleResults}?battleId=${next.battle!.id}');
      }
    });

    // Handle error state
    if (battleState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Battle'),
          automaticallyImplyLeading: false,
        ),
        body: ErrorDisplay(
          message: battleState.error!,
          onGoBack: () {
            ref.read(battleProvider.notifier).leaveBattle();
            context.go(Routes.home);
          },
          goBackLabel: 'Return to Home',
        ),
      );
    }

    // Loading state - battle or question not yet available
    if (battleState.battle == null || battleState.currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Battle'),
          automaticallyImplyLeading: false,
          actions: [
            // Allow users to exit if loading takes too long
            TextButton(
              onPressed: () {
                ref.read(battleProvider.notifier).leaveBattle();
                context.go(Routes.home);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading battle...'),
              SizedBox(height: 8),
              Text(
                'Please wait while we set up your match',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final battle = battleState.battle!;
    final question = battleState.currentQuestion!;
    final isPlayer1 = battle.player1.odId == currentUserId;
    final myPlayer = isPlayer1 ? battle.player1 : battle.player2!;
    final opponent = isPlayer1 ? battle.player2! : battle.player1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 40,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'forfeit') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Forfeit Battle?'),
                    content: const Text(
                        'You will lose and your opponent will win. Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Forfeit'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  ref.read(battleProvider.notifier).forfeitBattle();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'forfeit',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Forfeit', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Players header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // My health
                  Expanded(
                    child: _PlayerHealth(
                      username: myPlayer.username,
                      profilePictureUrl: myPlayer.profilePictureUrl,
                      health: myPlayer.health,
                      isMe: true,
                    ),
                  ),
                  // Timer
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: battleState.timeRemaining <= 10
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: battleState.timeRemaining <= 10
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${battleState.timeRemaining}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: battleState.timeRemaining <= 10
                              ? AppTheme.errorColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  // Opponent health
                  Expanded(
                    child: _PlayerHealth(
                      username: opponent.username,
                      profilePictureUrl: opponent.profilePictureUrl,
                      health: opponent.health,
                      isMe: false,
                    ),
                  ),
                ],
              ),
            ),

            // Question progress (per-player: shows MY personal progress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(battle.totalQuestions, (index) {
                  final isCurrent = index == battleState.myAnswerCount;
                  final isCompleted = index < battleState.myAnswerCount;

                  return Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.successColor
                            : isCurrent
                                ? AppTheme.primaryColor
                                : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Question ${(battleState.myAnswerCount + 1).clamp(1, battle.totalQuestions)} of ${battle.totalQuestions}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Passage if present
                    if (question.passage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FormattedText(
                          text: question.passage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (const ['Reading', 'Writing', 'English', 'Science']
                        .contains(question.section)) ...[
                      // Passage-based question type but no passage stored —
                      // show a notice so the question is still answerable
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.warningColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: AppTheme.warningColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Passage not available for this question.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.warningColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Question text
                    FormattedText(
                      text: question.questionText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Answer choices
                    ...List.generate(4, (index) {
                      final letters = ['A', 'B', 'C', 'D'];
                      final isSelected = battleState.selectedAnswer == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BattleAnswerChoice(
                          letter: letters[index],
                          text: question.choices[index],
                          isSelected: isSelected,
                          isDisabled: battleState.isSubmitting,
                          onTap: () {
                            ref.read(battleProvider.notifier).selectAnswer(index);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: battleState.selectedAnswer != null && !battleState.isSubmitting
                      ? () {
                          ref.read(battleProvider.notifier)
                              .submitAnswer(battleState.selectedAnswer!);
                        }
                      : null,
                  child: battleState.isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Answer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHealth extends StatelessWidget {
  final String username;
  final String? profilePictureUrl;
  final int health;
  final bool isMe;

  const _PlayerHealth({
    required this.username,
    this.profilePictureUrl,
    required this.health,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final healthFraction = (health / 100.0).clamp(0.0, 1.0);
    final Color healthColor = health > 50
        ? AppTheme.successColor
        : health > 25
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe ? AppTheme.primaryColor : AppTheme.secondaryColor,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: profilePictureUrl != null
                ? CachedNetworkImage(
                    imageUrl: profilePictureUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.person, size: 28),
                    errorWidget: (_, __, ___) => const Icon(Icons.person, size: 28),
                  )
                : const Icon(Icons.person, size: 28, color: AppTheme.textTertiary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isMe ? 'You' : username,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: LinearProgressIndicator(
            value: healthFraction,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$health HP',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: healthColor,
          ),
        ),
      ],
    );
  }
}

class _BattleAnswerChoice extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _BattleAnswerChoice({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormattedText(
                  text: text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
