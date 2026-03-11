import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/session_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);

    try {
      final sessionController = ref.read(sessionControllerProvider);
      await sessionController.continueAsGuest();

      if (mounted) {
        context.go(Routes.home);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Logo and branding
              Icon(
                Icons.school,
                size: 100,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Prep Royale',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Study smarter. Battle harder.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Disclaimer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Prep Royale is an independent study app and is not affiliated with, endorsed by, or associated with College Board, SAT, ACT, Inc., or any official testing organization.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Features list
              _FeatureItem(
                icon: Icons.bolt,
                title: 'Zen Mode',
                subtitle: 'Practice at your own pace',
              ),
              const SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.sports_kabaddi,
                title: 'Battle Mode',
                subtitle: 'Compete in real-time battles',
              ),
              const SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.trending_up,
                title: 'Track Progress',
                subtitle: 'See your improvement over time',
              ),

              const SizedBox(height: 32),

              // Sign up button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => context.go(Routes.signup),
                  child: const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 12),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => context.go(Routes.login),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Continue as guest button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Continue as Guest',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Guest mode info
              Text(
                'Guest progress is saved locally on this device only',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
