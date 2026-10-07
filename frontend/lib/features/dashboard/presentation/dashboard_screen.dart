import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Phase 1 dashboard: greets the user and explains what will appear. Teachers will see today's lessons here from
/// Phase 3; administrators get the overview in Phase 6.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(sessionControllerProvider).value;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(MaktabSpacing.md),
        children: [
          Text(l10n.greeting(user.firstName), style: theme.textTheme.headlineSmall),
          const SizedBox(height: MaktabSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(MaktabSpacing.md),
              child: Row(
                children: [
                  Icon(
                    user.isTeacherOnly ? Icons.event_note_outlined : Icons.insights_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: MaktabSpacing.md),
                  Expanded(
                    child: Text(user.isTeacherOnly ? l10n.teacherDashboardHint : l10n.adminDashboardHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
