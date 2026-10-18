import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../core/theme/maktab_colors.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../classes/data/classes_repository.dart';

/// The periods a report can cover, counted back from today.
enum ReportRange {
  fourWeeks(28),
  threeMonths(91),
  year(365);

  const ReportRange(this.days);

  final int days;

  /// The first and last day, today included.
  ({DateTime from, DateTime to}) datesFrom(DateTime today) {
    final to = dateOnly(today);
    return (from: to.subtract(Duration(days: days - 1)), to: to);
  }

  String label(AppLocalizations l10n) => switch (this) {
    ReportRange.fourWeeks => l10n.reportRangeFourWeeks,
    ReportRange.threeMonths => l10n.reportRangeThreeMonths,
    ReportRange.year => l10n.reportRangeYear,
  };
}

/// The choice of period and, when [classId] is wanted, of class above a report.
class ReportFilterBar extends ConsumerWidget {
  const ReportFilterBar({
    super.key,
    this.range,
    this.onRangeChanged,
    required this.classId,
    required this.onClassChanged,
  });

  final ReportRange? range;
  final ValueChanged<ReportRange>? onRangeChanged;
  final String? classId;
  final ValueChanged<String?> onClassChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final classes = ref.watch(classesProvider).value?.where((c) => c.active).toList() ?? const [];
    final selected = classes.any((c) => c.id == classId) ? classId : null;
    return Wrap(
      spacing: MaktabSpacing.sm,
      runSpacing: MaktabSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (range != null)
          SegmentedButton<ReportRange>(
            segments: [
              for (final option in ReportRange.values) ButtonSegment(value: option, label: Text(option.label(l10n))),
            ],
            selected: {range!},
            showSelectedIcon: false,
            onSelectionChanged: (choice) => onRangeChanged?.call(choice.first),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: DropdownButtonFormField<String?>(
            key: ValueKey(selected),
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.classLabel, isDense: true),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.filterAllClasses)),
              for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: onClassChanged,
          ),
        ),
      ],
    );
  }
}

/// "1 Oct 2026 – 28 Oct 2026", the dates a report covers.
String reportDates(DateTime from, DateTime to, AppLocalizations l10n) =>
    l10n.reportDates(formatDate(from), formatDate(to));

/// An attendance percentage with an icon and, below the threshold, a warning: never colour alone.
class AttendanceChip extends StatelessWidget {
  const AttendanceChip({super.key, required this.percentage, required this.threshold});

  final int? percentage;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final low = percentage != null && percentage! < threshold;
    final (background, foreground, icon) = switch (percentage) {
      null => (MaktabColors.outline, MaktabColors.primaryDark, Icons.remove),
      _ when low => (MaktabColors.warningContainer, MaktabColors.onWarningContainer, Icons.warning_amber_rounded),
      _ => (MaktabColors.successContainer, MaktabColors.onSuccessContainer, Icons.check_circle_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 4),
          Text(
            percentage == null ? '–' : '$percentage%',
            style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A titled card that holds a report section, with a quiet line when there is nothing to show.
class ReportSection extends StatelessWidget {
  const ReportSection({super.key, required this.title, required this.children, this.empty, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) Text(subtitle!, style: muted),
            const SizedBox(height: MaktabSpacing.xs),
            if (children.isEmpty && empty != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: MaktabSpacing.sm),
                child: Text(empty!, style: muted),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A row inside a [ReportSection]: a title, an optional second line, and something on the right.
class ReportRow extends StatelessWidget {
  const ReportRow({super.key, required this.title, this.subtitle, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}

/// A bar that shows a share of a whole next to the number itself, for averages and percentages.
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.value, required this.max, this.color = MaktabColors.primary});

  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: max <= 0 ? 0 : (value / max).clamp(0, 1),
        minHeight: 6,
        backgroundColor: MaktabColors.outline,
        color: color,
      ),
    );
  }
}
