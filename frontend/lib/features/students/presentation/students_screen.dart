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
import '../../classes/data/classes_repository.dart';
import '../data/student_models.dart';
import '../data/students_repository.dart';

/// Students Overview: search, filter by class and status, and open a profile. Teachers see only their classes.
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  StudentFilter _filter = (search: '', classId: null, status: StudentStatus.active);

  void _update(StudentFilter filter) => setState(() => _filter = filter);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionControllerProvider).value;
    final canWrite = user?.can(Permissions.studentWrite) ?? false;
    final students = ref.watch(studentsProvider(_filter));
    final classes = ref.watch(classesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navStudents)),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/students/new'),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.addStudent),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.sm, MaktabSpacing.md, 0),
            child: DebouncedSearch(
              hintText: l10n.searchStudentsHint,
              onChanged: (value) => _update((search: value, classId: _filter.classId, status: _filter.status)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.md, vertical: MaktabSpacing.sm),
            child: Row(
              children: [
                DropdownMenu<String?>(
                  initialSelection: _filter.classId,
                  label: Text(l10n.classSection),
                  width: 220,
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: null, label: l10n.filterAllClasses),
                    for (final c in classes) DropdownMenuEntry(value: c.id, label: c.name),
                  ],
                  onSelected: (id) => _update((search: _filter.search, classId: id, status: _filter.status)),
                ),
                const SizedBox(width: MaktabSpacing.sm),
                SegmentedButton<String?>(
                  segments: [
                    ButtonSegment(value: StudentStatus.active, label: Text(l10n.statusActive)),
                    ButtonSegment(value: StudentStatus.inactive, label: Text(l10n.inactive)),
                    ButtonSegment(value: null, label: Text(l10n.filterAll)),
                  ],
                  selected: {_filter.status},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      _update((search: _filter.search, classId: _filter.classId, status: s.first)),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(studentsProvider(_filter).future),
              child: AsyncView(
                value: students,
                onRetry: () => ref.invalidate(studentsProvider(_filter)),
                isEmpty: (page) => page.items.isEmpty,
                empty: MessageView(
                  icon: Icons.person_search_outlined,
                  title: l10n.studentsEmpty,
                  message: (user?.isTeacherOnly ?? false) && _filter.search.isEmpty && _filter.classId == null
                      ? l10n.studentsEmptyTeacher
                      : l10n.studentsEmptyHint,
                ),
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
                    return StudentTile(student: page.items[i]);
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

class StudentTile extends StatelessWidget {
  const StudentTile({super.key, required this.student});

  final StudentSummary student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final age = ageOn(student.dateOfBirth, DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: ListTile(
        minVerticalPadding: MaktabSpacing.sm,
        leading: CircleAvatar(
          backgroundColor: student.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(student.firstName.characters.first),
        ),
        title: Text(student.displayName),
        subtitle: Text('${student.currentClass?.name ?? l10n.studentNoClass} · ${l10n.ageYears(age)}'),
        trailing: student.isActive
            ? const Icon(Icons.chevron_right)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause_circle_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: MaktabSpacing.xs),
                  Text(l10n.inactive),
                ],
              ),
        onTap: () => context.push('/students/${student.id}'),
      ),
    );
  }
}
