import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/routing/redirect.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'role_label.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionControllerProvider).value;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(MaktabSpacing.md),
        children: [
          Text(l10n.accountSection, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: MaktabSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text(user.firstName.characters.first)),
                  title: Text(user.displayName),
                  subtitle: Text('${user.email}\n${user.roles.map((r) => roleLabel(r, l10n)).join(', ')}'),
                  isThreeLine: true,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: Text(l10n.changePasswordTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.changePassword),
                ),
                if (user.can(Permissions.userManage)) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: Text(l10n.usersAndPermissions),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(Routes.users),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: MaktabSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
