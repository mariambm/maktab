import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_colors.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../behaviour/presentation/behaviour_labels.dart';
import '../../curriculum/presentation/subject_labels.dart';
import '../../lessons/presentation/lesson_labels.dart';
import '../../payments/presentation/payment_labels.dart';
import '../../progress/data/progress_models.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';
import 'report_widgets.dart';

/// Reports on attendance, progress, behaviour and, for users with payment access, fees. Every figure covers only
/// the classes the user may see; a student in a list opens their own report.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportRange _range = ReportRange.fourWeeks;
  String? _classId;

  ReportFilter get _filter {
    final dates = _range.datesFrom(DateTime.now());
    return (from: dates.from, to: dates.to, classId: _classId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSeePayments = ref.watch(sessionControllerProvider).value?.can(Permissions.paymentRead) ?? false;
    final tabs = [
      Tab(text: l10n.reportsTabAttendance),
      Tab(text: l10n.reportsTabProgress),
      Tab(text: l10n.reportsTabBehaviour),
      if (canSeePayments) Tab(text: l10n.reportsTabPayments),
    ];
    final filters = ReportFilterBar(
      range: _range,
      onRangeChanged: (range) => setState(() => _range = range),
      classId: _classId,
      onClassChanged: (id) => setState(() => _classId = id),
    );
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navReports),
          bottom: TabBar(tabs: tabs, isScrollable: true, tabAlignment: TabAlignment.start),
        ),
        body: TabBarView(
          children: [
            _AttendanceTab(filter: _filter, filters: filters),
            _ProgressTab(
              classId: _classId,
              filters: ReportFilterBar(classId: _classId, onClassChanged: (id) => setState(() => _classId = id)),
            ),
            _BehaviourTab(filter: _filter, filters: filters),
            if (canSeePayments) const _PaymentsTab(),
          ],
        ),
      ),
    );
  }
}

void _openStudent(BuildContext context, String studentId) => context.push('/students/$studentId/report');

/// A scrolling report with its filters on top and pull to refresh.
class _ReportList<T> extends StatelessWidget {
  const _ReportList({required this.value, required this.onRefresh, required this.children, this.filters});

  final AsyncValue<T> value;
  final Future<void> Function() onRefresh;
  final Widget? filters;
  final List<Widget> Function(T data) children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(MaktabSpacing.md),
        children: [
          if (filters != null) ...[filters!, const SizedBox(height: MaktabSpacing.md)],
          switch (value) {
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final child in children(value)) ...[child, const SizedBox(height: MaktabSpacing.md)],
              ],
            ),
            _ => SizedBox(
              height: 360,
              child: AsyncView(value: value, onRetry: () => onRefresh(), data: (_) => const SizedBox.shrink()),
            ),
          },
        ],
      ),
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.filter, required this.filters});

  final ReportFilter filter;
  final Widget filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _ReportList<AttendanceReport>(
      value: ref.watch(attendanceReportProvider(filter)),
      onRefresh: () => ref.refresh(attendanceReportProvider(filter).future),
      filters: filters,
      children: (report) {
        final totals = report.totals;
        final threshold = report.thresholdPercentage;
        final low = totals.attendancePercentage != null && totals.attendancePercentage! < threshold;
        return [
          Text(reportDates(report.from, report.to, l10n)),
          StatRow(
            tiles: [
              StatTile(
                value: totals.attendancePercentage == null ? '–' : '${totals.attendancePercentage}%',
                label: l10n.reportAttendanceRate,
                color: low ? MaktabColors.warning : MaktabColors.success,
                icon: low ? Icons.warning_amber_rounded : null,
              ),
              StatTile(value: '${totals.lessons}', label: l10n.reportLessons, color: MaktabColors.primaryDark),
              StatTile(value: '${totals.present}', label: l10n.attendancePRESENT, color: MaktabColors.success),
              StatTile(value: '${totals.late}', label: l10n.attendanceLATE, color: MaktabColors.warning),
              StatTile(value: '${totals.absent}', label: l10n.attendanceABSENT, color: MaktabColors.danger),
            ],
          ),
          ReportSection(
            title: l10n.reportByClass,
            empty: l10n.reportNoRegisters,
            children: [
              for (final row in report.classes)
                ReportRow(
                  title: row.className ?? '',
                  subtitle: [
                    l10n.attendanceLessonsCounted(row.counts.lessons),
                    l10n.reportLateAbsent(row.counts.late, row.counts.absent),
                  ].join(' · '),
                  trailing: AttendanceChip(percentage: row.counts.attendancePercentage, threshold: threshold),
                ),
            ],
          ),
          ReportSection(
            title: l10n.reportBelowThreshold(threshold),
            empty: totals.records == 0 ? l10n.reportNoRegisters : l10n.reportBelowThresholdNone(threshold),
            children: [
              for (final student in report.belowThreshold)
                ReportRow(
                  title: '${student.firstName} ${student.lastName}',
                  subtitle: [
                    ?student.className,
                    l10n.reportAttendedOf(student.counts.present + student.counts.late, student.counts.records),
                  ].join(' · '),
                  trailing: AttendanceChip(percentage: student.counts.attendancePercentage, threshold: threshold),
                  onTap: () => _openStudent(context, student.studentId),
                ),
            ],
          ),
          if (report.absenceReasons.isNotEmpty)
            ReportSection(
              title: l10n.reportAbsenceReasons,
              children: [
                for (final reason in report.absenceReasons.entries)
                  ReportRow(title: absenceReasonLabel(reason.key, l10n), trailing: Text('${reason.value}')),
              ],
            ),
        ];
      },
    );
  }
}

