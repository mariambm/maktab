import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../lessons/data/lesson_models.dart';
import '../../lessons/presentation/lesson_detail_screen.dart';
import '../data/behaviour_models.dart';
import '../data/behaviour_repository.dart';
import 'behaviour_labels.dart';

/// Behaviour noted in this lesson: only for the students worth noting, any number of behaviours each.
class BehaviourRecorder extends ConsumerWidget {
  const BehaviourRecorder({super.key, required this.lesson, this.readOnly = false});

  final LessonDetail lesson;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(lessonBehaviourProvider(lesson.id));
    return SectionCard(
      title: l10n.behaviourSection,
      children: [
        AsyncView(
          value: saved,
          onRetry: () => ref.invalidate(lessonBehaviourProvider(lesson.id)),
          data: (behaviour) => _BehaviourForm(lesson: lesson, saved: behaviour, readOnly: readOnly),
        ),
      ],
    );
  }
}

class _BehaviourForm extends ConsumerStatefulWidget {
  const _BehaviourForm({required this.lesson, required this.saved, required this.readOnly});

  final LessonDetail lesson;
  final LessonBehaviour saved;
  final bool readOnly;

  @override
  ConsumerState<_BehaviourForm> createState() => _BehaviourFormState();
}

class _BehaviourFormState extends ConsumerState<_BehaviourForm> {
  late Map<String, BehaviourObservation> _observations = _draftFrom(widget.saved);
  bool _saving = false;

  static Map<String, BehaviourObservation> _draftFrom(LessonBehaviour saved) => {
    for (final observation in saved.observations) observation.studentId: observation,
  };

  @override
  void didUpdateWidget(_BehaviourForm old) {
    super.didUpdateWidget(old);
    if (!identical(old.saved, widget.saved)) {
      _observations = _draftFrom(widget.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final students = widget.lesson.students.where((s) => s.status != AttendanceStatuses.absent).toList();
    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
        child: Text(l10n.lessonNoStudents, style: _mutedStyle(context)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final student in students)
          _StudentBehaviourTile(
            student: student,
            observation: _observations[student.studentId],
            readOnly: widget.readOnly,
            onEdit: () => _edit(student),
          ),
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.only(top: MaktabSpacing.sm, right: MaktabSpacing.sm, bottom: MaktabSpacing.sm),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.saveBehaviour),
            ),
          ),
      ],
    );
  }

  Future<void> _edit(LessonStudent student) async {
    final result = await showModalBottomSheet<BehaviourObservation>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BehaviourSheet(
        studentName: student.displayName,
        initial:
            _observations[student.studentId] ??
            BehaviourObservation(studentId: student.studentId, behaviours: const []),
      ),
    );
    if (result != null && mounted) {
      setState(() => _observations[student.studentId] = result);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(behaviourRepositoryProvider).save(widget.lesson.id, _observations.values.toList());
      ref.invalidate(lessonBehaviourProvider(widget.lesson.id));
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.behaviourSaved)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      showSaveError(context, error);
    }
  }
}

class _StudentBehaviourTile extends StatelessWidget {
  const _StudentBehaviourTile({
    required this.student,
    required this.observation,
    required this.readOnly,
    required this.onEdit,
  });

  final LessonStudent student;
  final BehaviourObservation? observation;
  final bool readOnly;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = observation;
    final noted = current != null && !current.isEmpty;
    final summary = !noted
        ? l10n.behaviourNothingNoted
        : [
            ...Behaviours.all.where(current.behaviours.contains).map((b) => behaviourLabel(b, l10n)),
            if (current.note != null && current.note!.trim().isNotEmpty) current.note!.trim(),
          ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.only(right: MaktabSpacing.xs),
      title: Text(student.displayName),
      subtitle: Text(summary, style: noted ? null : _mutedStyle(context)),
      trailing: readOnly ? null : Icon(noted ? Icons.edit_outlined : Icons.add_comment_outlined),
      onTap: readOnly ? null : onEdit,
    );
  }
}

/// Pick any number of behaviours for one student, good ones first, with an optional note.
class BehaviourSheet extends StatefulWidget {
  const BehaviourSheet({super.key, required this.studentName, required this.initial});

  final String studentName;
  final BehaviourObservation initial;

  @override
  State<BehaviourSheet> createState() => _BehaviourSheetState();
}

class _BehaviourSheetState extends State<BehaviourSheet> {
  late final Set<String> _selected = {...widget.initial.behaviours};
  late final TextEditingController _note = TextEditingController(text: widget.initial.note ?? '');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.lg),
            child: Text(widget.studentName, style: theme.textTheme.titleLarge),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(MaktabSpacing.lg, MaktabSpacing.md, MaktabSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _group(context, l10n.behaviourGood, Behaviours.good, Icons.thumb_up_outlined),
                  const SizedBox(height: MaktabSpacing.md),
                  _group(context, l10n.behaviourNeedsAttention, Behaviours.needsAttention, Icons.flag_outlined),
                  const SizedBox(height: MaktabSpacing.md),
                  TextField(
                    controller: _note,
                    maxLength: 500,
                    decoration: InputDecoration(labelText: l10n.behaviourNote, counterText: ''),
                  ),
                ],
              ),
            ),
          ),
          // The buttons stay in view however long the list is.
          Padding(
            padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.sm, MaktabSpacing.lg, MaktabSpacing.md),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selected.clear();
                    _note.clear();
                  }),
                  child: Text(l10n.clear),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    BehaviourObservation(
                      studentId: widget.initial.studentId,
                      behaviours: Behaviours.all.where(_selected.contains).toList(),
                      note: _note.text,
                    ),
                  ),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<String> options, IconData icon) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: MaktabSpacing.xs),
            Text(title, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: MaktabSpacing.xs),
        Wrap(
          spacing: MaktabSpacing.xs,
          runSpacing: MaktabSpacing.xs,
          children: [
            for (final behaviour in options)
              FilterChip(
                label: Text(behaviourLabel(behaviour, l10n)),
                selected: _selected.contains(behaviour),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _selected.add(behaviour);
                  } else {
                    _selected.remove(behaviour);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }
}

TextStyle? _mutedStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
}
