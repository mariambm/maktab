import '../../../core/formatting.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/class_models.dart';

/// "Saturday 10:00–12:00, Sunday 10:00–12:00".
String scheduleText(List<ScheduleSlot> slots, AppLocalizations l10n) => slots
    .map(
      (s) =>
          '${weekdayLabel(s.weekday, l10n)} ${ScheduleSlot.shortTime(s.startTime)}–${ScheduleSlot.shortTime(s.endTime)}',
    )
    .join(', ');
