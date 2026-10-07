import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';

final _date = DateFormat('d MMM yyyy', 'en');

/// A date as shown everywhere in Maktab, for example "14 Mar 2017".
String formatDate(DateTime date) => _date.format(date);

String relationshipLabel(String relationship, AppLocalizations l10n) => switch (relationship) {
  'MOTHER' => l10n.relationshipMother,
  'FATHER' => l10n.relationshipFather,
  'GUARDIAN' => l10n.relationshipGuardian,
  _ => l10n.relationshipOther,
};

String weekdayLabel(String weekday, AppLocalizations l10n) => switch (weekday) {
  'MONDAY' => l10n.weekdayMONDAY,
  'TUESDAY' => l10n.weekdayTUESDAY,
  'WEDNESDAY' => l10n.weekdayWEDNESDAY,
  'THURSDAY' => l10n.weekdayTHURSDAY,
  'FRIDAY' => l10n.weekdayFRIDAY,
  'SATURDAY' => l10n.weekdaySATURDAY,
  _ => l10n.weekdaySUNDAY,
};

String genderLabel(String? gender, AppLocalizations l10n) => switch (gender) {
  'FEMALE' => l10n.genderFemale,
  'MALE' => l10n.genderMale,
  _ => l10n.genderNotRecorded,
};

/// The date part of [now], without time.
DateTime dateOnly(DateTime now) => DateTime(now.year, now.month, now.day);

final _dateTime = DateFormat('d MMM yyyy, HH:mm', 'en');

/// A moment in local time, for example "14 Mar 2026, 09:30".
String formatDateTime(DateTime moment) => _dateTime.format(moment.toLocal());

const _weekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

/// The API's spelling of a date's weekday, for example `SATURDAY`.
String apiWeekday(DateTime date) => _weekdays[date.weekday - 1];
