import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/debounced_search.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/parents_repository.dart';

/// Parents & Guardians: search by name, phone or email, and see each family's children at a glance.
class ParentsScreen extends ConsumerStatefulWidget {
  const ParentsScreen({super.key});

  @override
  ConsumerState<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends ConsumerState<ParentsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canWrite = ref.watch(sessionControllerProvider).value?.can(Permissions.parentWrite) ?? false;
    final parents = ref.watch(parentsProvider(_search));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navParents)),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/parents/new'),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            child: DebouncedSearch(
              hintText: l10n.searchParentsHint,
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(parentsProvider(_search).future),
              child: AsyncView(
                value: parents,
                onRetry: () => ref.invalidate(parentsProvider(_search)),
                isEmpty: (page) => page.items.isEmpty,
                empty: MessageView(icon: Icons.person_search_outlined, title: l10n.parentsEmpty),
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
                    final p = page.items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(p.firstName.characters.first)),
                        title: Text(p.displayName),
                        subtitle: Text(
                          [
                            p.phone,
                            if (p.children.isEmpty) l10n.noChildren else p.children.map((c) => c.firstName).join(', '),
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/parents/${p.id}'),
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
