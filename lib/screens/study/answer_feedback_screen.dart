import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/question_provider.dart';

class AnswerFeedbackScreen extends ConsumerWidget {
  final bool isCorrect;
  final int selectedAnswer;
  final int correctAnswer;
  final String explanation;
  final int xpEarned;

  const AnswerFeedbackScreen({
    super.key,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letters = ['A', 'B', 'C', 'D'];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Result icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : AppTheme.errorColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 80,
                        color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Result text
                    Text(
                      isCorrect ? 'Correct!' : 'Incorrect',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (!isCorrect) ...[
                      Text(
                        'The correct answer was ${letters[correctAnswer]}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

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
                          const Icon(
                            Icons.star,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$xpEarned XP',
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

                    // Explanation
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppTheme.warningColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Explanation',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            explanation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Fixed action buttons at bottom
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(studySessionProvider.notifier).endSession();
                        context.go(Routes.home);
                      },
                      child: const Text('End Session'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Try to move to next question
                        final hasNext = ref.read(studySessionProvider.notifier).nextQuestion();

                        if (!hasNext && context.mounted) {
                          // No more questions in current batch, try to load more
                          final loaded = await ref.read(studySessionProvider.notifier).loadMoreQuestions();

                          if (!loaded && context.mounted) {
                            // No questions available - show message and go home
                            ref.read(studySessionProvider.notifier).endSession();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Great job! You\'ve completed all available questions for this section. Come back tomorrow for more!',
                                ),
                                duration: Duration(seconds: 4),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            context.go(Routes.home);
                            return;
                          }
                        }

                        if (context.mounted) context.go(Routes.question);
                      },
                      child: const Text('Next Question'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
