import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/lesson_models.dart';

String attendanceLabel(String status, AppLocalizations l10n) => switch (status) {
  AttendanceStatuses.present => l10n.attendancePRESENT,
  AttendanceStatuses.late => l10n.attendanceLATE,
  _ => l10n.attendanceABSENT,
};

IconData attendanceIcon(String status) => switch (status) {
  AttendanceStatuses.present => Icons.check_circle_outline,
  AttendanceStatuses.late => Icons.schedule,
  _ => Icons.cancel_outlined,
};

String absenceReasonLabel(String reason, AppLocalizations l10n) => switch (reason) {
  AbsenceReasons.authorised => l10n.absenceAUTHORISED,
  AbsenceReasons.unauthorised => l10n.absenceUNAUTHORISED,
  AbsenceReasons.sick => l10n.absenceSICK,
  AbsenceReasons.holiday => l10n.absenceHOLIDAY,
  _ => l10n.absenceNOT_READING,
};

String lessonStatusLabel(String status, AppLocalizations l10n) => switch (status) {
  LessonStatuses.completed => l10n.lessonCOMPLETED,
  LessonStatuses.cancelled => l10n.lessonCANCELLED,
  _ => l10n.lessonPLANNED,
};

/// `HH:mm` from the API's `HH:mm:ss`.
String shortTime(String time) => time.length >= 5 ? time.substring(0, 5) : time;
