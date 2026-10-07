import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../behaviour/data/behaviour_repository.dart';
import '../../behaviour/presentation/behaviour_recorder.dart';
import '../../curriculum/data/curriculum_models.dart';
import '../../progress/data/progress_repository.dart';
import '../../progress/presentation/progress_recorder.dart';
import '../../uniform/data/uniform_repository.dart';
import '../../uniform/presentation/uniform_recorder.dart';
import '../data/lesson_models.dart';
import '../data/lessons_repository.dart';
import 'attendance_register.dart';
import 'lesson_content_editor.dart';
import 'lesson_labels.dart';

/// One lesson: the register first, because that is what a teacher opens the screen for, then what was taught, then
/// progress, behaviour and uniform for the students who were there.
class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lesson = ref.watch(lessonProvider(lessonId));
    final user = ref.watch(sessionControllerProvider).value;
    final canRecord = user?.can(Permissions.lessonRecord) ?? false;
    final canScore = user?.can(Permissions.progressRecord) ?? false;
    final canObserve = user?.can(Permissions.observationRecord) ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.value?.className ?? l10n.navLessons)),
      body: RefreshIndicator(
        onRefresh: () {
          ref
            ..invalidate(lessonProgressProvider(lessonId))
            ..invalidate(lessonBehaviourProvider(lessonId))
            ..invalidate(lessonUniformProvider(lessonId));
          return ref.refresh(lessonProvider(lessonId).future);
        },
        child: AsyncView(
          value: lesson,
          onRetry: () => ref.invalidate(lessonProvider(lessonId)),
          data: (detail) => ListView(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            children: [
              _LessonHeader(lesson: detail),
              const SizedBox(height: MaktabSpacing.sm),
              AttendanceRegister(lesson: detail, readOnly: !canRecord),
              const SizedBox(height: MaktabSpacing.sm),
              LessonContentEditor(lesson: detail, readOnly: !canRecord),
              const SizedBox(height: MaktabSpacing.sm),
              ProgressRecorder(lesson: detail, readOnly: !canScore),
              const SizedBox(height: MaktabSpacing.sm),
              BehaviourRecorder(lesson: detail, readOnly: !canObserve),
              const SizedBox(height: MaktabSpacing.sm),
              UniformRecorder(lesson: detail, readOnly: !canObserve),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.lesson});

  final LessonDetail lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final period = lesson.curriculumPeriod;
    final week = lesson.curriculumWeekNumber;
    return SectionCard(
      title: '${formatDate(lesson.lessonDate)} · ${shortTime(lesson.startTime)}–${shortTime(lesson.endTime)}',
      children: [
        InfoRow(label: l10n.classLabel, value: [lesson.className, ?lesson.room].join(' · ')),
        InfoRow(label: l10n.lessonStatusLabel, value: lessonStatusLabel(lesson.status, l10n)),
        if (period != null && week != null)
          InfoRow(
            label: l10n.navCurriculum,
            value: week == curriculumReviewWeek
                ? '${l10n.curriculumWeekOf(week, period.name)} · ${l10n.curriculumReviewWeek}'
                : l10n.curriculumWeekOf(week, period.name),
          ),
      ],
    );
  }
}

/// Shows a message on a failed save, in the same words the rest of the app uses.
void showSaveError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(errorMessage(error, AppLocalizations.of(context)))));
}
