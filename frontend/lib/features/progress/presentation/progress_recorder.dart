import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../curriculum/data/curriculum_models.dart';
import '../../curriculum/presentation/subject_labels.dart';
import '../../lessons/data/lesson_models.dart';
import '../../lessons/presentation/lesson_detail_screen.dart';
import '../data/progress_models.dart';
import '../data/progress_repository.dart';

/// A score per student for one subject at a time, on the mosque's own scale, saved in one request.
class ProgressRecorder extends ConsumerWidget {
  const ProgressRecorder({super.key, required this.lesson, this.readOnly = false});

  final LessonDetail lesson;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scale = ref.watch(progressScaleProvider);
    final progress = ref.watch(lessonProgressProvider(lesson.id));
    return SectionCard(
      title: l10n.progressSection,
      children: [
        AsyncView(
          value: scale,
          onRetry: () => ref.invalidate(progressScaleProvider),
          data: (levels) => AsyncView(
            value: progress,
            onRetry: () => ref.invalidate(lessonProgressProvider(lesson.id)),
            data: (saved) => _ProgressForm(lesson: lesson, scale: levels, saved: saved, readOnly: readOnly),
          ),
        ),
      ],
    );
  }
}

class _ProgressForm extends ConsumerStatefulWidget {
  const _ProgressForm({required this.lesson, required this.scale, required this.saved, required this.readOnly});

  final LessonDetail lesson;
  final List<ProgressScaleLevel> scale;
  final LessonProgress saved;
  final bool readOnly;

  @override
  ConsumerState<_ProgressForm> createState() => _ProgressFormState();
}

class _ProgressFormState extends ConsumerState<_ProgressForm> {
  late String _subject = _defaultSubject(widget.lesson);
  late Map<String, double> _scores = widget.saved.scoresFor(_subject);
  bool _saving = false;

  /// The subject of the first topic this week, which is usually what the teacher scores; Quran otherwise.
  static String _defaultSubject(LessonDetail lesson) {
    for (final topic in lesson.availableTopics) {
      if (topic.subject != null) {
        return topic.subject!;
      }
    }
    return Subjects.quranRecitation;
  }

  @override
  void didUpdateWidget(_ProgressForm old) {
    super.didUpdateWidget(old);
    if (!identical(old.saved, widget.saved)) {
      _scores = widget.saved.scoresFor(_subject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final students = widget.lesson.students;
    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
        child: Text(l10n.lessonNoStudents, style: _mutedStyle(context)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: MaktabSpacing.sm, bottom: MaktabSpacing.sm),
          child: DropdownButtonFormField<String>(
            key: const Key('progress.subject'),
            initialValue: _subject,
            decoration: InputDecoration(labelText: l10n.progressSubjectHint),
            items: [
              for (final subject in Subjects.all)
                DropdownMenuItem(value: subject, child: Text(subjectLabel(subject, l10n))),
            ],
            onChanged: (subject) => setState(() {
              _subject = subject!;
              _scores = widget.saved.scoresFor(_subject);
            }),
          ),
        ),
        for (final student in students)
          _StudentScoreRow(
            student: student,
            scale: widget.scale,
            score: _scores[student.studentId],
            readOnly: widget.readOnly,
            onChanged: (score) => setState(() {
              if (score == null) {
                _scores.remove(student.studentId);
              } else {
                _scores[student.studentId] = score;
              }
            }),
          ),
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.only(right: MaktabSpacing.sm, bottom: MaktabSpacing.sm),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.saveProgress),
            ),
          ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(progressRepositoryProvider).save(widget.lesson.id, _subject, Map.of(_scores));
      ref.invalidate(lessonProgressProvider(widget.lesson.id));
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.progressSaved)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      showSaveError(context, error);
    }
  }
}

class _StudentScoreRow extends StatelessWidget {
  const _StudentScoreRow({
    required this.student,
    required this.scale,
    required this.score,
    required this.readOnly,
    required this.onChanged,
  });

  final LessonStudent student;
  final List<ProgressScaleLevel> scale;
  final double? score;
  final bool readOnly;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final absent = student.status == AttendanceStatuses.absent;
    final level = scale.where((l) => l.score == score).firstOrNull;
    final summary = absent && score == null
        ? l10n.progressAbsent
        : level == null
        ? l10n.progressNoScore
        : '${formatScore(level.score)} · ${level.label}';
    return Padding(
      padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(student.displayName, style: theme.textTheme.bodyLarge)),
              Padding(
                padding: const EdgeInsets.only(right: MaktabSpacing.sm),
                child: Text(summary, style: _mutedStyle(context)),
              ),
            ],
          ),
          if (!readOnly && !absent) ...[
            const SizedBox(height: MaktabSpacing.xs),
            Wrap(
              spacing: MaktabSpacing.xs,
              runSpacing: MaktabSpacing.xs,
              children: [
                for (final option in scale)
                  ChoiceChip(
                    label: Text(formatScore(option.score)),
                    tooltip: option.label,
                    selected: option.score == score,
                    showCheckmark: false,
                    // Tapping the chosen score again clears it.
                    onSelected: (selected) => onChanged(selected ? option.score : null),
                  ),
              ],
            ),
          ],
          const Divider(height: MaktabSpacing.md),
        ],
      ),
    );
  }
}

TextStyle? _mutedStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
}
