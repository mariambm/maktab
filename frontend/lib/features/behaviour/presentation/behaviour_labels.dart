import '../../../l10n/generated/app_localizations.dart';

String behaviourLabel(String behaviour, AppLocalizations l10n) => switch (behaviour) {
  'GOOD_QURAN_RECITATION' => l10n.behaviourGOOD_QURAN_RECITATION,
  'LEARNED_ISLAMIC_STUDIES' => l10n.behaviourLEARNED_ISLAMIC_STUDIES,
  'LEARNED_NAMAZ_AND_DUAS' => l10n.behaviourLEARNED_NAMAZ_AND_DUAS,
  'LEARNED_NAAT_OR_SPEECH' => l10n.behaviourLEARNED_NAAT_OR_SPEECH,
  'LISTENED_TO_TEACHER' => l10n.behaviourLISTENED_TO_TEACHER,
  'BEEN_HELPFUL' => l10n.behaviourBEEN_HELPFUL,
  'ORGANISED' => l10n.behaviourORGANISED,
  'RESPECTFUL' => l10n.behaviourRESPECTFUL,
  'GOOD_GROUP_WORK' => l10n.behaviourGOOD_GROUP_WORK,
  'USING_TIME_EFFECTIVELY' => l10n.behaviourUSING_TIME_EFFECTIVELY,
  'OFF_TASK' => l10n.behaviourOFF_TASK,
  'NOT_LISTENING' => l10n.behaviourNOT_LISTENING,
  'DISTRACTING' => l10n.behaviourDISTRACTING,
  'TALKING' => l10n.behaviourTALKING,
  'DISORGANISED' => l10n.behaviourDISORGANISED,
  'LACK_OF_EFFORT' => l10n.behaviourLACK_OF_EFFORT,
  'WASTING_TIME' => l10n.behaviourWASTING_TIME,
  'SHOUTING' => l10n.behaviourSHOUTING,
  _ => l10n.behaviourWALKING_OR_RUNNING_AROUND,
};
