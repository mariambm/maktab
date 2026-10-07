import 'package:flutter/material.dart';

import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../parents/presentation/parent_picker.dart';
import '../data/student_models.dart';

/// A parent linked in a form, with the name kept for display.
class EditableParentLink {
  EditableParentLink({required this.parentId, required this.name, required this.relationship, this.primary = false});

  final String parentId;
  final String name;
  String relationship;
  bool primary;

  ParentLink toLink() => ParentLink(parentId: parentId, relationship: relationship, primaryContact: primary);
}

/// Lists linked parents with relationship and primary-contact controls, plus a button to add one (existing or new).
class ParentLinkEditor extends StatelessWidget {
  const ParentLinkEditor({super.key, required this.links, required this.onChanged, this.suggestedLastName});

  final List<EditableParentLink> links;
  final VoidCallback onChanged;

  /// Pre-fills the family name when creating a new parent from the student form.
  final String? suggestedLastName;

  Future<void> _add(BuildContext context) async {
    final picked = await showParentPicker(context, suggestedLastName: suggestedLastName);
    if (picked == null || links.any((l) => l.parentId == picked.id)) {
      return;
    }
    links.add(
      EditableParentLink(
        parentId: picked.id,
        name: picked.displayName,
        relationship: parentRelationships.first,
        primary: links.isEmpty,
      ),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final link in links)
          Card(
            margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(MaktabSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: MaktabSpacing.sm),
                      Expanded(child: Text(link.name, style: Theme.of(context).textTheme.titleSmall)),
                      IconButton(
                        tooltip: l10n.remove,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          links.remove(link);
                          if (link.primary && links.isNotEmpty) {
                            links.first.primary = true;
                          }
                          onChanged();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: link.relationship,
                          decoration: InputDecoration(labelText: l10n.relationshipLabel, isDense: true),
                          items: [
                            for (final r in parentRelationships)
                              DropdownMenuItem(value: r, child: Text(relationshipLabel(r, l10n))),
                          ],
                          onChanged: (r) {
                            link.relationship = r!;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: MaktabSpacing.sm),
                      FilterChip(
                        label: Text(l10n.primaryContact),
                        selected: link.primary,
                        onSelected: (_) {
                          for (final other in links) {
                            other.primary = identical(other, link);
                          }
                          onChanged();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: links.length >= 4 ? null : () => _add(context),
          icon: const Icon(Icons.person_add_alt),
          label: Text(l10n.addParentLink),
        ),
      ],
    );
  }
}
