import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/recent_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/behaviour_models.dart';
import '../data/behaviour_repository.dart';
import 'behaviour_labels.dart';

/// What was observed in each lesson, with its date: observations of a day, never a label on the child.
class StudentBehaviourCard extends ConsumerWidget {
  const StudentBehaviourCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.behaviourOverview,
      children: [
        AsyncView(
          value: ref.watch(studentBehaviourProvider(studentId)),
          onRetry: () => ref.invalidate(studentBehaviourProvider(studentId)),
          isEmpty: (records) => records.isEmpty,
          empty: Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(
              l10n.behaviourNoRecords,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          data: (records) => RecentList<StudentBehaviour>(
            items: records,
            showAllLabel: l10n.showAll,
            showLessLabel: l10n.showLess,
            itemBuilder: (record) => InfoRow(
              label: formatDate(record.lessonDate),
              value: [
                ...Behaviours.all.where(record.behaviours.contains).map((b) => behaviourLabel(b, l10n)),
                ?record.note,
              ].join(' · '),
            ),
          ),
        ),
      ],
    );
  }
}
