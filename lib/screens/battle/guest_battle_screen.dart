import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/question_model.dart';
import '../../services/firebase_service.dart';
import '../../services/local_stats_service.dart';
import '../../providers/session_provider.dart';

/// Guest battle state
class GuestBattleState {
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final int playerHealth;
  final int botHealth;
  final int playerScore;
  final int botScore;
  final bool isLoading;
  final String? error;
  final bool isComplete;
  final bool? playerWon;
  final DateTime? questionStartTime;
  final int timeRemaining;

  const GuestBattleState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.playerHealth = 100,
    this.botHealth = 100,
    this.playerScore = 0,
    this.botScore = 0,
    this.isLoading = false,
    this.error,
    this.isComplete = false,
    this.playerWon,
    this.questionStartTime,
    this.timeRemaining = 30,
  });

  QuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;

  bool get hasMoreQuestions => currentQuestionIndex < questions.length - 1;

  GuestBattleState copyWith({
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    int? playerHealth,
    int? botHealth,
    int? playerScore,
    int? botScore,
    bool? isLoading,
    String? error,
    bool? isComplete,
    bool? playerWon,
    DateTime? questionStartTime,
    int? timeRemaining,
  }) {
    return GuestBattleState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      playerHealth: playerHealth ?? this.playerHealth,
      botHealth: botHealth ?? this.botHealth,
      playerScore: playerScore ?? this.playerScore,
      botScore: botScore ?? this.botScore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isComplete: isComplete ?? this.isComplete,
      playerWon: playerWon ?? this.playerWon,
      questionStartTime: questionStartTime ?? this.questionStartTime,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }
}

/// Guest battle notifier
class GuestBattleNotifier extends StateNotifier<GuestBattleState> {
  final Ref _ref;
  Timer? _timer;
  final Random _random = Random();

  // Bot difficulty settings
  static const double _botAccuracy = 0.65; // 65% chance bot answers correctly
  static const int _botMinTime = 5; // Min seconds bot takes to answer
  static const int _botMaxTime = 20; // Max seconds bot takes to answer

  GuestBattleNotifier(this._ref) : super(const GuestBattleState());

