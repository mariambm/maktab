import '../../../l10n/generated/app_localizations.dart';
import '../data/curriculum_models.dart';

String subjectLabel(String subject, AppLocalizations l10n) => switch (subject) {
  Subjects.quranRecitation => l10n.subjectQURAN_RECITATION,
  Subjects.islamicStudies => l10n.subjectISLAMIC_STUDIES,
  Subjects.namazAndDuas => l10n.subjectNAMAZ_AND_DUAS,
  Subjects.arabic => l10n.subjectARABIC,
  _ => l10n.subjectNAATS_AND_SPEECHES,
};

/// "Subject · objective" under a topic's title, leaving out whatever is missing.
String? topicSubtitle(LessonTopic topic, AppLocalizations l10n) {
  final parts = [if (topic.subject != null) subjectLabel(topic.subject!, l10n), ?topic.learningObjective];
  return parts.isEmpty ? null : parts.join(' · ');
}
