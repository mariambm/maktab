import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../core/theme/maktab_colors.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../curriculum/presentation/subject_labels.dart';
import '../../lessons/presentation/lesson_labels.dart';
import '../../payments/presentation/payment_labels.dart';
import '../../progress/data/progress_models.dart';
import '../../progress/presentation/target_tile.dart';
import '../../uniform/data/uniform_models.dart';
import '../../uniform/presentation/uniform_labels.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';
import 'report_widgets.dart';
import 'reports_screen.dart';

/// One student's report over a chosen period: attendance, progress per subject, targets, behaviour and uniform
/// notes, and their fees for users who may see payments.
class StudentReportScreen extends ConsumerStatefulWidget {
  const StudentReportScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends ConsumerState<StudentReportScreen> {
  ReportRange _range = ReportRange.threeMonths;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dates = _range.datesFrom(DateTime.now());
    final filter = (studentId: widget.studentId, from: dates.from, to: dates.to);
    final report = ref.watch(studentReportProvider(filter));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          report.value == null
              ? l10n.studentReport
              : '${l10n.studentReport}: ${report.value!.firstName} ${report.value!.lastName}',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentReportProvider(filter).future),
        child: ListView(
          padding: const EdgeInsets.all(MaktabSpacing.md),
          children: [
            ReportFilterBarRangeOnly(range: _range, onChanged: (range) => setState(() => _range = range)),
            const SizedBox(height: MaktabSpacing.md),
            switch (report) {
              AsyncData(:final value) => _Report(report: value),
              _ => SizedBox(
                height: 360,
                child: AsyncView(
                  value: report,
                  onRetry: () => ref.invalidate(studentReportProvider(filter)),
                  data: (_) => const SizedBox.shrink(),
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// Only the period choice, for a report that is already about one student.
class ReportFilterBarRangeOnly extends StatelessWidget {
  const ReportFilterBarRangeOnly({super.key, required this.range, required this.onChanged});

  final ReportRange range;
  final ValueChanged<ReportRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<ReportRange>(
        segments: [
          for (final option in ReportRange.values) ButtonSegment(value: option, label: Text(option.label(l10n))),
        ],
        selected: {range},
        showSelectedIcon: false,
        onSelectionChanged: (choice) => onChanged(choice.first),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});

  final StudentReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final attendance = report.attendance;
    final low = attendance.belowThreshold;
    final payments = report.payments;
    final sections = <Widget>[
      Text(
        [?report.className, reportDates(report.from, report.to, l10n)].join(' · '),
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      StatRow(
        tiles: [
          StatTile(
            value: attendance.attendancePercentage == null ? '–' : '${attendance.attendancePercentage}%',
            label: low ? l10n.reportBelowThreshold(attendance.thresholdPercentage) : l10n.reportAttendanceRate,
            color: low ? MaktabColors.warning : MaktabColors.success,
            icon: low ? Icons.warning_amber_rounded : null,
          ),
          StatTile(value: '${attendance.lessons}', label: l10n.reportLessons, color: MaktabColors.primaryDark),
          StatTile(value: '${attendance.late}', label: l10n.attendanceLATE, color: MaktabColors.warning),
          StatTile(value: '${attendance.absent}', label: l10n.attendanceABSENT, color: MaktabColors.danger),
        ],
      ),
      if (attendance.absenceReasons.isNotEmpty)
        ReportSection(
          title: l10n.reportAbsenceReasons,
          children: [
            for (final reason in attendance.absenceReasons.entries)
              ReportRow(title: absenceReasonLabel(reason.key, l10n), trailing: Text('${reason.value}')),
          ],
        ),
      ReportSection(
        title: l10n.progressOverview,
        empty: l10n.reportNoProgress,
        children: [
          for (final subject in report.progress)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MaktabSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(subjectLabel(subject.subject, l10n), style: theme.textTheme.bodyLarge)),
                      Text(
                        subject.averageScore == null ? '–' : l10n.reportAverageOf(formatScore(subject.averageScore!)),
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: MaktabSpacing.xs),
                  ShareBar(value: subject.averageScore ?? 0, max: 5),
                  const SizedBox(height: MaktabSpacing.xs),
                  Text(
                    [
                      l10n.reportScoreCount(subject.scores),
                      if (subject.latestScore != null && subject.latestDate != null)
                        l10n.reportProgressLatest(
                          formatScore(subject.latestScore!),
                          subject.latestLabel ?? '',
                          formatDate(subject.latestDate!),
                        ),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
      ReportSection(
        title: l10n.reportTargets,
        empty: l10n.reportNoTargets,
        children: [for (final target in report.targets) TargetTile(target: target)],
      ),
      ReportSection(
        title: l10n.behaviourOverview,
        empty: l10n.reportNoObservations,
        children: [for (final count in report.behaviour) BehaviourCountRow(count: count)],
      ),
      ReportSection(
        title: l10n.reportUniform,
        empty: report.uniform.total == 0 ? l10n.reportUniformNone : null,
        children: [
          if (report.uniform.total > 0)
            for (final (status, count) in [
              (UniformStatuses.inOrder, report.uniform.inOrder),
              (UniformStatuses.partiallyInOrder, report.uniform.partiallyInOrder),
              (UniformStatuses.notInOrder, report.uniform.notInOrder),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(uniformStatusIcon(status)),
                title: Text(uniformStatusLabel(status, l10n)),
                trailing: Text('$count'),
              ),
        ],
      ),
      if (payments != null)
        ReportSection(
          title: l10n.reportStudentFees,
          empty: payments.months == 0 ? l10n.reportNoFees : null,
          children: [
            if (payments.months > 0) ...[
              ReportRow(
                title: l10n.reportExpected,
                subtitle: l10n.reportMonthsOwing(payments.months),
                trailing: Text(formatMoney(payments.expectedTotal, payments.currency)),
              ),
              ReportRow(title: l10n.reportReceived, trailing: Text(formatMoney(payments.paidTotal, payments.currency))),
              ReportRow(
                title: l10n.reportOutstanding,
                subtitle: payments.monthsOwing == 0 ? null : l10n.reportMonthsOwing(payments.monthsOwing),
                trailing: Text(
                  formatMoney(payments.outstandingTotal, payments.currency),
                  style: TextStyle(
                    color: payments.outstandingTotal > 0 ? MaktabColors.danger : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[section, const SizedBox(height: MaktabSpacing.md)],
      ],
    );
  }
}
