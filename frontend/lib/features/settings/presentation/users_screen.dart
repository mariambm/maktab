import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/users_repository.dart';
import 'role_label.dart';

/// Read-only list of accounts for ADMIN. Creating and editing users follows in Phase 2.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final users = ref.watch(usersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersAndPermissions)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(usersProvider.future),
        child: AsyncView(
          value: users,
          onRetry: () => ref.invalidate(usersProvider),
          isEmpty: (list) => list.isEmpty,
          empty: MessageView(icon: Icons.person_search_outlined, title: l10n.usersEmpty),
          data: (list) => ListView.separated(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: MaktabSpacing.sm),
            itemBuilder: (context, i) {
              final user = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(user.firstName.characters.first)),
                  title: Text(user.displayName),
                  subtitle: Text('${user.email}\n${user.roles.map((r) => roleLabel(r, l10n)).join(', ')}'),
                  isThreeLine: true,
                  trailing: user.active ? null : Chip(label: Text(l10n.inactive)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
