import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

/// Notification settings screen
/// Allows users to configure which types of notifications they want to receive
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = false;

  Future<void> _updatePreference(
    UserModel user,
    NotificationPreferences newPreferences,
  ) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'notificationPreferences': newPreferences.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in'));
          }

          final prefs = user.notificationPreferences;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choose which notifications you want to receive',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Priority 1 Notifications
              _buildSectionHeader('Essential'),
              _buildNotificationTile(
                title: 'Friend Requests',
                subtitle: 'When someone sends you a friend request',
                icon: Icons.person_add,
                value: prefs.friendRequests,
                onChanged: (value) {
                  _updatePreference(
                    user,
                    prefs.copyWith(friendRequests: value),
                  );
                },
              ),
              _buildNotificationTile(
                title: 'Battle Invites',
                subtitle: 'When a friend challenges you to a battle',
                icon: Icons.sports_kabaddi,
                value: prefs.friendBattleInvites,
                onChanged: (value) {
                  _updatePreference(
                    user,
                    prefs.copyWith(friendBattleInvites: value),
                  );
                },
              ),
              _buildNotificationTile(
                title: 'Friend Request Accepted',
                subtitle: 'When someone accepts your friend request',
                icon: Icons.check_circle,
                value: prefs.friendRequestAccepted,
                onChanged: (value) {
                  _updatePreference(
                    user,
                    prefs.copyWith(friendRequestAccepted: value),
                  );
                },
              ),
              _buildNotificationTile(
                title: 'Streak Warnings',
                subtitle: 'Reminder when your study streak is at risk',
                icon: Icons.local_fire_department,
                value: prefs.streakWarnings,
                onChanged: (value) {
                  _updatePreference(
                    user,
                    prefs.copyWith(streakWarnings: value),
                  );
                },
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Study Reminders'),
              _buildNotificationTile(
                title: 'Daily Study Reminder',
                subtitle: 'Daily reminder to keep your streak going',
                icon: Icons.notifications_active,
                value: prefs.dailyReminder,
                onChanged: (value) {
                  _updatePreference(
                    user,
                    prefs.copyWith(dailyReminder: value),
                  );
                },
              ),

              if (prefs.dailyReminder) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        'Reminder Time:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<int>(
                        value: prefs.dailyReminderTime,
                        items: List.generate(24, (index) {
                          final hour = index;
                          final period = hour >= 12 ? 'PM' : 'AM';
                          final displayHour = hour == 0
                              ? 12
                              : hour > 12
                                  ? hour - 12
                                  : hour;
                          return DropdownMenuItem(
                            value: hour,
                            child: Text('$displayHour:00 $period'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            _updatePreference(
                              user,
                              prefs.copyWith(dailyReminderTime: value),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _buildSectionHeader('Achievements & Progress'),
              _buildNotificationTile(
                title: 'Achievement Unlocks',
                subtitle: 'When you unlock a new achievement',
                icon: Icons.emoji_events,
                value: prefs.achievementUnlocks,
                onChanged: (value) {
                  _updatePreference(
                    user,
                    prefs.copyWith(achievementUnlocks: value),
                  );
                },
              ),
              _buildNotificationTile(
                title: 'Leaderboard Changes',
                subtitle: 'When your ranking improves significantly',
                icon: Icons.leaderboard,
                value: prefs.leaderboardChanges,
                onChanged: (value) {
                  _updatePreference(
                    user,
                    prefs.copyWith(leaderboardChanges: value),
                  );
                },
              ),

              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading settings: $error'),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        value: value,
        onChanged: _isLoading ? null : onChanged,
      ),
    );
  }
}
