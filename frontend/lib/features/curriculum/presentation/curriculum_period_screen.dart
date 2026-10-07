import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/curriculum_models.dart';
import '../data/curriculum_repository.dart';
import 'subject_labels.dart';

/// One period: four weeks of topics, with their learning objectives.
class CurriculumPeriodScreen extends ConsumerWidget {
  const CurriculumPeriodScreen({super.key, required this.periodId});

  final String periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final period = ref.watch(curriculumPeriodProvider(periodId));
    final canManage = ref.watch(sessionControllerProvider).value?.can(Permissions.curriculumWrite) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(period.value?.name ?? l10n.navCurriculum),
        actions: [
          if (canManage && period.hasValue)
            IconButton(
              tooltip: l10n.editPeriod,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/curriculum/$periodId/edit'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(curriculumPeriodProvider(periodId).future),
        child: AsyncView(
          value: period,
          onRetry: () => ref.invalidate(curriculumPeriodProvider(periodId)),
          data: (p) => ListView(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            children: [
              SectionCard(
                title: l10n.periodNumber(p.number),
                children: [
                  InfoRow(label: l10n.levelLabel, value: p.curriculumLevelName),
                  InfoRow(
                    label: l10n.periodDatesLabel,
                    value: l10n.periodRange(formatDate(p.startDate), formatDate(p.endDate)),
                  ),
                ],
              ),
              for (final week in [...p.weeks]..sort((a, b) => a.weekNumber.compareTo(b.weekNumber))) ...[
                const SizedBox(height: MaktabSpacing.sm),
                _WeekCard(week: week),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final CurriculumWeek week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.curriculumWeekLabel(week.weekNumber),
      action: week.review ? StatusChip(label: l10n.curriculumReviewWeek, icon: Icons.replay_outlined) : null,
      children: [
        if (week.topics.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(
              l10n.weekNoTopics,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        for (final topic in week.topics)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bookmark_border),
            title: Text(topic.title),
            subtitle: switch (topicSubtitle(topic, l10n)) {
              final text? => Text(text),
              null => null,
            },
          ),
      ],
    );
  }
}
