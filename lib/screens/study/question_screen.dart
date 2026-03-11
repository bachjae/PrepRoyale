import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/question_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/formatted_text.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  int? _selectedAnswer;
  bool _isSubmitting = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int? _lastQuestionIndex;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studySessionProvider);

    // Reset selection state when question index changes
    if (session != null && _lastQuestionIndex != session.currentIndex) {
      _lastQuestionIndex = session.currentIndex;
      _selectedAnswer = null;
      _startTimer();
    }

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active study session'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (session.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading questions...'),
            ],
          ),
        ),
      );
    }

    if (session.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              '${session.examType.name.toUpperCase()} ${_capitalize(session.section)}'),
          automaticallyImplyLeading: false,
        ),
        body: ErrorDisplay(
          message: session.error!,
          onGoBack: () {
            ref.read(studySessionProvider.notifier).endSession();
            context.go(Routes.home);
          },
          goBackLabel: 'Return to Home',
          onRetry: () {
            ref.read(studySessionProvider.notifier).startSession(
                  session.examType,
                  session.section,
                );
          },
        ),
      );
    }

    final question = session.currentQuestion;
    if (question == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              '${session.examType.name.toUpperCase()} ${_capitalize(session.section)}'),
          automaticallyImplyLeading: false,
        ),
        body: EmptyStateWithActions(
          icon: Icons.quiz_outlined,
          title: 'No Questions Available',
          description:
              'There are no ${session.examType.name.toUpperCase()} ${_capitalize(session.section)} questions available right now. New questions are added regularly, so please check back later.',
          primaryActionLabel: 'Return to Home',
          primaryActionIcon: Icons.home,
          onPrimaryAction: () {
            ref.read(studySessionProvider.notifier).endSession();
            context.go(Routes.home);
          },
          secondaryActionLabel: 'Try Again',
          secondaryActionIcon: Icons.refresh,
          onSecondaryAction: () {
            ref.read(studySessionProvider.notifier).startSession(
                  session.examType,
                  session.section,
                );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${session.examType.name.toUpperCase()} ${_capitalize(session.section)}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar already handles the top inset
        child: LoadingOverlay(
          isLoading: _isSubmitting,
          message: 'Submitting answer...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Question counter
              Text(
                'Question ${session.currentIndex + 1}',
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
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Passage',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FormattedText(
                        text: question.passage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Question text
              FormattedText(
                text: question.questionText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 24),

              // Answer choices
              ...List.generate(4, (index) {
                final letters = ['A', 'B', 'C', 'D'];
                final isSelected = _selectedAnswer == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnswerChoice(
                    letter: letters[index],
                    text: question.choices[index],
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedAnswer = index),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedAnswer != null ? _submitAnswer : null,
                  child: const Text('Submit Answer'),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) return;

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final result = await ref
          .read(studySessionProvider.notifier)
          .submitAnswer(_selectedAnswer!);

      if (!mounted) return;

      context.push(Routes.answerFeedback, extra: {
        'isCorrect': result.isCorrect,
        'selectedAnswer': result.selectedAnswer,
        'correctAnswer': result.correctAnswer,
        'explanation': result.explanation,
        'xpEarned': result.xpEarned,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Study Mode?'),
        content: const Text('Your progress on this question will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(studySessionProvider.notifier).endSession();
              context.go(Routes.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _AnswerChoice extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerChoice({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.1)
          : AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE2E8F0),
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
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
