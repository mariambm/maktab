import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/form_validators.dart';
import '../data/class_models.dart';
import '../data/classes_repository.dart';

/// Add or edit a class, including its teachers and weekly schedule, in one form.
class ClassFormScreen extends ConsumerWidget {
  const ClassFormScreen({super.key, this.classId});

  final String? classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = classId;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.addClass : l10n.editClass)),
      body: id == null
          ? const _ClassForm(initial: null)
          : AsyncView(
              value: ref.watch(classProvider(id)),
              onRetry: () => ref.invalidate(classProvider(id)),
              data: (c) => _ClassForm(initial: c),
            ),
    );
  }
}

class _EditableSlot {
  _EditableSlot(this.weekday, this.start, this.end);

  factory _EditableSlot.from(ScheduleSlot slot) =>
      _EditableSlot(slot.weekday, _parseTime(slot.startTime), _parseTime(slot.endTime));

  String weekday;
  TimeOfDay start;
  TimeOfDay end;

  bool get isValid => end.hour * 60 + end.minute > start.hour * 60 + start.minute;

  ScheduleSlot toSlot() => ScheduleSlot(weekday: weekday, startTime: _formatTime(start), endTime: _formatTime(end));

  static TimeOfDay _parseTime(String text) {
    final parts = text.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _ClassForm extends ConsumerStatefulWidget {
  const _ClassForm({required this.initial});

  final ClassSummary? initial;

  @override
  ConsumerState<_ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends ConsumerState<_ClassForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _room = TextEditingController(text: widget.initial?.room);
  late String? _levelId = widget.initial?.curriculumLevel.id;
  late bool _active = widget.initial?.active ?? true;
  late final Set<String> _teacherIds = {...?widget.initial?.teachers.map((t) => t.id)};
  late final List<_EditableSlot> _slots = [...?widget.initial?.schedule.map(_EditableSlot.from)];
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _addLevel() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newLevel),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.levelNameLabel),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.add)),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }
    try {
      final level = await ref.read(classesRepositoryProvider).createLevel(name);
      ref.invalidate(curriculumLevelsProvider);
      setState(() => _levelId = level.id);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e, l10n))));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _fieldErrors = const {});
    final slotsValid = _slots.every((s) => s.isValid);
    if (_saving || !_formKey.currentState!.validate() || !slotsValid) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(classesRepositoryProvider);
    final draft = ClassDraft(name: _name.text, curriculumLevelId: _levelId!, room: _room.text, active: _active);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final initial = widget.initial;
      final saved = initial == null ? await repository.create(draft) : await repository.update(initial.id, draft);
      final teachersChanged = initial == null
          ? _teacherIds.isNotEmpty
          : !_sameSet(_teacherIds, initial.teachers.map((t) => t.id).toSet());
      if (teachersChanged) {
        await repository.replaceTeachers(saved.id, _teacherIds);
      }
      await repository.replaceSchedule(saved.id, _slots.map((s) => s.toSlot()).toList());
      ref
        ..invalidate(classesProvider)
        ..invalidate(classProvider(saved.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.classSaved)));
      if (initial == null) {
        if (mounted) context.pushReplacement('/classes/${saved.id}');
      } else {
        if (mounted) context.pop();
      }
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty
            ? errorMessage(e, l10n)
            : e.fieldErrors['teacherIds'] ?? e.fieldErrors['slots'] ?? e.fieldErrors['active'];
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) => showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final levels = ref.watch(curriculumLevelsProvider);
    final teachers = ref.watch(teacherOptionsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MaktabSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  const SizedBox(height: MaktabSpacing.md),
                ],
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.classNameLabel),
                  validator: (v) => FormValidators.required(v?.trim(), l10n.nameRequired) ?? _fieldErrors['name'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_levelId),
                        initialValue: _levelId,
                        decoration: InputDecoration(labelText: l10n.levelLabel),
                        items: [
                          for (final level in levels.value ?? const <CurriculumLevel>[])
                            DropdownMenuItem(value: level.id, child: Text(level.name)),
                        ],
                        onChanged: (id) => setState(() => _levelId = id),
                        validator: (v) => v == null ? l10n.levelRequired : _fieldErrors['curriculumLevelId'],
                      ),
                    ),
                    const SizedBox(width: MaktabSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: MaktabSpacing.xs),
                      child: IconButton.filledTonal(
                        tooltip: l10n.newLevel,
                        onPressed: _addLevel,
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MaktabSpacing.md),
                TextFormField(
                  controller: _room,
                  decoration: InputDecoration(labelText: '${l10n.roomLabel} (${l10n.optional.toLowerCase()})'),
                  validator: (_) => _fieldErrors['room'],
                ),
                if (widget.initial != null) ...[
                  const SizedBox(height: MaktabSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.classActiveLabel),
                    subtitle: Text(l10n.classInactiveHint),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ],
                const SizedBox(height: MaktabSpacing.lg),
                Text(l10n.teachersSection, style: theme.textTheme.titleMedium),
                const SizedBox(height: MaktabSpacing.sm),
                AsyncView(
                  value: teachers,
                  onRetry: () => ref.invalidate(teacherOptionsProvider),
                  isEmpty: (list) => list.isEmpty,
                  empty: Text(l10n.noTeachers),
                  data: (list) => Wrap(
                    spacing: MaktabSpacing.sm,
                    runSpacing: MaktabSpacing.sm,
                    children: [
                      for (final t in list)
                        FilterChip(
                          label: Text(t.displayName),
                          selected: _teacherIds.contains(t.id),
                          onSelected: (selected) =>
                              setState(() => selected ? _teacherIds.add(t.id) : _teacherIds.remove(t.id)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: MaktabSpacing.lg),
                Text(l10n.scheduleSection, style: theme.textTheme.titleMedium),
                const SizedBox(height: MaktabSpacing.sm),
                for (final slot in _slots) _slotRow(slot, l10n, theme),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _slots.length >= 14
                        ? null
                        : () => setState(
                            () => _slots.add(
                              _EditableSlot(
                                'SATURDAY',
                                const TimeOfDay(hour: 10, minute: 0),
                                const TimeOfDay(hour: 12, minute: 0),
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addSlot),
                  ),
                ),
                const SizedBox(height: MaktabSpacing.lg),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.initial == null ? l10n.addClass : l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotRow(_EditableSlot slot, AppLocalizations l10n, ThemeData theme) {
    String time(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(MaktabSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: slot.weekday,
                    decoration: const InputDecoration(isDense: true),
                    items: [
                      for (final day in weekdays) DropdownMenuItem(value: day, child: Text(weekdayLabel(day, l10n))),
                    ],
                    onChanged: (day) => setState(() => slot.weekday = day!),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await _pickTime(slot.start);
                    if (picked != null) {
                      setState(() => slot.start = picked);
                    }
                  },
                  child: Text('${l10n.startTimeLabel} ${time(slot.start)}'),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await _pickTime(slot.end);
                    if (picked != null) {
                      setState(() => slot.end = picked);
                    }
                  },
                  child: Text('${l10n.endTimeLabel} ${time(slot.end)}'),
                ),
                IconButton(
                  tooltip: l10n.remove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _slots.remove(slot)),
                ),
              ],
            ),
            if (!slot.isValid) Text(l10n.endAfterStart, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
    );
  }
}
