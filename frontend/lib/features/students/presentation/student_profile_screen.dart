import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../behaviour/data/behaviour_repository.dart';
import '../../behaviour/presentation/student_behaviour_card.dart';
import '../../classes/data/classes_repository.dart';
import '../../lessons/data/lessons_repository.dart';
import '../../lessons/presentation/student_attendance_card.dart';
import '../../progress/data/progress_repository.dart';
import '../../progress/presentation/student_progress_card.dart';
import '../../progress/presentation/student_targets_card.dart';
import '../../uniform/data/uniform_repository.dart';
import '../../uniform/presentation/student_uniform_card.dart';
import '../data/student_models.dart';
import '../data/students_repository.dart';
import 'manage_parents_sheet.dart';
import 'move_class_sheet.dart';

enum _MenuAction { deactivate, reactivate, removeFromClass }

/// Student Profile: personal information, class with history, parents, attendance, targets, progress, behaviour
/// and uniform. Lesson history is added as a further section.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final student = ref.watch(studentProvider(studentId));
    final canWrite = ref.watch(sessionControllerProvider).value?.can(Permissions.studentWrite) ?? false;
    final loaded = student.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.displayName ?? l10n.navStudents),
        actions: [
          if (canWrite && loaded != null) ...[
            IconButton(
              tooltip: l10n.editStudent,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/students/$studentId/edit'),
            ),
            PopupMenuButton<_MenuAction>(
              onSelected: (action) => _onMenu(context, ref, loaded, action),
              itemBuilder: (_) => [
                if (loaded.isActive && loaded.currentClass != null)
                  PopupMenuItem(value: _MenuAction.removeFromClass, child: Text(l10n.removeFromClass)),
                if (loaded.isActive)
                  PopupMenuItem(value: _MenuAction.deactivate, child: Text(l10n.deactivateStudent))
                else
                  PopupMenuItem(value: _MenuAction.reactivate, child: Text(l10n.reactivateStudent)),
              ],
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          ref
            ..invalidate(enrollmentsProvider(studentId))
            ..invalidate(studentAttendanceStatisticsProvider(studentId))
            ..invalidate(studentTargetsProvider(studentId))
            ..invalidate(studentProgressProvider(studentId))
            ..invalidate(studentBehaviourProvider(studentId))
            ..invalidate(studentUniformProvider(studentId));
          return ref.refresh(studentProvider(studentId).future);
        },
        child: AsyncView(
          value: student,
          onRetry: () => ref.invalidate(studentProvider(studentId)),
          data: (s) => _Profile(student: s, canWrite: canWrite),
        ),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, StudentDetail student, _MenuAction action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(studentsRepositoryProvider);
    final (title, body, confirm) = switch (action) {
      _MenuAction.deactivate => (
        l10n.deactivateConfirmTitle(student.displayName),
        l10n.deactivateConfirmBody,
        l10n.deactivateStudent,
      ),
      _MenuAction.removeFromClass => (
        l10n.removeFromClass,
        l10n.removeFromClassConfirm(student.displayName, student.currentClass?.name ?? ''),
        l10n.remove,
      ),
      _MenuAction.reactivate => (null, null, null),
    };
    if (title != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body!),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirm!)),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    try {
      switch (action) {
        case _MenuAction.deactivate:
          await repository.setStatus(student.id, StudentStatus.inactive);
          messenger.showSnackBar(SnackBar(content: Text(l10n.studentDeactivated)));
        case _MenuAction.reactivate:
          await repository.setStatus(student.id, StudentStatus.active);
          messenger.showSnackBar(SnackBar(content: Text(l10n.studentReactivated)));
        case _MenuAction.removeFromClass:
          await repository.removeFromClass(student.id);
          messenger.showSnackBar(SnackBar(content: Text(l10n.studentSaved)));
      }
      refreshStudent(ref, student.id);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e, l10n))));
    }
  }
}

/// Invalidates everything that shows this student after a change.
void refreshStudent(WidgetRef ref, String studentId) {
  ref
    ..invalidate(studentProvider(studentId))
    ..invalidate(enrollmentsProvider(studentId))
    ..invalidate(studentsProvider)
    ..invalidate(classesProvider)
    ..invalidate(classStudentsProvider);
}

class _Profile extends StatelessWidget {
  const _Profile({required this.student, required this.canWrite});

