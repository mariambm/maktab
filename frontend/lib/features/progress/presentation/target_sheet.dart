import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../curriculum/data/curriculum_models.dart';
import '../../curriculum/presentation/subject_labels.dart';
import '../data/progress_models.dart';
import '../data/progress_repository.dart';
import '../data/target_models.dart';

/// Opens the target form. Pass [existing] to edit; to add, pass the student and the periods to choose from.
Future<StudentTarget?> showTargetSheet(
  BuildContext context, {
  StudentTarget? existing,
  String? studentId,
  List<CurriculumPeriodSummary> periods = const [],
  String? initialPeriodId,
}) => showModalBottomSheet<StudentTarget>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      TargetSheet(existing: existing, studentId: studentId, periods: periods, initialPeriodId: initialPeriodId),
);

class TargetSheet extends ConsumerStatefulWidget {
  const TargetSheet({super.key, this.existing, this.studentId, this.periods = const [], this.initialPeriodId});

  final StudentTarget? existing;
  final String? studentId;
  final List<CurriculumPeriodSummary> periods;
  final String? initialPeriodId;

  @override
  ConsumerState<TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends ConsumerState<TargetSheet> {
  final _formKey = GlobalKey<FormState>();
  late String? _periodId = widget.existing?.period.id ?? widget.initialPeriodId ?? widget.periods.firstOrNull?.id;
  late String? _subject = widget.existing?.subject;
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _target = TextEditingController(text: widget.existing?.targetPercentage?.toString());
  late final _current = TextEditingController(text: widget.existing?.currentPercentage?.toString());
  late double? _score = widget.existing?.progressScore;
  late final _note = TextEditingController(text: widget.existing?.teacherNote);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _target.dispose();
    _current.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final existing = widget.existing;
    final scale = ref.watch(progressScaleProvider).value ?? const <ProgressScaleLevel>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.lg),
              child: Text(existing == null ? l10n.addTarget : l10n.editTarget, style: theme.textTheme.titleLarge),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(MaktabSpacing.lg, MaktabSpacing.md, MaktabSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: MaktabSpacing.sm),
                    ],
                    if (existing == null)
                      DropdownButtonFormField<String>(
                        initialValue: _periodId,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l10n.targetPeriod),
                        items: [
                          for (final period in widget.periods)
                            DropdownMenuItem(value: period.id, child: Text(_periodLabel(period, l10n))),
                        ],
                        onChanged: (id) => setState(() => _periodId = id),
                        validator: (v) => v == null ? l10n.targetPeriod : null,
                      )
                    else
                      InputDecorator(
                        decoration: InputDecoration(labelText: l10n.targetPeriod),
                        child: Text(_periodLabel(existing.period, l10n)),
                      ),
                    const SizedBox(height: MaktabSpacing.md),
                    DropdownButtonFormField<String?>(
                      initialValue: _subject,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.targetSubjectOptional),
                      items: [
                        DropdownMenuItem(child: Text(l10n.targetAnySubject)),
                        for (final subject in Subjects.all)
                          DropdownMenuItem(value: subject, child: Text(subjectLabel(subject, l10n))),
                      ],
                      onChanged: (subject) => setState(() => _subject = subject),
                    ),
                    const SizedBox(height: MaktabSpacing.md),
                    TextFormField(
                      key: const Key('target.description'),
                      controller: _description,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.targetDescription,
                        hintText: l10n.targetDescriptionHint,
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? l10n.targetDescriptionRequired : null,
                    ),
                    const SizedBox(height: MaktabSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _percentField(const Key('target.target'), _target, l10n.targetPercentage, l10n),
                        ),
                        const SizedBox(width: MaktabSpacing.md),
                        Expanded(
                          child: _percentField(const Key('target.current'), _current, l10n.currentPercentage, l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: MaktabSpacing.md),
                    Text(l10n.targetScore, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: MaktabSpacing.xs),
                    Wrap(
                      spacing: MaktabSpacing.xs,
                      runSpacing: MaktabSpacing.xs,
                      children: [
                        for (final level in scale)
                          ChoiceChip(
                            label: Text(formatScore(level.score)),
                            tooltip: level.label,
                            selected: level.score == _score,
                            showCheckmark: false,
                            onSelected: (selected) => setState(() => _score = selected ? level.score : null),
                          ),
                      ],
                    ),
                    if (_score != null)
                      Padding(
                        padding: const EdgeInsets.only(top: MaktabSpacing.xs),
                        child: Text(
                          scale.where((l) => l.score == _score).firstOrNull?.label ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: MaktabSpacing.md),
                    TextField(
                      controller: _note,
                      maxLength: 1000,
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l10n.teacherNote, counterText: ''),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MaktabSpacing.lg,
                MaktabSpacing.sm,
                MaktabSpacing.lg,
                MaktabSpacing.md,
              ),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _percentField(Key key, TextEditingController controller, String label, AppLocalizations l10n) => TextFormField(
    key: key,
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, suffixText: '%'),
    validator: (v) {
      final text = (v ?? '').trim();
      if (text.isEmpty) {
        return null;
      }
      final value = int.tryParse(text);
      return value == null || value < 0 || value > 100 ? l10n.percentageInvalid : null;
    },
  );

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final existing = widget.existing;
    final draft = TargetDraft(
      studentId: existing == null ? widget.studentId : null,
      curriculumPeriodId: existing == null ? _periodId : null,
      subject: _subject,
      description: _description.text,
      targetPercentage: int.tryParse(_target.text.trim()),
      currentPercentage: int.tryParse(_current.text.trim()),
      progressScore: _score,
      teacherNote: _note.text,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(progressRepositoryProvider);
      final saved = existing == null
          ? await repository.createTarget(draft)
          : await repository.updateTarget(existing.id, draft);
      ref.invalidate(studentTargetsProvider(saved.studentId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.targetSaved)));
      navigator.pop(saved);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.fieldErrors.isEmpty ? errorMessage(e, l10n) : e.fieldErrors.values.first;
        });
      }
    }
  }
}

String _periodLabel(CurriculumPeriodSummary period, AppLocalizations l10n) =>
    l10n.progressPeriodOf(period.name, formatDate(period.startDate), formatDate(period.endDate));
