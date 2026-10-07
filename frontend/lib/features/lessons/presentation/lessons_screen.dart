import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/lesson_models.dart';
import '../data/lessons_repository.dart';
import 'lesson_labels.dart';

/// A teacher's day: every lesson of their classes, whether it has been started and how far the register is.
class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  DateTime _date = dateOnly(DateTime.now());
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = dateOnly(DateTime.now());
    final lessons = ref.watch(lessonsOnDateProvider(_date));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navLessons),
        actions: [
          if (_date != today) TextButton(onPressed: () => setState(() => _date = today), child: Text(l10n.today)),
        ],
      ),
      body: Column(
        children: [
          _DayBar(date: _date, isToday: _date == today, onChange: (date) => setState(() => _date = date)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(lessonsOnDateProvider(_date).future),
              child: AsyncView(
                value: lessons,
                onRetry: () => ref.invalidate(lessonsOnDateProvider(_date)),
                isEmpty: (list) => list.isEmpty,
                empty: MessageView(
                  icon: Icons.event_busy_outlined,
                  title: l10n.lessonsEmpty,
                  message: l10n.lessonsEmptyTeacher,
                ),
                data: (list) => ListView(
                  padding: const EdgeInsets.all(MaktabSpacing.md),
                  children: [
                    for (final lesson in list)
                      _LessonCard(lesson: lesson, busy: _opening, onTap: () => _openOrShow(lesson)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opening is idempotent on the server, so tapping a slot twice still lands on the same lesson.
  Future<void> _openOrShow(LessonSummary lesson) async {
    if (lesson.isOpened) {
      await context.push('/lessons/${lesson.id}');
      ref.invalidate(lessonsOnDateProvider(_date));
      return;
    }
    final user = ref.read(sessionControllerProvider).value;
    if (!(user?.can(Permissions.lessonRecord) ?? false) || _opening) {
      return;
    }
    setState(() => _opening = true);
    try {
      final opened = await ref
          .read(lessonsRepositoryProvider)
          .open(
            OpenLessonDraft(
              classGroupId: lesson.classGroupId,
              lessonDate: lesson.lessonDate,
              classScheduleId: lesson.classScheduleId,
              startTime: lesson.classScheduleId == null ? lesson.startTime : null,
              endTime: lesson.classScheduleId == null ? lesson.endTime : null,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() => _opening = false);
      await context.push('/lessons/${opened.id}');
      ref.invalidate(lessonsOnDateProvider(_date));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _opening = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(error, AppLocalizations.of(context)))));
    }
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.date, required this.isToday, required this.onChange});

  final DateTime date;
  final bool isToday;
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(MaktabSpacing.sm, MaktabSpacing.sm, MaktabSpacing.sm, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.previousDay,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChange(date.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: Column(
              children: [
                Text(formatDate(date), style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                Text(
                  isToday ? l10n.today : weekdayLabel(apiWeekday(date), l10n),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.nextDay,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onChange(date.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.busy, required this.onTap});

  final LessonSummary lesson;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(MaktabSpacing.md),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shortTime(lesson.startTime), style: theme.textTheme.titleMedium),
                  Text(shortTime(lesson.endTime), style: muted),
                ],
              ),
              const SizedBox(width: MaktabSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.className, style: theme.textTheme.titleMedium),
                    const SizedBox(height: MaktabSpacing.xs),
                    Text([?lesson.room, l10n.studentCount(lesson.studentCount)].join(' · '), style: muted),
                    const SizedBox(height: MaktabSpacing.sm),
                    _StatusLine(lesson: lesson),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.lesson});

  final LessonSummary lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!lesson.isOpened) {
      return StatusChip(label: l10n.lessonNotOpened, icon: Icons.play_circle_outline, muted: true);
    }
    if (lesson.status == LessonStatuses.cancelled) {
      return StatusChip(label: l10n.lessonCANCELLED, icon: Icons.event_busy_outlined, muted: true);
    }
    if (lesson.attendanceComplete) {
      return StatusChip(label: l10n.lessonAttendanceDone, icon: Icons.check_circle_outline);
    }
    return StatusChip(
      label: l10n.lessonAttendancePartial(lesson.attendanceRecorded, lesson.studentCount),
      icon: Icons.how_to_reg_outlined,
      muted: true,
    );
  }
}
