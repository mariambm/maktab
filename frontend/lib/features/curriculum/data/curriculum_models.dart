import 'package:json_annotation/json_annotation.dart';

part 'curriculum_models.g.dart';

/// A period always runs for four weeks; week 4 is the review week.
const curriculumWeeksPerPeriod = 4;
const curriculumReviewWeek = 4;

/// The mosque's teaching list, as sent by the API.
abstract final class Subjects {
  static const quranRecitation = 'QURAN_RECITATION';
  static const islamicStudies = 'ISLAMIC_STUDIES';
  static const namazAndDuas = 'NAMAZ_AND_DUAS';
  static const arabic = 'ARABIC';
  static const naatsAndSpeeches = 'NAATS_AND_SPEECHES';

  static const all = [quranRecitation, islamicStudies, namazAndDuas, arabic, naatsAndSpeeches];
}

/// One topic of a curriculum week, with the objective the students should reach.
@JsonSerializable(createToJson: false)
class LessonTopic {
  const LessonTopic({
    required this.id,
    this.subject,
    required this.title,
    this.learningObjective,
    required this.sortOrder,
  });

  factory LessonTopic.fromJson(Map<String, dynamic> json) => _$LessonTopicFromJson(json);

  final String id;

  /// Null only for topics written before subjects existed.
  final String? subject;
  final String title;
  final String? learningObjective;
  final int sortOrder;
}

@JsonSerializable(createToJson: false)
class CurriculumWeek {
  const CurriculumWeek({required this.id, required this.weekNumber, required this.review, required this.topics});

  factory CurriculumWeek.fromJson(Map<String, dynamic> json) => _$CurriculumWeekFromJson(json);

  final String id;
  final int weekNumber;
  final bool review;
  final List<LessonTopic> topics;
}

/// A period without its weeks, as shown in lists and in the lesson header.
@JsonSerializable(createToJson: false)
class CurriculumPeriodSummary {
  const CurriculumPeriodSummary({
    required this.id,
    required this.curriculumLevelId,
    required this.number,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory CurriculumPeriodSummary.fromJson(Map<String, dynamic> json) => _$CurriculumPeriodSummaryFromJson(json);

  final String id;
  final String curriculumLevelId;
  final int number;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  bool coversToday(DateTime today) => !today.isBefore(startDate) && !today.isAfter(endDate);
}

@JsonSerializable(createToJson: false)
class CurriculumPeriod {
  const CurriculumPeriod({
    required this.id,
    required this.curriculumLevelId,
    required this.curriculumLevelName,
    required this.number,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.weeks,
  });

  factory CurriculumPeriod.fromJson(Map<String, dynamic> json) => _$CurriculumPeriodFromJson(json);

  final String id;
  final String curriculumLevelId;
  final String curriculumLevelName;
  final int number;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<CurriculumWeek> weeks;
}

/// A topic as the period form sends it.
class LessonTopicDraft {
  const LessonTopicDraft({required this.subject, required this.title, this.learningObjective});

  final String subject;
  final String title;
  final String? learningObjective;

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'title': title.trim(),
    'learningObjective': learningObjective == null || learningObjective!.trim().isEmpty
        ? null
        : learningObjective!.trim(),
  };
}

class CurriculumWeekDraft {
  const CurriculumWeekDraft({required this.weekNumber, required this.review, required this.topics});

  final int weekNumber;
  final bool review;
  final List<LessonTopicDraft> topics;

  Map<String, dynamic> toJson() => {
    'weekNumber': weekNumber,
    'review': review,
    'topics': topics.map((t) => t.toJson()).toList(),
  };
}

/// What the period form sends. The end date follows from the start date, so it is not sent.
class CurriculumPeriodDraft {
  const CurriculumPeriodDraft({
    required this.curriculumLevelId,
    required this.number,
    required this.name,
    required this.startDate,
    required this.weeks,
  });

  final String curriculumLevelId;
  final int number;
  final String name;
  final DateTime startDate;
  final List<CurriculumWeekDraft> weeks;

  Map<String, dynamic> toJson() => {
    'curriculumLevelId': curriculumLevelId,
    'number': number,
    'name': name.trim(),
    'startDate':
        '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-'
        '${startDate.day.toString().padLeft(2, '0')}',
    'weeks': weeks.map((w) => w.toJson()).toList(),
  };
}
