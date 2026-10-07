import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/recent_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../curriculum/presentation/subject_labels.dart';
import '../data/progress_models.dart';
import '../data/progress_repository.dart';

/// A student's scores, newest lesson first, each with the date and subject it was given for.
class StudentProgressCard extends ConsumerWidget {
  const StudentProgressCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.progressOverview,
      children: [
        AsyncView(
          value: ref.watch(studentProgressProvider(studentId)),
          onRetry: () => ref.invalidate(studentProgressProvider(studentId)),
          isEmpty: (scores) => scores.isEmpty,
          empty: Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(
              l10n.progressNoRecords,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          data: (scores) => RecentList<StudentScore>(
            items: scores,
            showAllLabel: l10n.showAll,
            showLessLabel: l10n.showLess,
            itemBuilder: (score) => InfoRow(
              label: formatDate(score.lessonDate),
              value: [
                subjectLabel(score.subject, l10n),
                [formatScore(score.score), ?score.label].join(' '),
                ?score.note,
              ].join(' · '),
            ),
          ),
        ),
      ],
    );
  }
}
