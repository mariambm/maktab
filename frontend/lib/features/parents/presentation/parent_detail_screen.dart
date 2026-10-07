import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/parents_repository.dart';

class ParentDetailScreen extends ConsumerWidget {
  const ParentDetailScreen({super.key, required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final parent = ref.watch(parentProvider(parentId));
    final canWrite = ref.watch(sessionControllerProvider).value?.can(Permissions.parentWrite) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(parent.value?.displayName ?? l10n.navParents),
        actions: [
          if (canWrite && parent.hasValue)
            IconButton(
              tooltip: l10n.editParent,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/parents/$parentId/edit'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(parentProvider(parentId).future),
        child: AsyncView(
          value: parent,
          onRetry: () => ref.invalidate(parentProvider(parentId)),
          data: (p) => ListView(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            children: [
              SectionCard(
                title: l10n.contactSection,
                children: [
                  InfoRow(label: l10n.phoneLabel, value: p.phone),
                  InfoRow(label: l10n.emailLabel, value: p.email ?? l10n.notSet),
                ],
              ),
              const SizedBox(height: MaktabSpacing.sm),
              SectionCard(
                title: l10n.childrenSection,
                children: [
                  if (p.children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
                      child: Text(l10n.noChildren),
                    ),
                  for (final child in p.children)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.school_outlined),
                      title: Text(child.displayName),
                      subtitle: Text(
                        [
                          relationshipLabel(child.relationship, l10n),
                          if (child.primaryContact) l10n.primaryContact,
                          if (child.status != 'ACTIVE') l10n.inactive,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/students/${child.studentId}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
