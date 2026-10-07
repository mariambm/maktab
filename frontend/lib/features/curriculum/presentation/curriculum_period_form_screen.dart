import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/form_validators.dart';
import '../../classes/data/class_models.dart';
import '../../classes/data/classes_repository.dart';
import '../data/curriculum_models.dart';
import '../data/curriculum_repository.dart';

/// Add or edit a four-week period with the topics of each week.
class CurriculumPeriodFormScreen extends ConsumerWidget {
  const CurriculumPeriodFormScreen({super.key, this.periodId});

  final String? periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = periodId;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.addPeriod : l10n.editPeriod)),
      body: id == null
          ? const _PeriodForm(initial: null)
          : AsyncView(
              value: ref.watch(curriculumPeriodProvider(id)),
              onRetry: () => ref.invalidate(curriculumPeriodProvider(id)),
              data: (period) => _PeriodForm(initial: period),
            ),
    );
  }
}

/// A topic being edited; the controllers live as long as the row does.
class _EditableTopic {
  _EditableTopic({String title = '', String objective = ''})
    : title = TextEditingController(text: title),
      objective = TextEditingController(text: objective);

  final TextEditingController title;
  final TextEditingController objective;

  bool get isBlank => title.text.trim().isEmpty && objective.text.trim().isEmpty;

  LessonTopicDraft toDraft() => LessonTopicDraft(title: title.text, learningObjective: objective.text);

  void dispose() {
    title.dispose();
    objective.dispose();
  }
}

class _PeriodForm extends ConsumerStatefulWidget {
  const _PeriodForm({required this.initial});

  final CurriculumPeriod? initial;

  @override
  ConsumerState<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends ConsumerState<_PeriodForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _number = TextEditingController(text: widget.initial?.number.toString() ?? '1');
  late String? _levelId = widget.initial?.curriculumLevelId;
  late DateTime? _startDate = widget.initial?.startDate;
  late final Map<int, List<_EditableTopic>> _topics = _topicsFrom(widget.initial);
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  static Map<int, List<_EditableTopic>> _topicsFrom(CurriculumPeriod? period) {
    final weeks = {for (final week in period?.weeks ?? const <CurriculumWeek>[]) week.weekNumber: week};
    return {
      for (var week = 1; week <= curriculumWeeksPerPeriod; week++)
        week: [
          for (final topic in weeks[week]?.topics ?? const <LessonTopic>[])
            _EditableTopic(title: topic.title, objective: topic.learningObjective ?? ''),
        ],
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    for (final topics in _topics.values) {
      for (final topic in topics) {
        topic.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final levels = ref.watch(curriculumLevelsProvider);
    final today = DateTime.now();
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
                DropdownButtonFormField<String>(
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
                const SizedBox(height: MaktabSpacing.md),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.periodNameLabel),
                  validator: (v) => FormValidators.required(v?.trim(), l10n.nameRequired) ?? _fieldErrors['name'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                TextFormField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.periodNumberLabel),
                  validator: (v) =>
                      (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? l10n.periodNumberRequired : _fieldErrors['number'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                DateField(
                  label: l10n.periodStartLabel,
                  firstDate: DateTime(today.year - 2),
                  lastDate: DateTime(today.year + 2, 12, 31),
                  initialValue: _startDate,
                  onChanged: (date) => _startDate = date,
                  validator: (v) => v == null ? l10n.selectDate : _fieldErrors['startDate'],
                ),
                const SizedBox(height: MaktabSpacing.sm),
                Text(
                  l10n.periodFourWeeks,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                for (var week = 1; week <= curriculumWeeksPerPeriod; week++) ...[
                  const SizedBox(height: MaktabSpacing.sm),
                  _WeekEditor(
                    week: week,
                    topics: _topics[week]!,
                    onAdd: () => setState(() => _topics[week]!.add(_EditableTopic())),
                    onRemove: (topic) => setState(() {
                      _topics[week]!.remove(topic);
                      topic.dispose();
                    }),
                  ),
                ],
                const SizedBox(height: MaktabSpacing.lg),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _fieldErrors = const {});
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(curriculumRepositoryProvider);
    final draft = CurriculumPeriodDraft(
      curriculumLevelId: _levelId!,
      number: int.parse(_number.text.trim()),
      name: _name.text,
      startDate: _startDate!,
      weeks: [
        for (var week = 1; week <= curriculumWeeksPerPeriod; week++)
          CurriculumWeekDraft(
            weekNumber: week,
            review: week == curriculumReviewWeek,
            topics: [for (final topic in _topics[week]!.where((t) => !t.isBlank)) topic.toDraft()],
          ),
      ],
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final initial = widget.initial;
      final saved = initial == null ? await repository.create(draft) : await repository.update(initial.id, draft);
      ref
        ..invalidate(curriculumPeriodsProvider)
        ..invalidate(curriculumPeriodProvider(saved.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.periodSaved)));
      if (!mounted) {
        return;
      }
      if (initial == null) {
        context.pushReplacement('/curriculum/${saved.id}');
      } else {
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? errorMessage(e, l10n) : e.fieldErrors.values.first;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _WeekEditor extends StatelessWidget {
  const _WeekEditor({required this.week, required this.topics, required this.onAdd, required this.onRemove});

  final int week;
  final List<_EditableTopic> topics;
  final VoidCallback onAdd;
  final void Function(_EditableTopic topic) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      title: week == curriculumReviewWeek
          ? '${l10n.curriculumWeekLabel(week)} · ${l10n.curriculumReviewWeek}'
          : l10n.curriculumWeekLabel(week),
      action: IconButton(tooltip: l10n.addTopic, onPressed: onAdd, icon: const Icon(Icons.add)),
      children: [
        for (final topic in topics)
          Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: topic.title,
                        decoration: InputDecoration(labelText: l10n.topicTitleLabel),
                      ),
                      const SizedBox(height: MaktabSpacing.xs),
                      TextFormField(
                        controller: topic.objective,
                        decoration: InputDecoration(labelText: l10n.topicObjectiveLabel),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.removeTopic,
                  onPressed: () => onRemove(topic),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
