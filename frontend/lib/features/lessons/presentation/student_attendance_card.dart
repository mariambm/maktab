import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/lessons_repository.dart';

/// A student's attendance, counted by the server on every request so no figure is ever stale.
class StudentAttendanceCard extends ConsumerWidget {
  const StudentAttendanceCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statistics = ref.watch(studentAttendanceStatisticsProvider(studentId));
    return SectionCard(
      title: l10n.attendanceOverview,
      children: [
        AsyncView(
          value: statistics,
          onRetry: () => ref.invalidate(studentAttendanceStatisticsProvider(studentId)),
          isEmpty: (s) => s.lessons == 0,
          empty: Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(
              l10n.attendanceNoRecords,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.attendancePercentage(s.attendancePercentage ?? 0),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (s.belowThreshold)
                    StatusChip(
                      label: l10n.attendanceBelowThreshold(s.threshold),
                      icon: Icons.warning_amber_outlined,
                      muted: true,
                    ),
                ],
              ),
              const SizedBox(height: MaktabSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
                child: Text(
                  l10n.attendanceLessonsCounted(s.lessons),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              InfoRow(label: l10n.attendancePRESENT, value: '${s.present}'),
              InfoRow(label: l10n.attendanceLATE, value: '${s.late}'),
              InfoRow(label: l10n.attendanceABSENT, value: '${s.absent}'),
            ],
          ),
        ),
      ],
    );
  }
}