  final StudentDetail student;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final age = ageOn(student.dateOfBirth, DateTime.now());
    return ListView(
      padding: const EdgeInsets.all(MaktabSpacing.md),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(student.firstName.characters.first, style: theme.textTheme.headlineSmall),
                    ),
                    const SizedBox(width: MaktabSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.displayName, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: MaktabSpacing.xs),
                          Wrap(
                            spacing: MaktabSpacing.sm,
                            runSpacing: MaktabSpacing.xs,
                            children: [
                              StatusChip(
                                label: student.isActive ? l10n.statusActive : l10n.inactive,
                                icon: student.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                                muted: !student.isActive,
                              ),
                              StatusChip(
                                label: student.currentClass?.name ?? l10n.studentNoClass,
                                icon: Icons.groups_outlined,
                                muted: student.currentClass == null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MaktabSpacing.md),
                SectionCard(
                  title: l10n.personalInformation,
                  children: [
                    InfoRow(
                      label: l10n.dateOfBirthLabel,
                      value: '${formatDate(student.dateOfBirth)} (${l10n.ageYears(age)})',
                    ),
                    InfoRow(label: l10n.genderLabel, value: genderLabel(student.gender, l10n)),
                    InfoRow(label: l10n.joinedOnLabel, value: formatDate(student.joinedOn)),
                    if (student.leftOn != null) InfoRow(label: l10n.leftOnLabel, value: formatDate(student.leftOn!)),
                    if (student.notes != null) InfoRow(label: l10n.notesLabel, value: student.notes!),
                  ],
                ),
                const SizedBox(height: MaktabSpacing.sm),
                _ClassSection(student: student, canWrite: canWrite),
                const SizedBox(height: MaktabSpacing.sm),
                _ParentsSection(student: student, canWrite: canWrite),
                const SizedBox(height: MaktabSpacing.sm),
                StudentAttendanceCard(studentId: student.id),
                const SizedBox(height: MaktabSpacing.sm),
                StudentTargetsCard(student: student),
                const SizedBox(height: MaktabSpacing.sm),
                StudentProgressCard(studentId: student.id),
                const SizedBox(height: MaktabSpacing.sm),
                StudentBehaviourCard(studentId: student.id),
                const SizedBox(height: MaktabSpacing.sm),
                StudentUniformCard(studentId: student.id),
                const SizedBox(height: MaktabSpacing.md),
                Text(
                  l10n.moreComingNote,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassSection extends ConsumerWidget {
  const _ClassSection({required this.student, required this.canWrite});

  final StudentDetail student;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(enrollmentsProvider(student.id));
    final canMove = canWrite && student.isActive;
    return SectionCard(
      title: l10n.classSection,
      action: canMove
          ? TextButton.icon(
              onPressed: () => showMoveClassSheet(context, student),
              icon: const Icon(Icons.swap_horiz),
              label: Text(student.currentClass == null ? l10n.placeInClass : l10n.moveToClass),
            )
          : null,
      children: [
        AsyncView(
          value: history,
          onRetry: () => ref.invalidate(enrollmentsProvider(student.id)),
          isEmpty: (list) => list.isEmpty,
          empty: Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(l10n.studentNoClass),
          ),
          data: (list) => Column(
            children: [
              for (final e in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(e.isCurrent ? Icons.groups : Icons.history),
                  title: Text(e.classGroup.name),
                  subtitle: Text(
                    e.isCurrent
                        ? l10n.currentClassSince(formatDate(e.startDate))
                        : l10n.enrollmentPeriod(formatDate(e.startDate), formatDate(e.endDate!)),
                  ),
                  onTap: () => context.push('/classes/${e.classGroup.id}'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParentsSection extends StatelessWidget {
  const _ParentsSection({required this.student, required this.canWrite});

  final StudentDetail student;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final canReadParents = ref.watch(sessionControllerProvider).value?.can(Permissions.parentRead) ?? false;
        return SectionCard(
          title: canReadParents ? l10n.parentsSection : l10n.primaryContact,
          action: canWrite && canReadParents
              ? TextButton.icon(
                  onPressed: () => showManageParentsSheet(context, student),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.manageParents),
                )
              : null,
          children: [
            if (student.parents.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
                child: Text(l10n.noParents),
              ),
            for (final p in student.parents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(p.displayName),
                subtitle: Text(
                  [
                    relationshipLabel(p.relationship, l10n),
                    if (p.primaryContact && canReadParents) l10n.primaryContact,
                    p.phone,
                    ?p.email,
                  ].join(' · '),
                ),
                onTap: canReadParents ? () => context.push('/parents/${p.parentId}') : null,
              ),
          ],
        );
      },
    );
  }
}
