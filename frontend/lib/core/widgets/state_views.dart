import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../errors/api_exception.dart';
import '../theme/maktab_spacing.dart';

/// Centred icon, title and message, used for empty and error states so every screen looks the same.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MaktabSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: MaktabSpacing.md),
              Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: MaktabSpacing.sm),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: MaktabSpacing.lg), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MessageView(
      icon: Icons.cloud_off_outlined,
      title: errorMessage(error, l10n),
      action: onRetry == null
          ? null
          : OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.retry)),
    );
  }
}

/// A user-facing message for any error. Server messages are already safe to show; anything else is generic.
String errorMessage(Object error, AppLocalizations l10n) {
  if (error is ApiException) {
    if (error.isNetworkError) {
      return l10n.networkError;
    }
    return error.message ?? l10n.genericError;
  }
  return l10n.genericError;
}
