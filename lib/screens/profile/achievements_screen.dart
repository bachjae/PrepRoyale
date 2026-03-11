import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/achievement_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/achievement_service.dart';
import '../../widgets/common/loading_overlay.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(message: 'Failed to load achievements'),
        data: (user) {
          if (user == null) {
            return const ErrorDisplay(message: 'User not found');
          }

          final achievementService = ref.read(achievementServiceProvider);
          final progressMap = achievementService.getAchievementProgress(user);
          final progressList = progressMap.values.toList();

          // Sort: unlocked first, then by progress
          progressList.sort((a, b) {
            if (a.isUnlocked && !b.isUnlocked) return -1;
            if (!a.isUnlocked && b.isUnlocked) return 1;
            return b.progressPercent.compareTo(a.progressPercent);
          });

          final unlockedCount = progressList.where((p) => p.isUnlocked).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlockedCount / ${progressList.length}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Achievements Unlocked',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category sections
                _buildCategorySection(
                  context,
                  'Study Progress',
                  Icons.school,
                  progressList.where((p) =>
                      p.achievement.category == AchievementCategory.questions).toList(),
                ),
                _buildCategorySection(
                  context,
                  'Streaks',
                  Icons.local_fire_department,
                  progressList.where((p) =>
                      p.achievement.category == AchievementCategory.streaks).toList(),
                ),
                _buildCategorySection(
                  context,
                  'Accuracy',
                  Icons.check_circle,
                  progressList.where((p) =>
                      p.achievement.category == AchievementCategory.accuracy).toList(),
                ),
                _buildCategorySection(
                  context,
                  'Battles',
                  Icons.flash_on,
                  progressList.where((p) =>
                      p.achievement.category == AchievementCategory.battles).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    List<AchievementProgress> achievements,
  ) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...achievements.map((progress) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AchievementCard(progress: progress),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementProgress progress;

  const _AchievementCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final achievement = progress.achievement;
    final isUnlocked = progress.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Emoji badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 24,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Achievement info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.progressPercent,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.primaryColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${progress.currentProgress}/${achievement.requirement}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
