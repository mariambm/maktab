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
import '../../students/data/student_models.dart';
import '../data/class_models.dart';
import '../data/classes_repository.dart';

/// One class: level, room, weekly schedule, teachers and the students in it now.
class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final classGroup = ref.watch(classProvider(classId));
    final user = ref.watch(sessionControllerProvider).value;
    final canManage = user?.can(Permissions.classManage) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(classGroup.value?.name ?? l10n.navClasses),
        actions: [
          if (canManage && classGroup.hasValue)
            IconButton(
              tooltip: l10n.editClass,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/classes/$classId/edit'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(classStudentsProvider(classId));
          return ref.refresh(classProvider(classId).future);
        },
        child: AsyncView(
          value: classGroup,
          onRetry: () => ref.invalidate(classProvider(classId)),
          data: (c) => ListView(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            children: [
              SectionCard(
                title: c.curriculumLevel.name,
                children: [
                  InfoRow(label: l10n.roomLabel, value: c.room ?? l10n.notSet),
                  InfoRow(label: l10n.studentsSection, value: l10n.studentCount(c.studentCount)),
                  if (!c.active) InfoRow(label: l10n.classActiveLabel, value: l10n.inactive),
                ],
              ),
              const SizedBox(height: MaktabSpacing.sm),
              SectionCard(
                title: l10n.scheduleSection,
                children: [
                  if (c.schedule.isEmpty) _Muted(l10n.noSchedule),
                  for (final slot in c.schedule)
                    InfoRow(
                      label: weekdayLabel(slot.weekday, l10n),
                      value: '${ScheduleSlot.shortTime(slot.startTime)}–${ScheduleSlot.shortTime(slot.endTime)}',
                    ),
                ],
              ),
              const SizedBox(height: MaktabSpacing.sm),
              SectionCard(
                title: l10n.teachersSection,
                children: [
                  if (c.teachers.isEmpty) _Muted(l10n.noTeachers),
                  for (final t in c.teachers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(t.displayName),
                    ),
                ],
              ),
              const SizedBox(height: MaktabSpacing.sm),
              if (user?.can(Permissions.studentRead) ?? false) _Roster(classId: classId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Roster extends ConsumerWidget {
  const _Roster({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final students = ref.watch(classStudentsProvider(classId));
    final today = DateTime.now();
    return SectionCard(
      title: l10n.studentsSection,
      children: [
        AsyncView(
          value: students,
          onRetry: () => ref.invalidate(classStudentsProvider(classId)),
          isEmpty: (list) => list.isEmpty,
          empty: _Muted(l10n.classNoStudents),
          data: (list) => Column(
            children: [
              for (final s in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(s.firstName.characters.first)),
                  title: Text(s.displayName),
                  subtitle: Text(
                    '${l10n.ageYears(ageOn(s.dateOfBirth, today))} · ${l10n.currentClassSince(formatDate(s.enrolledSince))}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/students/${s.id}'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
