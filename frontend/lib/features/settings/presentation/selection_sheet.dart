import 'package:flutter/material.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A bottom sheet of checkboxes that saves the chosen set through [onSave]. Options in [locked] are shown ticked
/// and cannot be changed (for example permissions a role already gives). Pops with true once saved.
Future<bool?> showSelectionSheet(
  BuildContext context, {
  required String title,
  String? hint,
  required List<String> options,
  required String Function(String) labelOf,
  required Set<String> selected,
  Set<String> locked = const {},
  String? requiredMessage,
  required Future<void> Function(Set<String>) onSave,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _SelectionSheet(
    title: title,
    hint: hint,
    options: options,
    labelOf: labelOf,
    selected: selected,
    locked: locked,
    requiredMessage: requiredMessage,
    onSave: onSave,
  ),
);

class _SelectionSheet extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.hint,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.locked,
    required this.requiredMessage,
    required this.onSave,
  });

  final String title;
  final String? hint;
  final List<String> options;
  final String Function(String) labelOf;
  final Set<String> selected;
  final Set<String> locked;
  final String? requiredMessage;
  final Future<void> Function(Set<String>) onSave;

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  late final Set<String> _chosen = {...widget.selected};
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final required = widget.requiredMessage;
    if (required != null && _chosen.isEmpty) {
      setState(() => _error = required);
      return;
    }
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_chosen);
      navigator.pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.fieldErrors.values.firstOrNull ?? errorMessage(e, l10n));
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(MaktabSpacing.lg, 0, MaktabSpacing.lg, MaktabSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            if (widget.hint != null) ...[
              const SizedBox(height: MaktabSpacing.xs),
              Text(widget.hint!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: MaktabSpacing.sm),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            for (final option in widget.options)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(widget.labelOf(option)),
                value: widget.locked.contains(option) || _chosen.contains(option),
                onChanged: widget.locked.contains(option) || _saving
                    ? null
                    : (checked) => setState(() => checked! ? _chosen.add(option) : _chosen.remove(option)),
              ),
            const SizedBox(height: MaktabSpacing.md),
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
