import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/streak_display.dart';
import '../../widgets/common/xp_progress_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(Routes.editProfile),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          message: 'Failed to load profile',
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return const ErrorDisplay(message: 'User not found');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile header
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => context.push(Routes.profilePicture),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: user.profilePictureUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: user.profilePictureUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Icon(Icons.person, size: 48),
                                        errorWidget: (_, __, ___) => const Icon(Icons.person, size: 48),
                                      )
                                    : const Icon(Icons.person, size: 48, color: AppTheme.textTertiary),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Level and XP
                XpProgressBar(
                  level: user.level,
                  progress: user.levelProgress,
                  xpToNextLevel: user.xpToNextLevel,
                ),
                const SizedBox(height: 24),

                // Streaks
                StreakRow(
                  dailyStreak: user.dailyStreak.count,
                  accuracyStreak: user.accuracyStreak.current,
                  dailyBest: user.dailyStreak.best,
                  accuracyBest: user.accuracyStreak.best,
                ),
                const SizedBox(height: 24),

                // Stats section
                _SectionHeader(title: 'Study Stats', icon: Icons.bar_chart),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _StatRow(
                        label: 'Total Questions',
                        value: '${user.stats.totalQuestions}',
                      ),
                      const Divider(height: 24),
                      _StatRow(
                        label: 'Overall Accuracy',
                        value: '${(user.stats.overallAccuracy * 100).round()}%',
                      ),
                      if (user.stats.sectionAccuracy.isNotEmpty) ...[
                        const Divider(height: 24),
                        ...user.stats.sectionAccuracy.entries.map((entry) {
                          final parts = entry.key.split('_');
                          final label = '${parts[0].toUpperCase()} ${_capitalize(parts[1])}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StatRow(
                              label: label,
                              value: '${(entry.value * 100).round()}%',
                              isSubitem: true,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Battle stats
                _SectionHeader(title: 'Battle Stats', icon: Icons.flash_on),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _StatRow(
                        label: 'Battles Won',
                        value: '${user.battleStats.wins}',
                      ),
                      const Divider(height: 24),
                      _StatRow(
                        label: 'Battles Lost',
                        value: '${user.battleStats.losses}',
                      ),
                      const Divider(height: 24),
                      _StatRow(
                        label: 'Win Rate',
                        value: '${(user.battleStats.winRate * 100).round()}%',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Achievements button
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Achievements'),
                  subtitle: Text('${user.unlockedAchievements.length} unlocked'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.achievements),
                ),
                const SizedBox(height: 16),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                    label: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) {
                context.go(Routes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSubitem;

  const _StatRow({
    required this.label,
    required this.value,
    this.isSubitem = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSubitem ? AppTheme.textTertiary : AppTheme.textSecondary,
            fontSize: isSubitem ? 13 : null,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSubitem ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
