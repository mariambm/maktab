import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_colors.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../classes/data/classes_repository.dart';
import '../../lessons/data/lesson_models.dart';
import '../../lessons/data/lessons_repository.dart';
import '../../payments/presentation/payment_labels.dart';
import '../../reports/data/report_models.dart';
import '../../reports/data/reports_repository.dart';
import '../../students/data/student_models.dart';
import '../../students/data/students_repository.dart';

final _longDate = DateFormat('EEEE d MMMM yyyy', 'en');

/// The dashboard: a greeting, a few figures the user may see, today's lessons, and the last four weeks at a glance
/// with a way into the reports.
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
          StatRow(
            tiles: [
              if (classes != null)
                StatTile(
                  value: '${classes.where((c) => c.active).length}',
                  label: l10n.dashboardClasses,
                  color: MaktabColors.primaryDark,
                ),
              if (students != null)
                StatTile(
                  value: '${students.totalItems}',
                  label: l10n.dashboardStudents,
                  color: MaktabColors.primaryDark,
                ),
              if (lessons?.value != null)
                StatTile(
                  value: '${lessons!.value!.length}',
                  label: l10n.dashboardLessonsToday,
                  color: MaktabColors.success,
                ),
            ],
          ),
          if (lessons != null) ...[
            const SizedBox(height: MaktabSpacing.md),
            _TodaysLessons(lessons: lessons, today: today),
          ],
          if (user.can(Permissions.reportRead)) ...[const SizedBox(height: MaktabSpacing.md), const _RecentFigures()],
        ],
      ),
    );
  }
}

class _TodaysLessons extends ConsumerStatefulWidget {
  const _TodaysLessons({required this.lessons, required this.today});

  final AsyncValue<List<LessonSummary>> lessons;
  final DateTime today;

  @override
  ConsumerState<_TodaysLessons> createState() => _TodaysLessonsState();
}

class _TodaysLessonsState extends ConsumerState<_TodaysLessons> {
  bool _opening = false;

  /// Opens the lesson straight from the dashboard, so the teacher lands on its register in one tap.
  Future<void> _open(LessonSummary lesson) async {
    setState(() => _opening = true);
    try {
      final opened = await ref.read(lessonsRepositoryProvider).open(OpenLessonDraft.forSlot(lesson));
      if (!mounted) {
        return;
      }
      setState(() => _opening = false);
      await context.push('/lessons/${opened.id}');
      ref.invalidate(lessonsOnDateProvider(widget.today));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _opening = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(error, AppLocalizations.of(context)))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final lessons = widget.lessons;
    final list = lessons.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashboardTodaysLessons, style: theme.textTheme.titleMedium),
            const SizedBox(height: MaktabSpacing.sm),
            if (lessons case AsyncError(:final error) when list == null)
              Row(
                children: [
                  Expanded(child: Text(errorMessage(error, l10n), style: theme.textTheme.bodyMedium)),
                  TextButton(
                    onPressed: () => ref.invalidate(lessonsOnDateProvider(widget.today)),
                    child: Text(l10n.retry),
                  ),
                ],
              )
            else if (list == null)
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
                        : FilledButton(
                            onPressed: _opening ? null : () => _open(lesson),
                            child: Text(l10n.dashboardOpen),
                          ),
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

/// Attendance of the last four weeks, targets behind and the latest month's fees, each opening the report behind it.
class _RecentFigures extends ConsumerWidget {
  const _RecentFigures();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final figures = ref.watch(dashboardFiguresProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashboardLastFourWeeks, style: theme.textTheme.titleMedium),
            const SizedBox(height: MaktabSpacing.sm),
            switch (figures) {
              AsyncData(:final value) => _figureTiles(context, value, l10n),
              AsyncError(:final error) => Row(
                children: [
                  Expanded(child: Text(errorMessage(error, l10n), style: theme.textTheme.bodyMedium)),
                  TextButton(onPressed: () => ref.invalidate(dashboardFiguresProvider), child: Text(l10n.retry)),
                ],
              ),
              _ => const Padding(
                padding: EdgeInsets.all(MaktabSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => context.go('/reports'), child: Text(l10n.dashboardViewReports)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _figureTiles(BuildContext context, DashboardFigures figures, AppLocalizations l10n) {
    final attendance = figures.attendance;
    final percentage = attendance.attendancePercentage;
    final low = percentage != null && percentage < attendance.thresholdPercentage;
    final payments = figures.payments;
    void open() => context.go('/reports');
    return StatRow(
      tiles: [
        StatTile(
          value: percentage == null ? '–' : '$percentage%',
          label: l10n.dashboardAttendance,
          color: low ? MaktabColors.warning : MaktabColors.success,
          icon: low ? Icons.warning_amber_rounded : null,
          onTap: open,
        ),
        StatTile(
          value: '${attendance.late}',
          label: l10n.attendanceLATE,
          color: attendance.late > 0 ? MaktabColors.warning : MaktabColors.primaryDark,
          onTap: open,
        ),
        StatTile(
          value: '${attendance.absent}',
          label: l10n.attendanceABSENT,
          color: attendance.absent > 0 ? MaktabColors.danger : MaktabColors.primaryDark,
          onTap: open,
        ),
        StatTile(
          value: '${attendance.studentsBelowThreshold}',
          label: l10n.dashboardBelowThreshold(attendance.thresholdPercentage),
          color: attendance.studentsBelowThreshold > 0 ? MaktabColors.warning : MaktabColors.primaryDark,
          icon: attendance.studentsBelowThreshold > 0 ? Icons.warning_amber_rounded : null,
          onTap: open,
        ),
        StatTile(
          value: '${figures.progress.targetsBehind}',
          label: l10n.dashboardBehindTarget,
          color: figures.progress.targetsBehind > 0 ? MaktabColors.warning : MaktabColors.primaryDark,
          onTap: open,
        ),
        if (payments != null)
          StatTile(
            value: formatMoney(payments.totals.outstandingTotal, payments.currency),
            label: l10n.dashboardOutstanding(formatMonth(payments.month)),
            color: payments.totals.outstandingTotal > 0 ? MaktabColors.danger : MaktabColors.success,
            onTap: open,
          ),
      ],
    );
  }
}
