import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/redirect.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/debounced_search.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/users_repository.dart';
import 'role_label.dart';

/// Accounts for ADMIN: search, add, and open one to change roles, permissions, status or password.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final users = ref.watch(usersProvider(_search));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersAndPermissions)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${Routes.users}/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addUser),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            child: DebouncedSearch(
              hintText: l10n.searchUsersHint,
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(usersProvider(_search).future),
              child: AsyncView(
                value: users,
                onRetry: () => ref.invalidate(usersProvider(_search)),
                isEmpty: (page) => page.items.isEmpty,
                empty: MessageView(icon: Icons.person_search_outlined, title: l10n.usersEmpty),
                data: (page) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, 0, MaktabSpacing.md, 88),
                  itemCount: page.items.length + (page.hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == page.items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(MaktabSpacing.md),
                        child: Text(l10n.showingSome(page.items.length, page.totalItems), textAlign: TextAlign.center),
                      );
                    }
                    final user = page.items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(user.firstName.characters.first)),
                        title: Text(user.displayName),
                        subtitle: Text('${user.email}\n${user.roles.map((r) => roleLabel(r, l10n)).join(', ')}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!user.active) Chip(label: Text(l10n.inactive)),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => context.push('${Routes.users}/${user.id}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
