import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/router.dart';
import '../config/theme.dart';
import '../providers/session_provider.dart';

/// A banner that shows when the user is in guest mode
class GuestModeBanner extends ConsumerWidget {
  final bool compact;

  const GuestModeBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);

    if (!isGuest) return const SizedBox.shrink();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 16, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Text(
              'Guest Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're in Guest Mode",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your progress is saved only on this device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(userSessionProvider.notifier).exitGuestMode();
              if (context.mounted) context.go(Routes.welcome);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}

/// A dialog that prompts guests to sign up for a feature
class GuestFeaturePrompt extends ConsumerWidget {
  final String featureName;
  final String description;
  final IconData icon;

  const GuestFeaturePrompt({
    super.key,
    required this.featureName,
    required this.description,
    this.icon = Icons.lock_outline,
  });

  static Future<void> show(
    BuildContext context, {
    required String featureName,
    required String description,
    IconData icon = Icons.lock_outline,
  }) {
    return showDialog(
      context: context,
      builder: (context) => GuestFeaturePrompt(
        featureName: featureName,
        description: description,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            featureName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(userSessionProvider.notifier).exitGuestMode();
                if (context.mounted) context.go(Routes.signup);
              },
              child: const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(userSessionProvider.notifier).exitGuestMode();
                if (context.mounted) context.go(Routes.login);
              },
              child: const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A placeholder screen for features not available to guests
class GuestRestrictedScreen extends ConsumerWidget {
  final String featureName;
  final String description;
  final IconData icon;

  const GuestRestrictedScreen({
    super.key,
    required this.featureName,
    required this.description,
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 32),
              Text(
                featureName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(userSessionProvider.notifier)
                        .exitGuestMode();
                    if (context.mounted) context.go(Routes.signup);
                  },
                  child: const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(userSessionProvider.notifier)
                        .exitGuestMode();
                    if (context.mounted) context.go(Routes.login);
                  },
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper that shows restricted content for guests
class GuestGuard extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String description;
  final IconData icon;

  const GuestGuard({
    super.key,
    required this.child,
    required this.featureName,
    required this.description,
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);

    if (isGuest) {
      return GuestRestrictedScreen(
        featureName: featureName,
        description: description,
        icon: icon,
      );
    }

    return child;
  }
}
