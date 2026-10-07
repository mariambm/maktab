import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../classes/data/classes_repository.dart';
import '../../curriculum/data/curriculum_models.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../students/data/student_models.dart';
import '../data/progress_repository.dart';
import '../data/target_models.dart';
import 'target_sheet.dart';
import 'target_tile.dart';

/// A student's targets per four-week period, the latest period first; earlier periods stay visible.
class StudentTargetsCard extends ConsumerWidget {
  const StudentTargetsCard({super.key, required this.student});

  final StudentDetail student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canManage = ref.watch(sessionControllerProvider).value?.can(Permissions.targetManage) ?? false;
    final targets = ref.watch(studentTargetsProvider(student.id));
    return SectionCard(
      title: l10n.targetsOverview,
      action: canManage && student.currentClass != null
          ? IconButton(tooltip: l10n.addTarget, icon: const Icon(Icons.add), onPressed: () => _add(context, ref))
          : null,
      children: [
        AsyncView(
          value: targets,
          onRetry: () => ref.invalidate(studentTargetsProvider(student.id)),
          isEmpty: (list) => list.isEmpty,
          empty: Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(
              l10n.targetsNoRecords,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, target) in list.indexed) ...[
                if (index == 0 || list[index - 1].period.id != target.period.id)
                  Padding(
                    padding: const EdgeInsets.only(top: MaktabSpacing.xs),
                    child: Text(target.period.name, style: theme.textTheme.labelLarge),
                  ),
                TargetTile(
                  target: target,
                  onTap: canManage ? () => showTargetSheet(context, existing: target) : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Targets are set for a period of the student's own level, the one running now first.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final classId = student.currentClass?.id;
    if (classId == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.targetNeedsClass)));
      return;
    }
    try {
      final classGroup = await ref.read(classProvider(classId).future);
      final periods = await ref.read(curriculumPeriodsProvider(classGroup.curriculumLevel.id).future);
      if (!context.mounted) {
        return;
      }
      if (periods.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.targetNoPeriods)));
        return;
      }
      final sorted = [...periods]..sort((a, b) => b.startDate.compareTo(a.startDate));
      final today = DateTime.now();
      final current = sorted.where((p) => p.coversToday(DateTime(today.year, today.month, today.day))).firstOrNull;
      await showTargetSheet(
        context,
        studentId: student.id,
        periods: sorted,
        initialPeriodId: (current ?? sorted.first).id,
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.genericError)));
    }
  }
}

/// Exposed for the Progress screen, which adds a target for the period it already shows.
Future<StudentTarget?> addTargetForPeriod(BuildContext context, String studentId, CurriculumPeriodSummary period) =>
    showTargetSheet(context, studentId: studentId, periods: [period], initialPeriodId: period.id);
