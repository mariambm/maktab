import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Shows a temporary password once, with a copy button. The password lives only in this dialog.
Future<void> showTemporaryPasswordDialog(BuildContext context, {required String name, required String password}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(l10n.temporaryPasswordTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.temporaryPasswordBody(name)),
              const SizedBox(height: MaktabSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.md, vertical: MaktabSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        password,
                        style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 1),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.copy,
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: password));
                        messenger.showSnackBar(SnackBar(content: Text(l10n.copied)));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.done))],
        );
      },
    );