  /// Start a new guest battle
  Future<void> startBattle() async {
    state = const GuestBattleState(isLoading: true);

    try {
      final firebaseService = _ref.read(firebaseServiceProvider);

      // Fetch random questions for the battle
      final questions =
          await firebaseService.getRandomQuestionsForBattle(count: 10);

      if (questions.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No questions available. Please try again later.',
        );
        return;
      }

      state = state.copyWith(
        questions: questions,
        isLoading: false,
        questionStartTime: DateTime.now(),
        timeRemaining: 30,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start battle: $e',
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining <= 1) {
        // Time's up - treat as wrong answer
        _handleTimeout();
      } else {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();

    // Player takes self-damage for timeout
    final newPlayerHealth = (state.playerHealth - 15).clamp(0, 100);

    // Simulate bot answer (bot has time to answer since player timed out)
    final botCorrect = _random.nextDouble() < _botAccuracy;
    int newBotHealth = state.botHealth;
    int newBotScore = state.botScore;

    if (botCorrect) {
      // Bot scores but doesn't deal extra damage since player already penalized by timeout
      newBotScore += 1;
    }

    _processRoundEnd(
        newPlayerHealth, newBotHealth, state.playerScore, newBotScore);
  }

  /// Submit player's answer
  Future<void> submitAnswer(int selectedAnswer) async {
    if (state.currentQuestion == null || state.isComplete) return;

    _timer?.cancel();

    final question = state.currentQuestion!;
    final isCorrect = question.isAnswerCorrect(selectedAnswer);
    final timeSpent =
        DateTime.now().difference(state.questionStartTime!).inSeconds;

    // Calculate player results
    int newPlayerHealth = state.playerHealth;
    int newBotHealth = state.botHealth;
    int newPlayerScore = state.playerScore;
    int newBotScore = state.botScore;

    if (isCorrect) {
      // Player deals damage to bot
      final damage = _calculateDamage(timeSpent);
      newBotHealth = (state.botHealth - damage).clamp(0, 100);
      newPlayerScore += 1;
    } else {
      // Player takes self-damage
      newPlayerHealth = (state.playerHealth - 8).clamp(0, 100);
    }

    // Simulate bot answer
    final botAnswerTime =
        _random.nextInt(_botMaxTime - _botMinTime) + _botMinTime;
    final botCorrect = _random.nextDouble() < _botAccuracy;

    if (botCorrect) {
      // Bot deals damage to player
      final botDamage = _calculateDamage(botAnswerTime);
      newPlayerHealth = (newPlayerHealth - botDamage).clamp(0, 100);
      newBotScore += 1;
    } else {
      // Bot takes self-damage
      newBotHealth = (newBotHealth - 8).clamp(0, 100);
    }

    // Update local stats for guest
    final localStatsService = _ref.read(localStatsServiceProvider);
    await localStatsService.updateGuestStats(
      questionId: question.id,
      sectionKey: question.sectionKey,
      isCorrect: isCorrect,
      skill: question.skill,
      xpEarned: isCorrect ? 10 : 5,
    );

    _processRoundEnd(
        newPlayerHealth, newBotHealth, newPlayerScore, newBotScore);
  }

  void _processRoundEnd(
      int playerHealth, int botHealth, int playerScore, int botScore) {
    // Check for battle end conditions
    bool isComplete = false;
    bool? playerWon;

    if (playerHealth <= 0 || botHealth <= 0) {
      isComplete = true;
      playerWon = playerHealth > botHealth;
    } else if (!state.hasMoreQuestions) {
      isComplete = true;
      playerWon = playerScore > botScore ||
          (playerScore == botScore && playerHealth > botHealth);
    }

    if (isComplete) {
      state = state.copyWith(
        playerHealth: playerHealth,
        botHealth: botHealth,
        playerScore: playerScore,
        botScore: botScore,
        isComplete: true,
        playerWon: playerWon,
      );

      // Update battle stats
      _updateBattleStats(playerWon ?? false);
    } else {
      // Move to next question
      state = state.copyWith(
        playerHealth: playerHealth,
        botHealth: botHealth,
        playerScore: playerScore,
        botScore: botScore,
        currentQuestionIndex: state.currentQuestionIndex + 1,
        questionStartTime: DateTime.now(),
        timeRemaining: 30,
      );
      _startTimer();
    }
  }

  Future<void> _updateBattleStats(bool playerWon) async {
    final localStatsService = _ref.read(localStatsServiceProvider);
    await localStatsService.updateGuestBattleStats(isWinner: playerWon);

    // Refresh guest stats
    _ref.invalidate(guestStatsProvider);
  }

  int _calculateDamage(int timeSpentSeconds) {
    if (timeSpentSeconds <= 15) return 15;
    if (timeSpentSeconds <= 30) return 12;
    return 10;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final guestBattleProvider =
    StateNotifierProvider.autoDispose<GuestBattleNotifier, GuestBattleState>(
        (ref) {
  return GuestBattleNotifier(ref);
});

/// Guest Battle Screen
class GuestBattleScreen extends ConsumerStatefulWidget {
  const GuestBattleScreen({super.key});

  @override
  ConsumerState<GuestBattleScreen> createState() => _GuestBattleScreenState();
}

class _GuestBattleScreenState extends ConsumerState<GuestBattleScreen> {
  @override
  void initState() {
    super.initState();
    // Start battle when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guestBattleProvider.notifier).startBattle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(guestBattleProvider);

    if (battleState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle vs Bot')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding an opponent...'),
            ],
          ),
        ),
      );
    }

    if (battleState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Battle vs Bot'),
          automaticallyImplyLeading: false,
        ),
        body: _GuestBattleErrorState(
          error: battleState.error!,
          onGoHome: () => context.go(Routes.home),
          onRetry: () => ref.read(guestBattleProvider.notifier).startBattle(),
        ),
      );
    }

    if (battleState.isComplete) {
      return _BattleResultsView(
        playerWon: battleState.playerWon ?? false,
        playerScore: battleState.playerScore,
        botScore: battleState.botScore,
        playerHealth: battleState.playerHealth,
        botHealth: battleState.botHealth,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Question ${battleState.currentQuestionIndex + 1}/${battleState.questions.length}'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'quit') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Quit Battle?'),
                    content: const Text(
                        'Are you sure you want to quit? Your progress will be lost.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Continue'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Quit'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.go(Routes.home);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'quit',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Quit', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Health bars
          _HealthBarsWidget(
            playerHealth: battleState.playerHealth,
            botHealth: battleState.botHealth,
            playerScore: battleState.playerScore,
            botScore: battleState.botScore,
          ),

          // Timer
          _TimerWidget(timeRemaining: battleState.timeRemaining),

          // Question
          Expanded(
            child: battleState.currentQuestion == null
                ? const Center(child: CircularProgressIndicator())
                : _QuestionWidget(
                    question: battleState.currentQuestion!,
                    onAnswerSelected: (answer) {
                      ref
                          .read(guestBattleProvider.notifier)
                          .submitAnswer(answer);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HealthBarsWidget extends StatelessWidget {
  final int playerHealth;
  final int botHealth;
  final int playerScore;
  final int botScore;

  const _HealthBarsWidget({
    required this.playerHealth,
    required this.botHealth,
    required this.playerScore,
    required this.botScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          // Player
          Expanded(
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 4),
                    Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                _HealthBar(health: playerHealth, isPlayer: true),
                const SizedBox(height: 4),
                Text('Score: $playerScore',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('VS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          // Bot
          Expanded(
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Study Bot',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.smart_toy, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                _HealthBar(health: botHealth, isPlayer: false),
                const SizedBox(height: 4),
                Text('Score: $botScore', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final int health;
  final bool isPlayer;

  const _HealthBar({required this.health, required this.isPlayer});

  @override
  Widget build(BuildContext context) {
    final color = health > 50
        ? Colors.green
        : health > 25
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment:
          isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text('$health HP',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: health / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final int timeRemaining;

  const _TimerWidget({required this.timeRemaining});

  @override
  Widget build(BuildContext context) {
    final isLow = timeRemaining <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: isLow ? Colors.red : AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '${timeRemaining}s',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isLow ? Colors.red : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionWidget extends StatelessWidget {
  final QuestionModel question;
  final Function(int) onAnswerSelected;

  const _QuestionWidget({
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Passage if present
          if (question.passage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.article_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Passage',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.passage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Question text
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          // Answer choices
          ...List.generate(question.choices.length, (index) {
            final letters = ['A', 'B', 'C', 'D'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: () => onAnswerSelected(index),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          letters[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.choices[index],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BattleResultsView extends StatelessWidget {
  final bool playerWon;
  final int playerScore;
  final int botScore;
  final int playerHealth;
  final int botHealth;

  const _BattleResultsView({
    required this.playerWon,
    required this.playerScore,
    required this.botScore,
    required this.playerHealth,
    required this.botHealth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Result icon
              Icon(
                playerWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 100,
                color: playerWon ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 24),

              // Result text
              Text(
                playerWon ? 'Victory!' : 'Defeat',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: playerWon
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                playerWon
                    ? 'You defeated the Study Bot!'
                    : 'The Study Bot won this time. Try again!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Stats
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _StatRow(label: 'Your Score', value: '$playerScore'),
                    const Divider(),
                    _StatRow(label: 'Bot Score', value: '$botScore'),
                    const Divider(),
                    _StatRow(label: 'Your Health', value: '$playerHealth HP'),
                    const Divider(),
                    _StatRow(label: 'Bot Health', value: '$botHealth HP'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Guest mode notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sign up to battle real players and climb the leaderboard!',
                        style: TextStyle(
                            color: AppTheme.primaryColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(Routes.guestBattle),
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Error state widget for guest battles with clear navigation options
class _GuestBattleErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onGoHome;
  final VoidCallback onRetry;

  const _GuestBattleErrorState({
    required this.error,
    required this.onGoHome,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the error is about no questions available
    final isNoQuestionsError = error.toLowerCase().contains('no questions');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (isNoQuestionsError
                        ? AppTheme.warningColor
                        : AppTheme.errorColor)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoQuestionsError ? Icons.quiz_outlined : Icons.error_outline,
                size: 50,
                color: isNoQuestionsError
                    ? AppTheme.warningColor
                    : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              isNoQuestionsError
                  ? 'No Questions Available'
                  : 'Unable to Start Battle',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),

            // Description
            const SizedBox(height: 12),
            Text(
              isNoQuestionsError
                  ? 'There are no battle questions available right now. New questions are added regularly, so please check back soon!'
                  : error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
            ),

            const SizedBox(height: 32),

            // Primary action: Go Home
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onGoHome,
                icon: const Icon(Icons.home),
                label: const Text('Return to Home'),
              ),
            ),

            // Secondary action: Try Again
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
