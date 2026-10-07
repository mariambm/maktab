import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/class_models.dart';
import '../data/classes_repository.dart';
import 'class_labels.dart';

/// Classes Overview. Administrators see and manage every class; teachers see the classes they teach.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionControllerProvider).value;
    final canManage = user?.can(Permissions.classManage) ?? false;
    final classes = ref.watch(classesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navClasses)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/classes/new'),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.addClass),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(classesProvider.future),
        child: AsyncView(
          value: classes,
          onRetry: () => ref.invalidate(classesProvider),
          isEmpty: (list) => list.isEmpty,
          empty: MessageView(
            icon: Icons.groups_outlined,
            title: l10n.classesEmpty,
            message: canManage ? null : l10n.classesEmptyTeacher,
          ),
          data: (list) => ListView(
            padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, 88),
            children: [for (final c in list) _ClassCard(classGroup: c)],
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.classGroup});

  final ClassSummary classGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/classes/${classGroup.id}'),
        child: Padding(
          padding: const EdgeInsets.all(MaktabSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(classGroup.name, style: theme.textTheme.titleMedium)),
                  if (!classGroup.active)
                    StatusChip(label: l10n.inactive, icon: Icons.pause_circle_outline, muted: true),
                ],
              ),
              const SizedBox(height: MaktabSpacing.xs),
              Text(
                [
                  classGroup.curriculumLevel.name,
                  ?classGroup.room,
                  l10n.studentCount(classGroup.studentCount),
                ].join(' · '),
                style: muted,
              ),
              const SizedBox(height: MaktabSpacing.sm),
              _IconLine(
                icon: Icons.schedule,
                text: classGroup.schedule.isEmpty ? l10n.noSchedule : scheduleText(classGroup.schedule, l10n),
              ),
              _IconLine(
                icon: Icons.person_outline,
                text: classGroup.teachers.isEmpty
                    ? l10n.noTeachers
                    : classGroup.teachers.map((t) => t.displayName).join(', '),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: MaktabSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: MaktabSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
