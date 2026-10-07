import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/lesson_models.dart';
import '../data/lessons_repository.dart';
import 'lesson_detail_screen.dart';
import 'lesson_labels.dart';
import '../../curriculum/presentation/subject_labels.dart';

/// What was taught: the topics of this curriculum week, a free note, and whether the lesson went ahead.
class LessonContentEditor extends ConsumerStatefulWidget {
  const LessonContentEditor({super.key, required this.lesson, this.readOnly = false});

  final LessonDetail lesson;
  final bool readOnly;

  @override
  ConsumerState<LessonContentEditor> createState() => _LessonContentEditorState();
}

class _LessonContentEditorState extends ConsumerState<LessonContentEditor> {
  late final TextEditingController _notes = TextEditingController(text: widget.lesson.contentNotes ?? '');
  late Set<String> _covered = widget.lesson.coveredTopicIds.toSet();
  late String _status = widget.lesson.status;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final topics = widget.lesson.availableTopics;
    return SectionCard(
      title: l10n.lessonContentSection,
      children: [
        if (topics.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(l10n.lessonNoTopics, style: muted),
          )
        else ...[
          Text(l10n.lessonTopicsSection, style: theme.textTheme.titleSmall),
          for (final topic in topics)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _covered.contains(topic.id),
              title: Text(topic.title),
              subtitle: switch (topicSubtitle(topic, l10n)) {
                final text? => Text(text),
                null => null,
              },
              onChanged: widget.readOnly
                  ? null
                  : (checked) => setState(() {
                      if (checked ?? false) {
                        _covered = {..._covered, topic.id};
                      } else {
                        _covered = {..._covered}..remove(topic.id);
                      }
                    }),
            ),
        ],
        const SizedBox(height: MaktabSpacing.sm),
        if (widget.readOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(widget.lesson.contentNotes ?? l10n.notSet, style: muted),
          )
        else ...[
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: l10n.lessonNotesLabel,
              hintText: l10n.lessonNotesHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: MaktabSpacing.sm),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final status in const [LessonStatuses.planned, LessonStatuses.completed, LessonStatuses.cancelled])
                ButtonSegment(value: status, label: Text(lessonStatusLabel(status, l10n))),
            ],
            selected: {_status},
            onSelectionChanged: (selection) => setState(() => _status = selection.first),
          ),
          const SizedBox(height: MaktabSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.saveLesson),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(lessonsRepositoryProvider)
          .update(
            widget.lesson.id,
            LessonUpdateDraft(status: _status, contentNotes: _notes.text, coveredTopicIds: _covered),
          );
      ref.invalidate(lessonProvider(widget.lesson.id));
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.lessonSaved)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      showSaveError(context, error);
    }
  }
}
