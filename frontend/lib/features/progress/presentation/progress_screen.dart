import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../classes/data/class_models.dart';
import '../../classes/data/classes_repository.dart';
import '../../curriculum/presentation/subject_labels.dart';
import '../data/progress_models.dart';
import '../data/progress_repository.dart';
import '../data/target_models.dart';
import 'student_targets_card.dart';
import 'target_sheet.dart';
import 'target_tile.dart';

/// Progress per class: the period running now, and for each student their latest score and their targets.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final classes = ref.watch(classesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProgress)),
      body: AsyncView(
        value: classes,
        onRetry: () => ref.invalidate(classesProvider),
        isEmpty: (list) => list.where((c) => c.active).isEmpty,
        empty: MessageView(icon: Icons.groups_outlined, title: l10n.progressNoClasses),
        data: (list) {
          final active = list.where((c) => c.active).toList();
          final classId = active.any((c) => c.id == _selected) ? _selected! : active.first.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, 0),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(classId),
                  initialValue: classId,
                  decoration: InputDecoration(labelText: l10n.progressChooseClass),
                  items: [for (final ClassSummary c in active) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (id) => setState(() => _selected = id),
                ),
              ),
              Expanded(child: _ClassProgressView(classId: classId)),
            ],
          );
        },
      ),
    );
  }
}

class _ClassProgressView extends ConsumerWidget {
  const _ClassProgressView({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canManage = ref.watch(sessionControllerProvider).value?.can(Permissions.targetManage) ?? false;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(classProgressProvider(classId).future),
      child: AsyncView(
        value: ref.watch(classProgressProvider(classId)),
        onRetry: () => ref.invalidate(classProgressProvider(classId)),
        data: (overview) {
          final period = overview.period;
          return ListView(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            children: [
              Text(
                period == null
                    ? l10n.progressNoPeriod
                    : l10n.progressPeriodOf(period.name, formatDate(period.startDate), formatDate(period.endDate)),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: MaktabSpacing.sm),
              if (overview.students.isEmpty) MessageView(icon: Icons.school_outlined, title: l10n.progressNoStudents),
              for (final student in overview.students)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MaktabSpacing.md,
                      MaktabSpacing.xs,
                      MaktabSpacing.xs,
                      MaktabSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(student.displayName, style: theme.textTheme.titleMedium),
                          subtitle: Text(_latest(student.latestScore, l10n)),
                          trailing: canManage && period != null
                              ? IconButton(
                                  tooltip: l10n.addTarget,
                                  icon: const Icon(Icons.add_task),
                                  onPressed: () => _addTarget(context, ref, student.studentId),
                                )
                              : null,
                          onTap: () => context.push('/students/${student.studentId}'),
                        ),
                        for (final target in student.targets)
                          TargetTile(target: target, onTap: canManage ? () => _editTarget(context, ref, target) : null),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _latest(LatestScore? score, AppLocalizations l10n) {
    if (score == null) {
      return l10n.progressNoScoreYet;
    }
    return '${l10n.progressLatestScore}: ${[formatScore(score.score), ?score.label].join(' ')} · '
        '${subjectLabel(score.subject, l10n)} · ${formatDate(score.lessonDate)}';
  }

  Future<void> _addTarget(BuildContext context, WidgetRef ref, String studentId) async {
    final period = ref.read(classProgressProvider(classId)).value?.period;
    if (period == null) {
      return;
    }
    final saved = await addTargetForPeriod(context, studentId, period);
    if (saved != null) {
      ref.invalidate(classProgressProvider(classId));
    }
  }

  Future<void> _editTarget(BuildContext context, WidgetRef ref, StudentTarget target) async {
    final saved = await showTargetSheet(context, existing: target);
    if (saved != null) {
      ref.invalidate(classProgressProvider(classId));
    }
  }
}
