import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../lessons/data/lesson_models.dart';
import '../../lessons/presentation/lesson_detail_screen.dart';
import '../data/uniform_models.dart';
import '../data/uniform_repository.dart';
import 'uniform_labels.dart';

/// Uniform for the lesson. Nothing is assumed: only what the teacher taps is recorded.
class UniformRecorder extends ConsumerWidget {
  const UniformRecorder({super.key, required this.lesson, this.readOnly = false});

  final LessonDetail lesson;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(lessonUniformProvider(lesson.id));
    final uniform = saved.value;
    if (uniform != null) {
      return _UniformForm(lesson: lesson, saved: uniform, readOnly: readOnly);
    }
    // Loading and errors stay inside the card, like the other sections.
    return SectionCard(
      title: l10n.uniformSection,
      children: [
        AsyncView(
          value: saved,
          onRetry: () => ref.invalidate(lessonUniformProvider(lesson.id)),
          data: (_) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _UniformForm extends ConsumerStatefulWidget {
  const _UniformForm({required this.lesson, required this.saved, required this.readOnly});

  final LessonDetail lesson;
  final LessonUniform saved;
  final bool readOnly;

  @override
  ConsumerState<_UniformForm> createState() => _UniformFormState();
}

class _UniformFormState extends ConsumerState<_UniformForm> {
  late Map<String, UniformEntry> _entries = _draftFrom(widget.saved);
  bool _saving = false;

  static Map<String, UniformEntry> _draftFrom(LessonUniform saved) => {
    for (final entry in saved.records) entry.studentId: entry,
  };

  @override
  void didUpdateWidget(_UniformForm old) {
    super.didUpdateWidget(old);
    if (!identical(old.saved, widget.saved)) {
      _entries = _draftFrom(widget.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final students = widget.lesson.students.where((s) => s.status != AttendanceStatuses.absent).toList();
    return SectionCard(
      title: l10n.uniformSection,
      action: widget.readOnly || students.isEmpty
          ? null
          : TextButton(onPressed: () => _markAllInOrder(students), child: Text(l10n.uniformAllInOrder)),
      children: [
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(l10n.lessonNoStudents, style: _mutedStyle(context)),
          ),
        for (final student in students)
          _StudentUniformRow(
            student: student,
            entry: _entries[student.studentId],
            readOnly: widget.readOnly,
            onChanged: (entry) => setState(() {
              if (entry == null) {
                _entries.remove(student.studentId);
              } else {
                _entries[student.studentId] = entry;
              }
            }),
          ),
        if (!widget.readOnly && students.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: MaktabSpacing.sm, bottom: MaktabSpacing.sm),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.saveUniform),
            ),
          ),
      ],
    );
  }

  /// Fills in "in order" for everyone not noted yet; what was already noted stays.
  void _markAllInOrder(List<LessonStudent> students) {
    setState(() {
      for (final student in students) {
        _entries.putIfAbsent(
          student.studentId,
          () => UniformEntry(studentId: student.studentId, status: UniformStatuses.inOrder),
        );
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(uniformRepositoryProvider).save(widget.lesson.id, _entries.values.toList());
      ref.invalidate(lessonUniformProvider(widget.lesson.id));
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.uniformSaved)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      showSaveError(context, error);
    }
  }
}

class _StudentUniformRow extends StatelessWidget {
  const _StudentUniformRow({
    required this.student,
    required this.entry,
    required this.readOnly,
    required this.onChanged,
  });

  final LessonStudent student;
  final UniformEntry? entry;
  final bool readOnly;
  final ValueChanged<UniformEntry?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = entry;
    return Padding(
      padding: const EdgeInsets.only(right: MaktabSpacing.sm, bottom: MaktabSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.displayName, style: theme.textTheme.bodyLarge),
          const SizedBox(height: MaktabSpacing.xs),
          if (readOnly)
            Text(
              current == null
                  ? l10n.behaviourNothingNoted
                  : [
                      uniformStatusLabel(current.status, l10n),
                      if (current.reason != null) uniformReasonLabel(current.reason!, l10n),
                    ].join(' · '),
              style: _mutedStyle(context),
            )
          else ...[
            Wrap(
              spacing: MaktabSpacing.xs,
              runSpacing: MaktabSpacing.xs,
              children: [
                for (final status in UniformStatuses.all)
                  ChoiceChip(
                    avatar: Icon(uniformStatusIcon(status), size: 18),
                    label: Text(uniformStatusLabel(status, l10n)),
                    selected: current?.status == status,
                    showCheckmark: false,
                    // Tapping the chosen status again clears it.
                    onSelected: (selected) => onChanged(
                      !selected
                          ? null
                          : current == null
                          ? UniformEntry(studentId: student.studentId, status: status)
                          : current.copyWith(status: status),
                    ),
                  ),
              ],
            ),
            if (current != null && current.status != UniformStatuses.inOrder)
              Padding(
                padding: const EdgeInsets.only(top: MaktabSpacing.sm),
                child: DropdownButtonFormField<String>(
                  initialValue: current.reason,
                  decoration: InputDecoration(labelText: l10n.uniformReason),
                  items: [
                    for (final reason in UniformReasons.all)
                      DropdownMenuItem(value: reason, child: Text(uniformReasonLabel(reason, l10n))),
                  ],
                  onChanged: (reason) => onChanged(current.copyWith(reason: reason)),
                ),
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
