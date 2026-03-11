import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/session_provider.dart';

class DetailedStatsScreen extends ConsumerWidget {
  const DetailedStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(effectiveUserDataProvider);

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stats')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Stats',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Stats Card
            _OverallStatsCard(userData: userData),
            const SizedBox(height: 20),

            // Streaks Card
            _StreaksCard(userData: userData),
            const SizedBox(height: 20),

            // Battle Stats Card
            _BattleStatsCard(userData: userData),
            const SizedBox(height: 20),

            // Section Performance
            _SectionPerformanceCard(userData: userData),
            const SizedBox(height: 20),

            // Skill Breakdown
            if (userData.skillStats.isNotEmpty) ...[
              _SkillBreakdownCard(userData: userData),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverallStatsCard extends StatelessWidget {
  final EffectiveUserData userData;

  const _OverallStatsCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      title: 'Overall Performance',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Questions Answered',
                  value: '${userData.totalQuestionsAnswered}',
                  icon: Icons.quiz_outlined,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Correct Answers',
                  value: '${userData.totalCorrect}',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Overall Accuracy',
                  value: '${(userData.overallAccuracy * 100).toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  valueColor: _getAccuracyColor(userData.overallAccuracy),
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Current Level',
                  value: '${userData.level}',
                  icon: Icons.star_outline,
                  valueColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatTile(
            label: 'Total XP Earned',
            value: '${userData.totalXp}',
            icon: Icons.bolt,
            valueColor: AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return AppTheme.successColor;
    if (accuracy >= 0.6) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}

class _StreaksCard extends StatelessWidget {
  final EffectiveUserData userData;

  const _StreaksCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      title: 'Streaks',
      icon: Icons.local_fire_department,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StreakTile(
                  label: 'Daily Streak',
                  current: userData.dailyStreak,
                  best: userData.bestDailyStreak,
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StreakTile(
                  label: 'Accuracy Streak',
                  current: userData.currentAccuracyStreak,
                  best: userData.bestAccuracyStreak,
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BattleStatsCard extends StatelessWidget {
  final EffectiveUserData userData;

  const _BattleStatsCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    final winRate = userData.battlesPlayed == 0
        ? 0.0
        : userData.battlesWon / userData.battlesPlayed;

    return _StatsCard(
      title: 'Battle Stats',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Battles Won',
                  value: '${userData.battlesWon}',
                  icon: Icons.emoji_events_outlined,
                  valueColor: AppTheme.successColor,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Battles Played',
                  value: '${userData.battlesPlayed}',
                  icon: Icons.sports_mma,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatTile(
            label: 'Win Rate',
            value: '${(winRate * 100).toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            valueColor: winRate >= 0.5 ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ],
      ),
    );
  }
}

class _SectionPerformanceCard extends StatelessWidget {
  final EffectiveUserData userData;

  const _SectionPerformanceCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    final sections = userData.sectionAccuracy.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return _StatsCard(
      title: 'Section Performance',
      icon: Icons.category_outlined,
      child: sections.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Answer questions to see your section performance!',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: sections.map((entry) {
                return _SectionAccuracyBar(
                  sectionName: EffectiveUserData.formatSectionName(entry.key),
                  accuracy: entry.value,
                );
              }).toList(),
            ),
    );
  }
}

class _SkillBreakdownCard extends StatelessWidget {
  final EffectiveUserData userData;

  const _SkillBreakdownCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    // Group skills by section
    final Map<String, List<MapEntry<String, EffectiveSkillStats>>> skillsBySection = {};

    for (final entry in userData.skillStats.entries) {
      final parts = entry.key.split('_');
      if (parts.length >= 2) {
        final sectionKey = '${parts[0]}_${parts[1]}';
        skillsBySection.putIfAbsent(sectionKey, () => []);
        skillsBySection[sectionKey]!.add(entry);
      }
    }

    return _StatsCard(
      title: 'Skill Breakdown',
      icon: Icons.psychology_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: skillsBySection.entries.map((sectionEntry) {
          final sectionName = EffectiveUserData.formatSectionName(sectionEntry.key);
          final skills = sectionEntry.value
            ..sort((a, b) => b.value.accuracy.compareTo(a.value.accuracy));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  sectionName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              ...skills.map((skillEntry) {
                final skillName = EffectiveUserData.formatSkillName(skillEntry.key);
                final stats = skillEntry.value;
                return _SkillRow(
                  skillName: skillName,
                  accuracy: stats.accuracy,
                  attempts: stats.totalAttempts,
                  correct: stats.correctAnswers,
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _StatsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StreakTile extends StatelessWidget {
  final String label;
  final int current;
  final int best;
  final IconData icon;
  final Color color;

  const _StreakTile({
    required this.label,
    required this.current,
    required this.best,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$current',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Best: $best',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionAccuracyBar extends StatelessWidget {
  final String sectionName;
  final double accuracy;

  const _SectionAccuracyBar({
    required this.sectionName,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getAccuracyColor(accuracy);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${(accuracy * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: accuracy.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return AppTheme.successColor;
    if (accuracy >= 0.6) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}

class _SkillRow extends StatelessWidget {
  final String skillName;
  final double accuracy;
  final int attempts;
  final int correct;

  const _SkillRow({
    required this.skillName,
    required this.accuracy,
    required this.attempts,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getAccuracyColor(accuracy);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              skillName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: accuracy.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '${(accuracy * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$correct/$attempts',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return AppTheme.successColor;
    if (accuracy >= 0.6) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
