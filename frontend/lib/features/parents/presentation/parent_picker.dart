import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/parent_models.dart';
import '../data/parents_repository.dart';
import 'parent_form_screen.dart';

/// Lets the user pick an existing parent/guardian or create a new one without leaving the form they are in.
Future<ParentGuardian?> showParentPicker(BuildContext context, {String? suggestedLastName}) =>
    showModalBottomSheet<ParentGuardian>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          FractionallySizedBox(heightFactor: 0.85, child: _ParentPicker(suggestedLastName: suggestedLastName)),
    );

class _ParentPicker extends ConsumerStatefulWidget {
  const _ParentPicker({this.suggestedLastName});

  final String? suggestedLastName;

  @override
  ConsumerState<_ParentPicker> createState() => _ParentPickerState();
}

class _ParentPickerState extends ConsumerState<_ParentPicker> {
  late String _search = widget.suggestedLastName ?? '';
  late final _controller = TextEditingController(text: _search);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createNew() async {
    final navigator = Navigator.of(context);
    final created = await navigator.push<ParentGuardian>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ParentFormScreen(suggestedLastName: widget.suggestedLastName),
      ),
    );
    if (created != null) {
      navigator.pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parents = ref.watch(parentsProvider(_search));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.md),
          child: Text(l10n.chooseExistingParent, style: Theme.of(context).textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.all(MaktabSpacing.md),
          child: SearchBar(
            controller: _controller,
            hintText: l10n.searchParentsHint,
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        Expanded(
          child: AsyncView(
            value: parents,
            onRetry: () => ref.invalidate(parentsProvider(_search)),
            isEmpty: (page) => page.items.isEmpty,
            empty: MessageView(icon: Icons.person_search_outlined, title: l10n.parentsEmpty),
            data: (page) => ListView(
              children: [
                for (final p in page.items)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(p.displayName),
                    subtitle: Text('${p.phone} · ${l10n.childrenCount(p.children.length)}'),
                    onTap: () => Navigator.of(context).pop(p),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MaktabSpacing.md),
            child: FilledButton.tonalIcon(
              onPressed: _createNew,
              icon: const Icon(Icons.add),
              label: Text(l10n.newParent),
            ),
          ),
        ),
      ],
    );
  }
}
