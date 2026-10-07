import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/form_validators.dart';
import '../../classes/data/class_models.dart';
import '../../classes/data/classes_repository.dart';
import '../../parents/data/parents_repository.dart';
import '../data/student_models.dart';
import '../data/students_repository.dart';
import 'parent_link_editor.dart';
import 'student_profile_screen.dart';

/// Add Student (with class and parents in the same form) and Edit student (personal details only; class and parents
/// are changed from the profile).
class StudentFormScreen extends ConsumerWidget {
  const StudentFormScreen({super.key, this.studentId});

  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = studentId;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.addStudent : l10n.editStudent)),
      body: id == null
          ? const _StudentForm(initial: null)
          : AsyncView(
              value: ref.watch(studentProvider(id)),
              onRetry: () => ref.invalidate(studentProvider(id)),
              data: (student) => _StudentForm(initial: student),
            ),
    );
  }
}

class _StudentForm extends ConsumerStatefulWidget {
  const _StudentForm({required this.initial});

  final StudentDetail? initial;

  @override
  ConsumerState<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends ConsumerState<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.initial?.firstName);
  late final _lastName = TextEditingController(text: widget.initial?.lastName);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late DateTime? _dateOfBirth = widget.initial?.dateOfBirth;
  late DateTime _joinedOn = widget.initial?.joinedOn ?? dateOnly(DateTime.now());
  late String? _gender = widget.initial?.gender;
  String? _classId;
  final List<EditableParentLink> _parents = [];
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  bool get _creating => widget.initial == null;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _fieldErrors = const {});
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final draft = StudentDraft(
      firstName: _firstName.text,
      lastName: _lastName.text,
      dateOfBirth: _dateOfBirth!,
      gender: _gender,
      joinedOn: _joinedOn,
      notes: _notes.text,
      classId: _classId,
      parents: _parents.map((p) => p.toLink()).toList(),
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(studentsRepositoryProvider);
      final initial = widget.initial;
      if (initial == null) {
        final created = await repository.create(draft);
        ref.invalidate(parentsProvider);
        refreshStudent(ref, created.id);
        messenger.showSnackBar(SnackBar(content: Text(l10n.studentCreated)));
        if (mounted) context.pushReplacement('/students/${created.id}');
      } else {
        await repository.update(initial.id, draft);
        refreshStudent(ref, initial.id);
        messenger.showSnackBar(SnackBar(content: Text(l10n.studentSaved)));
        if (mounted) context.pop();
      }
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? errorMessage(e, l10n) : null;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());
    final classes = _creating ? (ref.watch(classesProvider).value ?? const <ClassSummary>[]) : const <ClassSummary>[];
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
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.firstNameLabel),
                  validator: (v) =>
                      FormValidators.required(v?.trim(), l10n.firstNameRequired) ?? _fieldErrors['firstName'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.lastNameLabel),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      FormValidators.required(v?.trim(), l10n.lastNameRequired) ?? _fieldErrors['lastName'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                DateField(
                  label: l10n.dateOfBirthLabel,
                  initialValue: _dateOfBirth,
                  firstDate: DateTime(today.year - 25),
                  lastDate: today.subtract(const Duration(days: 1)),
                  initialPickerMode: DatePickerMode.year,
                  onChanged: (d) => _dateOfBirth = d,
                  validator: (v) => v == null ? l10n.dateOfBirthRequired : _fieldErrors['dateOfBirth'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                Text(l10n.genderLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: MaktabSpacing.xs),
                SegmentedButton<String?>(
                  segments: [
                    ButtonSegment(value: Genders.female, label: Text(l10n.genderFemale)),
                    ButtonSegment(value: Genders.male, label: Text(l10n.genderMale)),
                    ButtonSegment(value: null, label: Text(l10n.genderNotRecorded)),
                  ],
                  selected: {_gender},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _gender = s.first),
                ),
                const SizedBox(height: MaktabSpacing.md),
                DateField(
                  label: l10n.joinedOnLabel,
                  initialValue: _joinedOn,
                  firstDate: DateTime(today.year - 20),
                  lastDate: DateTime(today.year + 1, 12, 31),
                  onChanged: (d) => _joinedOn = d,
                  validator: (_) => _fieldErrors['joinedOn'],
                ),
                if (_creating) ...[
                  const SizedBox(height: MaktabSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: _classId,
                    decoration: InputDecoration(labelText: l10n.classOptionalLabel),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.noClassOption)),
                      for (final c in classes.where((c) => c.active))
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (id) => setState(() => _classId = id),
                    validator: (_) => _fieldErrors['classId'],
                  ),
                  const SizedBox(height: MaktabSpacing.lg),
                  Text(l10n.parentsSection, style: theme.textTheme.titleMedium),
                  const SizedBox(height: MaktabSpacing.sm),
                  if (_fieldErrors['parents'] != null) ...[
                    Text(_fieldErrors['parents']!, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: MaktabSpacing.sm),
                  ],
                  ParentLinkEditor(
                    links: _parents,
                    suggestedLastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
                    onChanged: () => setState(() {}),
                  ),
                ],
                const SizedBox(height: MaktabSpacing.lg),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: '${l10n.notesLabel} (${l10n.optional.toLowerCase()})',
                    hintText: l10n.notesHint,
                    alignLabelWithHint: true,
                  ),
                  validator: (_) => _fieldErrors['notes'],
                ),
                const SizedBox(height: MaktabSpacing.lg),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_creating ? l10n.addStudent : l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
