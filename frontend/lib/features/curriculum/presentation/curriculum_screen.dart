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
import '../../classes/data/class_models.dart';
import '../../classes/data/classes_repository.dart';
import '../data/curriculum_models.dart';
import '../data/curriculum_repository.dart';

/// The four-week periods per level, the one running now first.
class CurriculumScreen extends ConsumerStatefulWidget {
  const CurriculumScreen({super.key});

  @override
  ConsumerState<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends ConsumerState<CurriculumScreen> {
  String? _levelId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = ref.watch(sessionControllerProvider).value?.can(Permissions.curriculumWrite) ?? false;
    final periods = ref.watch(curriculumPeriodsProvider(_levelId));
    final levels = ref.watch(curriculumLevelsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCurriculum)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/curriculum/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.addPeriod),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, 0),
            child: DropdownButtonFormField<String?>(
              initialValue: _levelId,
              decoration: InputDecoration(labelText: l10n.levelLabel),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.allLevels)),
                for (final level in levels.value ?? const <CurriculumLevel>[])
                  DropdownMenuItem(value: level.id, child: Text(level.name)),
              ],
              onChanged: (id) => setState(() => _levelId = id),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(curriculumPeriodsProvider(_levelId).future),
              child: AsyncView(
                value: periods,
                onRetry: () => ref.invalidate(curriculumPeriodsProvider(_levelId)),
                isEmpty: (list) => list.isEmpty,
                empty: MessageView(
                  icon: Icons.menu_book_outlined,
                  title: l10n.curriculumEmpty,
                  message: canManage ? l10n.curriculumEmptyManage : l10n.curriculumEmptyTeacher,
                ),
                data: (list) => ListView(
                  padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, 88),
                  children: [
                    for (final period in list)
                      _PeriodCard(period: period, levelName: levelsById(levels.value)[period.curriculumLevelId]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Periods of every level look alike, so each card says which level it belongs to.
Map<String, String> levelsById(List<CurriculumLevel>? levels) => {
  for (final level in levels ?? const <CurriculumLevel>[]) level.id: level.name,
};

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, this.levelName});

  final CurriculumPeriodSummary period;
  final String? levelName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final runsNow = period.coversToday(dateOnly(DateTime.now()));
    return Card(
      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/curriculum/${period.id}'),
        child: Padding(
          padding: const EdgeInsets.all(MaktabSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(period.name, style: theme.textTheme.titleMedium)),
                        if (runsNow) StatusChip(label: l10n.periodRunsNow, icon: Icons.play_circle_outline),
                      ],
                    ),
                    const SizedBox(height: MaktabSpacing.xs),
                    Text(
                      [
                        ?levelName,
                        l10n.periodNumber(period.number),
                        l10n.periodRange(formatDate(period.startDate), formatDate(period.endDate)),
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
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
