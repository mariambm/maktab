import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/form_validators.dart';
import '../data/parent_models.dart';
import '../data/parents_repository.dart';

final _phonePattern = RegExp(r'^\+?[0-9 ()-]{6,30}$');

/// Add or edit a parent/guardian. Pops with the saved [ParentGuardian], so the student form can link it straight
/// away.
class ParentFormScreen extends ConsumerWidget {
  const ParentFormScreen({super.key, this.parentId, this.suggestedLastName});

  final String? parentId;
  final String? suggestedLastName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = parentId;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.addParentTitle : l10n.editParent)),
      body: id == null
          ? _ParentForm(initial: null, suggestedLastName: suggestedLastName)
          : AsyncView(
              value: ref.watch(parentProvider(id)),
              onRetry: () => ref.invalidate(parentProvider(id)),
              data: (parent) => _ParentForm(initial: parent),
            ),
    );
  }
}

class _ParentForm extends ConsumerStatefulWidget {
  const _ParentForm({required this.initial, this.suggestedLastName});

  final ParentGuardian? initial;
  final String? suggestedLastName;

  @override
  ConsumerState<_ParentForm> createState() => _ParentFormState();
}

class _ParentFormState extends ConsumerState<_ParentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.initial?.firstName);
  late final _lastName = TextEditingController(text: widget.initial?.lastName ?? widget.suggestedLastName);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _email = TextEditingController(text: widget.initial?.email);
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _fieldErrors = const {});
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final draft = ParentDraft(
      firstName: _firstName.text,
      lastName: _lastName.text,
      phone: _phone.text,
      email: _email.text,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(parentsRepositoryProvider);
      final initial = widget.initial;
      final saved = initial == null ? await repository.create(draft) : await repository.update(initial.id, draft);
      ref.invalidate(parentsProvider);
      ref.invalidate(parentProvider(saved.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.parentSaved)));
      navigator.pop(saved);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MaktabSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                  validator: (v) =>
                      FormValidators.required(v?.trim(), l10n.lastNameRequired) ?? _fieldErrors['lastName'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(labelText: l10n.phoneLabel, prefixIcon: const Icon(Icons.phone_outlined)),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) {
                      return l10n.phoneRequired;
                    }
                    return _phonePattern.hasMatch(text) ? _fieldErrors['phone'] : l10n.phoneInvalid;
                  },
                ),
                const SizedBox(height: MaktabSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.emailOptionalLabel,
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                  onFieldSubmitted: (_) => _save(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? _fieldErrors['email']
                      : FormValidators.email(v, l10n) ?? _fieldErrors['email'],
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
        ),
      ),
    );
  }
}
