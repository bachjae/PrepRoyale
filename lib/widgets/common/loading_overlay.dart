import 'package:flutter/material.dart';

import '../../config/theme.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onGoBack;
  final String? goBackLabel;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.actionLabel,
    this.actionIcon,
    this.onGoBack,
    this.goBackLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Primary action: Go Back (if provided) - ensures users can always navigate away
            if (onGoBack != null) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onGoBack,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(goBackLabel ?? 'Go Back'),
                ),
              ),
              if (onRetry != null) const SizedBox(height: 12),
            ],
            // Secondary action: Retry (if provided)
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: onGoBack != null
                    ? OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: Icon(actionIcon ?? Icons.refresh),
                        label: Text(actionLabel ?? 'Retry'),
                      )
                    : ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: Icon(actionIcon ?? Icons.refresh),
                        label: Text(actionLabel ?? 'Retry'),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// An enhanced empty state widget with support for primary and secondary actions.
/// Use this when users reach a screen with no content and need clear navigation options.
class EmptyStateWithActions extends StatelessWidget {
  /// The icon to display at the top
  final IconData icon;

  /// The main title text
  final String title;

  /// Optional description providing more context
  final String? description;

  /// Primary action button text (e.g., "Go Back", "Return Home")
  final String primaryActionLabel;

  /// Callback for primary action - this should always be provided
  final VoidCallback onPrimaryAction;

  /// Optional secondary action button text (e.g., "Retry", "Try Again")
  final String? secondaryActionLabel;

  /// Optional callback for secondary action
  final VoidCallback? onSecondaryAction;

  /// Icon for the primary action button
  final IconData? primaryActionIcon;

  /// Icon for the secondary action button
  final IconData? secondaryActionIcon;

  /// Optional custom icon color
  final Color? iconColor;

  const EmptyStateWithActions({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.primaryActionIcon,
    this.secondaryActionIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.textTertiary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: iconColor ?? AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Description
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Primary action button (always visible)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onPrimaryAction,
                icon: Icon(primaryActionIcon ?? Icons.arrow_back),
                label: Text(primaryActionLabel),
              ),
            ),

            // Secondary action button (optional)
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onSecondaryAction,
                  icon: Icon(secondaryActionIcon ?? Icons.refresh),
                  label: Text(secondaryActionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
