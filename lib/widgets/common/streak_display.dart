import 'package:flutter/material.dart';

import '../../config/theme.dart';

enum StreakType { daily, accuracy }

class StreakDisplay extends StatelessWidget {
  final StreakType type;
  final int count;
  final int? best;
  final bool compact;

  const StreakDisplay({
    super.key,
    required this.type,
    required this.count,
    this.best,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == StreakType.daily
        ? AppTheme.dailyStreakColor
        : AppTheme.accuracyStreakColor;
    final emoji = type == StreakType.daily ? '🔥' : '⚡';
    final label = type == StreakType.daily ? 'Daily Streak' : 'Accuracy Streak';

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                type == StreakType.daily ? 'days' : 'correct',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (best != null) ...[
            const SizedBox(height: 4),
            Text(
              'Best: $best',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StreakRow extends StatelessWidget {
  final int dailyStreak;
  final int accuracyStreak;
  final int? dailyBest;
  final int? accuracyBest;

  const StreakRow({
    super.key,
    required this.dailyStreak,
    required this.accuracyStreak,
    this.dailyBest,
    this.accuracyBest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StreakDisplay(
            type: StreakType.daily,
            count: dailyStreak,
            best: dailyBest,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreakDisplay(
            type: StreakType.accuracy,
            count: accuracyStreak,
            best: accuracyBest,
          ),
        ),
      ],
    );
  }
}
