import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_colors.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../classes/data/classes_repository.dart';
import '../../lessons/data/lesson_models.dart';
import '../../lessons/data/lessons_repository.dart';
import '../../students/data/student_models.dart';
import '../../students/data/students_repository.dart';

final _longDate = DateFormat('EEEE d MMMM yyyy', 'en');

/// The dashboard: a greeting, a few figures the user may see, and today's lessons. Reports and their overview come
/// in Phase 6.
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
    final today = dateOnly(DateTime.now());
    final canSeeLessons = user.can(Permissions.lessonRecord);
    final classes = user.can(Permissions.classRead) ? ref.watch(classesProvider).value : null;
    final students = user.can(Permissions.studentRead)
        ? ref.watch(studentsProvider((search: '', classId: null, status: StudentStatus.active))).value
        : null;
    final lessons = canSeeLessons ? ref.watch(lessonsOnDateProvider(today)) : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(MaktabSpacing.md),
        children: [
          Text(l10n.greeting(user.firstName), style: theme.textTheme.headlineSmall),
          Text(
            _longDate.format(today),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: MaktabSpacing.md),
          _StatRow(
            tiles: [
              if (classes != null)
                _StatTile(
                  value: '${classes.where((c) => c.active).length}',
                  label: l10n.dashboardClasses,
                  color: MaktabColors.primaryDark,
                ),
              if (students != null)
                _StatTile(
                  value: '${students.totalItems}',
                  label: l10n.dashboardStudents,
                  color: MaktabColors.primaryDark,
                ),
              if (lessons?.value != null)
                _StatTile(
                  value: '${lessons!.value!.length}',
                  label: l10n.dashboardLessonsToday,
                  color: MaktabColors.success,
                ),
            ],
          ),
          if (lessons != null) ...[const SizedBox(height: MaktabSpacing.md), _TodaysLessons(lessons: lessons)],
          if (!user.isTeacherOnly) ...[
            const SizedBox(height: MaktabSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(MaktabSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.insights_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: MaktabSpacing.md),
                    Expanded(child: Text(l10n.adminDashboardHint)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Puts the figures side by side, sharing the width on a phone and at most 180 wide each on a large screen.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = MaktabSpacing.sm;
        final width = ((constraints.maxWidth - gap * (tiles.length - 1)) / tiles.length).clamp(0.0, 180.0);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MaktabSpacing.md, horizontal: MaktabSpacing.sm),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: MaktabSpacing.xs),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TodaysLessons extends StatelessWidget {
  const _TodaysLessons({required this.lessons});

  final AsyncValue<List<LessonSummary>> lessons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final list = lessons.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashboardTodaysLessons, style: theme.textTheme.titleMedium),
            const SizedBox(height: MaktabSpacing.sm),
            if (list == null)
              const Padding(
                padding: EdgeInsets.all(MaktabSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (list.isEmpty)
              Text(l10n.dashboardNoLessonsToday, style: muted)
            else
              for (final lesson in list) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(lesson.startTime.substring(0, 5), style: theme.textTheme.labelLarge),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.className, style: theme.textTheme.bodyLarge),
                          Text([?lesson.room, l10n.studentCount(lesson.studentCount)].join(' · '), style: muted),
                        ],
                      ),
                    ),
                    lesson.isOpened
                        ? OutlinedButton(
                            onPressed: () => context.push('/lessons/${lesson.id}'),
                            child: Text(l10n.dashboardView),
                          )
                        : FilledButton(onPressed: () => context.go('/lessons'), child: Text(l10n.dashboardOpen)),
                  ],
                ),
                const Divider(height: MaktabSpacing.lg),
              ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => context.go('/lessons'), child: Text(l10n.dashboardAllLessons)),
            ),
          ],
        ),
      ),
    );
  }
}
