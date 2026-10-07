import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/lesson_models.dart';
import '../data/lessons_repository.dart';
import 'lesson_detail_screen.dart';
import 'lesson_labels.dart';

/// Minutes a teacher can pick from; a short list keeps the register to a few taps.
const _minuteOptions = [5, 10, 15, 20, 30, 45, 60];

/// The whole class in one list, everyone present until the teacher says otherwise, saved in one request.
class AttendanceRegister extends ConsumerStatefulWidget {
  const AttendanceRegister({super.key, required this.lesson, this.readOnly = false});

  final LessonDetail lesson;
  final bool readOnly;

  @override
  ConsumerState<AttendanceRegister> createState() => _AttendanceRegisterState();
}

class _AttendanceRegisterState extends ConsumerState<AttendanceRegister> {
  late Map<String, AttendanceEntry> _entries;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entries = _draftFrom(widget.lesson);
  }

  @override
  void didUpdateWidget(AttendanceRegister old) {
    super.didUpdateWidget(old);
    if (old.lesson.id != widget.lesson.id) {
      _entries = _draftFrom(widget.lesson);
    }
  }

  /// Students already recorded keep what was recorded; the rest start as present, so only exceptions need a tap.
  static Map<String, AttendanceEntry> _draftFrom(LessonDetail lesson) => {
    for (final student in lesson.students)
      student.studentId: AttendanceEntry(
        studentId: student.studentId,
        status: student.status ?? AttendanceStatuses.present,
        minutesLate: student.minutesLate,
        absenceReason: student.absenceReason,
        note: student.note,
      ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final students = widget.lesson.students;
    return SectionCard(
      title: l10n.attendanceSection,
      action: widget.readOnly || students.isEmpty
          ? null
          : TextButton(onPressed: _markAllPresent, child: Text(l10n.markAllPresent)),
      children: [
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(l10n.lessonNoStudents, style: _mutedStyle(context)),
          ),
        for (final student in students)
          _StudentRow(
            student: student,
            entry: _entries[student.studentId]!,
            readOnly: widget.readOnly,
            onChanged: (entry) => setState(() => _entries[student.studentId] = entry),
          ),
        if (!widget.readOnly && students.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: MaktabSpacing.sm, bottom: MaktabSpacing.sm),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.saveAttendance),
            ),
          ),
      ],
    );
  }

  void _markAllPresent() {
    setState(() {
      _entries = {
        for (final student in widget.lesson.students)
          student.studentId: AttendanceEntry(studentId: student.studentId, status: AttendanceStatuses.present),
      };
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(lessonsRepositoryProvider).saveAttendance(widget.lesson.id, _entries.values.toList());
      ref.invalidate(lessonProvider(widget.lesson.id));
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.attendanceSaved)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      showSaveError(context, error);
    }
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.entry, required this.readOnly, required this.onChanged});

  final LessonStudent student;
  final AttendanceEntry entry;
  final bool readOnly;
  final ValueChanged<AttendanceEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.displayName, style: theme.textTheme.bodyLarge),
          const SizedBox(height: MaktabSpacing.xs),
          if (readOnly)
            Text(_readOnlySummary(l10n), style: _mutedStyle(context))
          else
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final status in AttendanceStatuses.all)
                  ButtonSegment(
                    value: status,
                    icon: Icon(attendanceIcon(status), size: 18),
                    label: Text(attendanceLabel(status, l10n)),
                  ),
              ],
              selected: {entry.status},
              onSelectionChanged: (selection) => onChanged(_withStatus(entry, selection.first)),
            ),
          if (!readOnly && entry.status == AttendanceStatuses.late) _MinutesField(entry: entry, onChanged: onChanged),
          if (!readOnly && entry.status == AttendanceStatuses.absent) _ReasonField(entry: entry, onChanged: onChanged),
          if (!readOnly && entry.status != AttendanceStatuses.present) _NoteField(entry: entry, onChanged: onChanged),
          const Divider(height: MaktabSpacing.md),
        ],
      ),
    );
  }

  String _readOnlySummary(AppLocalizations l10n) {
    final status = student.status;
    if (status == null) {
      return l10n.lessonNotOpened;
    }
    return [
      attendanceLabel(status, l10n),
      if (student.minutesLate != null) l10n.minutesLateShort(student.minutesLate!),
      if (student.absenceReason != null) absenceReasonLabel(student.absenceReason!, l10n),
      ?student.note,
    ].join(' · ');
  }
}

/// Switching status fills in what that status needs, so a saved row is always complete.
AttendanceEntry _withStatus(AttendanceEntry entry, String status) => entry.copyWith(
  status: status,
  minutesLate: status == AttendanceStatuses.late ? (entry.minutesLate ?? _minuteOptions.first) : null,
  absenceReason: status == AttendanceStatuses.absent ? (entry.absenceReason ?? AbsenceReasons.unknown) : null,
);

class _MinutesField extends StatelessWidget {
  const _MinutesField({required this.entry, required this.onChanged});

  final AttendanceEntry entry;
  final ValueChanged<AttendanceEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = entry.minutesLate ?? _minuteOptions.first;
    return Padding(
      padding: const EdgeInsets.only(top: MaktabSpacing.sm),
      child: DropdownButtonFormField<int>(
        initialValue: _minuteOptions.contains(minutes) ? minutes : _minuteOptions.first,
        decoration: InputDecoration(labelText: l10n.minutesLate),
        items: [
          for (final option in _minuteOptions)
            DropdownMenuItem(value: option, child: Text(l10n.minutesLateShort(option))),
        ],
        onChanged: (value) => onChanged(entry.copyWith(minutesLate: value)),
      ),
    );
  }
}

class _ReasonField extends StatelessWidget {
  const _ReasonField({required this.entry, required this.onChanged});

  final AttendanceEntry entry;
  final ValueChanged<AttendanceEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: MaktabSpacing.sm),
      child: DropdownButtonFormField<String>(
        initialValue: entry.absenceReason ?? AbsenceReasons.unknown,
        decoration: InputDecoration(labelText: l10n.absenceReason),
        items: [
          for (final reason in AbsenceReasons.all)
            DropdownMenuItem(value: reason, child: Text(absenceReasonLabel(reason, l10n))),
        ],
        onChanged: (value) => onChanged(entry.copyWith(absenceReason: value)),
      ),
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({required this.entry, required this.onChanged});

  final AttendanceEntry entry;
  final ValueChanged<AttendanceEntry> onChanged;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _controller = TextEditingController(text: widget.entry.note ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: MaktabSpacing.sm),
      child: TextField(
        controller: _controller,
        maxLength: 500,
        decoration: InputDecoration(labelText: l10n.attendanceNote, counterText: ''),
        onChanged: (value) => widget.onChanged(widget.entry.copyWith(note: value)),
      ),
    );
  }
}

TextStyle? _mutedStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
}
