import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../classes/data/classes_repository.dart';
import '../data/student_models.dart';
import '../data/students_repository.dart';
import 'student_profile_screen.dart';

/// Moves a student to another class (or places them in one). The old class is closed on the chosen date and kept in
/// the student's history.
Future<void> showMoveClassSheet(BuildContext context, StudentDetail student) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MoveClassSheet(student: student),
);

class _MoveClassSheet extends ConsumerStatefulWidget {
  const _MoveClassSheet({required this.student});

  final StudentDetail student;

  @override
  ConsumerState<_MoveClassSheet> createState() => _MoveClassSheetState();
}

class _MoveClassSheetState extends ConsumerState<_MoveClassSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _classId;
  DateTime _date = dateOnly(DateTime.now());
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};
  String? _error;

  Future<void> _save() async {
    setState(() => _fieldErrors = const {});
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final enrollment = await ref.read(studentsRepositoryProvider).moveToClass(widget.student.id, _classId!, _date);
      refreshStudent(ref, widget.student.id);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.movedToClass(enrollment.classGroup.name))));
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
    final classes = ref.watch(classesProvider).value ?? const [];
    final options = classes.where((c) => c.active && c.id != widget.student.currentClass?.id).toList();
    final today = dateOnly(DateTime.now());
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MaktabSpacing.lg,
        0,
        MaktabSpacing.lg,
        MaktabSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.student.currentClass == null ? l10n.placeInClass : l10n.moveToClass,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MaktabSpacing.md),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: MaktabSpacing.sm),
            ],
            DropdownButtonFormField<String>(
              initialValue: _classId,
              decoration: InputDecoration(labelText: l10n.chooseClass),
              items: [for (final c in options) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (id) => setState(() => _classId = id),
              validator: (v) => v == null ? l10n.chooseClass : _fieldErrors['classId'],
            ),
            const SizedBox(height: MaktabSpacing.md),
            DateField(
              label: l10n.moveDateLabel,
              initialValue: _date,
              firstDate: widget.student.joinedOn,
              lastDate: today,
              onChanged: (d) => _date = d,
              validator: (_) => _fieldErrors['startDate'],
            ),
            const SizedBox(height: MaktabSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
