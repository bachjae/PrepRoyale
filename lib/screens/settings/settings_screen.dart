import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cloud_fn.dart';
import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/local_stats_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Guest Mode Banner ────────────────────────────
          if (isGuest) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "You're in Guest Mode",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your progress is saved locally on this device only. Create an account to sync across devices and access all features.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Account section ──────────────────────────────
          _SectionHeader(title: isGuest ? 'Guest Account' : 'Account'),
          if (!isGuest) ...[
            _SettingsTile(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () => context.push(Routes.editProfile),
            ),
            _SettingsTile(
              icon: Icons.photo_camera_outlined,
              label: 'Change Profile Picture',
              onTap: () => context.push(Routes.profilePicture),
            ),
          ],

          // Guest-specific options
          if (isGuest) ...[
            _SettingsTile(
              icon: Icons.person_add_outlined,
              label: 'Create Account',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Recommended',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              onTap: () async {
                await ref.read(userSessionProvider.notifier).exitGuestMode();
                if (context.mounted) context.go(Routes.signup);
              },
            ),
            _SettingsTile(
              icon: Icons.login,
              label: 'Sign In to Existing Account',
              onTap: () async {
                await ref.read(userSessionProvider.notifier).exitGuestMode();
                if (context.mounted) context.go(Routes.login);
              },
            ),
            _SettingsTile(
              icon: Icons.delete_outline,
              label: 'Clear Local Data',
              onTap: () => _showClearDataDialog(context, ref),
            ),
          ],

          const SizedBox(height: 8),

          // ── About section ────────────────────────────────
          const _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'App Version',
            trailing: Text(
              '1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textTertiary,
              ),
            ),
            onTap: null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Not affiliated with College Board, SAT, ACT, Inc., or any official testing organization.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textTertiary,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Sign Out / Exit Guest Mode button ────────────
          if (!isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SignOutButton(
                onSignOut: () async {
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) {
                    context.go(Routes.welcome);
                  }
                },
              ),
            ),

          if (isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ExitGuestButton(
                onExit: () async {
                  await ref.read(userSessionProvider.notifier).exitGuestMode();
                  if (context.mounted) {
                    context.go(Routes.welcome);
                  }
                },
              ),
            ),

          // ── Delete Account (authenticated users only) ─────
          if (!isGuest) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DeleteAccountButton(
                onDelete: () => _confirmDeleteAccount(context, ref),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will delete all your local progress, stats, and battle history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final localStatsService = ref.read(localStatsServiceProvider);
      await localStatsService.clearGuestStats();
      ref.invalidate(guestStatsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data cleared')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account, profile, progress, battle history, and all associated data.\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Call Cloud Function — deletes Firestore data, Storage files, etc.
      await callFn('deleteUserAccount');

      // Delete the Firebase Auth account
      await FirebaseAuth.instance.currentUser?.delete();

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        context.go(Routes.welcome);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'For security, please sign out and sign in again, then retry deleting your account.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings list tile
// ─────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiary,
                    size: 20,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sign out button
// ─────────────────────────────────────────────
class _SignOutButton extends StatefulWidget {
  final Future<void> Function() onSignOut;

  const _SignOutButton({required this.onSignOut});

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onSignOut();
                if (mounted) {
                  setState(() => _loading = false);
                }
              },
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.errorColor,
                ),
              )
            : const Icon(Icons.logout, size: 20, color: AppTheme.errorColor),
        label: Text(
          'Sign Out',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.errorColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Exit guest mode button
// ─────────────────────────────────────────────
class _ExitGuestButton extends StatefulWidget {
  final Future<void> Function() onExit;

  const _ExitGuestButton({required this.onExit});

  @override
  State<_ExitGuestButton> createState() => _ExitGuestButtonState();
}

class _ExitGuestButtonState extends State<_ExitGuestButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onExit();
                if (mounted) {
                  setState(() => _loading = false);
                }
              },
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.textSecondary,
                ),
              )
            : Icon(Icons.exit_to_app, size: 20, color: AppTheme.textSecondary),
        label: Text(
          'Exit Guest Mode',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppTheme.textTertiary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Delete account button
// ─────────────────────────────────────────────
class _DeleteAccountButton extends StatefulWidget {
  final Future<void> Function() onDelete;

  const _DeleteAccountButton({required this.onDelete});

  @override
  State<_DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<_DeleteAccountButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onDelete();
                if (mounted) setState(() => _loading = false);
              },
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
            : const Icon(Icons.delete_forever, size: 20, color: Colors.red),
        label: Text(
          'Delete Account & Data',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