class _ProgressTab extends ConsumerWidget {
  const _ProgressTab({required this.classId, required this.filters});

  final String? classId;
  final Widget filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _ReportList<ProgressReport>(
      value: ref.watch(progressReportProvider(classId)),
      onRefresh: () => ref.refresh(progressReportProvider(classId).future),
      filters: filters,
      children: (report) => [
        ReportSection(
          title: l10n.reportByClass,
          empty: l10n.reportNoClasses,
          children: [
            for (final row in report.classes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: MaktabSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(row.className, style: theme.textTheme.bodyLarge)),
                        Text(
                          row.averageScore == null
                              ? l10n.reportNoScores
                              : l10n.reportAverageOf(formatScore(row.averageScore!)),
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: MaktabSpacing.xs),
                    ShareBar(value: row.averageScore ?? 0, max: 5),
                    const SizedBox(height: MaktabSpacing.xs),
                    Text(
                      [
                        row.period == null
                            ? l10n.reportNoPeriod
                            : l10n.progressPeriodOf(
                                row.period!.name,
                                formatDate(row.period!.startDate),
                                formatDate(row.period!.endDate),
                              ),
                        l10n.reportScoreCount(row.scores),
                        row.targets == 0
                            ? l10n.reportNoTargetsSet
                            : l10n.reportTargetsBehind(row.targetsBehind, row.targets),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          ],
        ),
        ReportSection(
          title: l10n.reportBehindTarget,
          empty: l10n.reportBehindTargetNone,
          children: [
            for (final target in report.behindTarget)
              ReportRow(
                title: '${target.firstName} ${target.lastName}',
                subtitle: [
                  target.className,
                  if (target.subject != null) subjectLabel(target.subject!, l10n),
                  target.description,
                  l10n.reportCurrentOfTarget(
                    target.currentPercentage?.toString() ?? '–',
                    target.targetPercentage?.toString() ?? '–',
                  ),
                ].join(' · '),
                onTap: () => _openStudent(context, target.studentId),
              ),
          ],
        ),
        if (report.periods.isNotEmpty)
          ReportSection(
            title: l10n.reportPeriodTrend,
            children: [
              for (final period in report.periods)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: MaktabSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(period.period.name)),
                          Text(
                            period.averageScore == null
                                ? l10n.reportScoreCount(0)
                                : '${l10n.reportAverageOf(formatScore(period.averageScore!))} · '
                                      '${l10n.reportScoreCount(period.scores)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: MaktabSpacing.xs),
                      ShareBar(value: period.averageScore ?? 0, max: 5),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _BehaviourTab extends ConsumerWidget {
  const _BehaviourTab({required this.filter, required this.filters});

  final ReportFilter filter;
  final Widget filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _ReportList<BehaviourReport>(
      value: ref.watch(behaviourReportProvider(filter)),
      onRefresh: () => ref.refresh(behaviourReportProvider(filter).future),
      filters: filters,
      children: (report) {
        final good = report.behaviours.where((b) => b.good).fold(0, (sum, b) => sum + b.count);
        final attention = report.behaviours.where((b) => !b.good).fold(0, (sum, b) => sum + b.count);
        return [
          Text(reportDates(report.from, report.to, l10n)),
          StatRow(
            tiles: [
              StatTile(
                value: '${report.observations}',
                label: l10n.reportObservations,
                color: MaktabColors.primaryDark,
              ),
              StatTile(
                value: '$good',
                label: l10n.reportGood,
                color: MaktabColors.success,
                icon: Icons.thumb_up_alt_outlined,
              ),
              StatTile(
                value: '$attention',
                label: l10n.reportNeedsAttention,
                color: MaktabColors.warning,
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          ReportSection(
            title: l10n.reportRecurring(report.recurringAtLeast),
            empty: report.observations == 0
                ? l10n.reportNoObservations
                : l10n.reportRecurringNone(report.recurringAtLeast),
            children: [
              for (final row in report.recurring)
                ReportRow(
                  title: '${row.firstName} ${row.lastName}',
                  subtitle: [
                    ?row.className,
                    behaviourLabel(row.behaviour, l10n),
                    l10n.reportTimes(row.count),
                    l10n.reportLastSeen(formatDate(row.lastSeen)),
                  ].join(' · '),
                  onTap: () => _openStudent(context, row.studentId),
                ),
            ],
          ),
          ReportSection(
            title: l10n.reportMostSeen,
            empty: l10n.reportNoObservations,
            children: [for (final count in report.behaviours) BehaviourCountRow(count: count)],
          ),
        ];
      },
    );
  }
}

/// How often a behaviour was seen, marked good or needs attention by icon and text as well as colour.
class BehaviourCountRow extends StatelessWidget {
  const BehaviourCountRow({super.key, required this.count});

  final BehaviourCount count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        count.good ? Icons.thumb_up_alt_outlined : Icons.flag_outlined,
        color: count.good ? MaktabColors.success : MaktabColors.warning,
        semanticLabel: count.good ? l10n.reportGood : l10n.reportNeedsAttention,
      ),
      title: Text(behaviourLabel(count.behaviour, l10n)),
      subtitle: Text(count.good ? l10n.reportGood : l10n.reportNeedsAttention),
      trailing: Text(l10n.reportTimes(count.count)),
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _ReportList<PaymentReport>(
      value: ref.watch(paymentReportProvider),
      onRefresh: () => ref.refresh(paymentReportProvider.future),
      children: (report) {
        final currency = report.currency;
        final totals = report.totals;
        if (report.months.isEmpty) {
          return [ReportSection(title: l10n.reportMonths, empty: l10n.reportNoMonths, children: const [])];
        }
        return [
          Text(l10n.reportDates(formatMonth(report.months.last.month), formatMonth(report.months.first.month))),
          StatRow(
            minWidth: 140,
            tiles: [
              StatTile(
                value: formatMoney(totals.paidTotal, currency),
                label: l10n.reportReceived,
                color: MaktabColors.success,
              ),
              StatTile(
                value: formatMoney(totals.outstandingTotal, currency),
                label: l10n.reportOutstanding,
                color: totals.outstandingTotal > 0 ? MaktabColors.danger : MaktabColors.success,
                icon: totals.outstandingTotal > 0 ? Icons.error_outline : null,
              ),
              StatTile(
                value: formatMoney(totals.expectedTotal, currency),
                label: l10n.reportExpected,
                color: MaktabColors.primaryDark,
              ),
            ],
          ),
          ReportSection(
            title: l10n.reportMonths,
            children: [
              for (final month in report.months)
                ReportRow(
                  title: formatMonth(month.month),
                  subtitle: [
                    l10n.paymentReceivedOf(
                      formatMoney(month.totals.paidTotal, currency),
                      formatMoney(month.totals.expectedTotal, currency),
                    ),
                    l10n.paymentCounts(month.totals.paid, month.totals.partiallyPaid, month.totals.outstanding),
                  ].join('\n'),
                  onTap: () => context.push('/payments/${month.id}'),
                ),
            ],
          ),
          ReportSection(
            title: l10n.reportStudentsOwing,
            empty: l10n.reportNobodyOwes,
            children: [
              for (final student in report.studentsOwing)
                ReportRow(
                  title: '${student.firstName} ${student.lastName}',
                  subtitle: [?student.className, l10n.reportMonthsOwing(student.months)].join(' · '),
                  trailing: Text(formatMoney(student.outstandingAmount, currency)),
                  onTap: () => _openStudent(context, student.studentId),
                ),
            ],
          ),
        ];
      },
    );
  }
}
