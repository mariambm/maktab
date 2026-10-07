import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../parents/data/parents_repository.dart';
import '../data/student_models.dart';
import '../data/students_repository.dart';
import 'parent_link_editor.dart';
import 'student_profile_screen.dart';

Future<void> showManageParentsSheet(BuildContext context, StudentDetail student) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ManageParentsSheet(student: student),
);

class _ManageParentsSheet extends ConsumerStatefulWidget {
  const _ManageParentsSheet({required this.student});

  final StudentDetail student;

  @override
  ConsumerState<_ManageParentsSheet> createState() => _ManageParentsSheetState();
}

class _ManageParentsSheetState extends ConsumerState<_ManageParentsSheet> {
  late final List<EditableParentLink> _links = [
    for (final p in widget.student.parents)
      EditableParentLink(
        parentId: p.parentId,
        name: p.displayName,
        relationship: p.relationship,
        primary: p.primaryContact,
      ),
  ];
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(studentsRepositoryProvider)
          .replaceParents(widget.student.id, _links.map((l) => l.toLink()).toList());
      refreshStudent(ref, widget.student.id);
      ref.invalidate(parentsProvider);
      ref.invalidate(parentProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.studentSaved)));
    } on ApiException catch (e) {
      setState(() => _error = e.fieldErrors['parents'] ?? errorMessage(e, l10n));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(MaktabSpacing.lg, 0, MaktabSpacing.lg, MaktabSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.parentsSection, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: MaktabSpacing.md),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: MaktabSpacing.sm),
            ],
            ParentLinkEditor(
              links: _links,
              suggestedLastName: widget.student.lastName,
              onChanged: () => setState(() {}),
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
