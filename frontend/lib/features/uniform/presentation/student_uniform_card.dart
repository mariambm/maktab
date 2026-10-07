import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/recent_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/uniform_models.dart';
import '../data/uniform_repository.dart';
import 'uniform_labels.dart';

/// Uniform as noted per lesson, newest first.
class StudentUniformCard extends ConsumerWidget {
  const StudentUniformCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.uniformOverview,
      children: [
        AsyncView(
          value: ref.watch(studentUniformProvider(studentId)),
          onRetry: () => ref.invalidate(studentUniformProvider(studentId)),
          isEmpty: (records) => records.isEmpty,
          empty: Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(
              l10n.uniformNoRecords,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          data: (records) => RecentList<StudentUniform>(
            items: records,
            showAllLabel: l10n.showAll,
            showLessLabel: l10n.showLess,
            itemBuilder: (record) => InfoRow(
              label: formatDate(record.lessonDate),
              value: [
                uniformStatusLabel(record.status, l10n),
                if (record.reason != null) uniformReasonLabel(record.reason!, l10n),
                ?record.note,
              ].join(' · '),
            ),
          ),
        ),
      ],
    );
  }
}
