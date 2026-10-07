import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/routing/redirect.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/form_validators.dart';
import '../data/user_summary.dart';
import '../data/users_repository.dart';
import 'role_label.dart';
import 'temporary_password_dialog.dart';

/// Add an account (name, email, roles) or edit an existing one's name and email. Roles of an existing account are
/// changed on its detail screen.
class UserFormScreen extends ConsumerWidget {
  const UserFormScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = userId;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.addUser : l10n.editUser)),
      body: id == null
          ? const _UserForm(initial: null)
          : AsyncView(
              value: ref.watch(userProvider(id)),
              onRetry: () => ref.invalidate(userProvider(id)),
              data: (user) => _UserForm(initial: user),
            ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({required this.initial});

  final UserSummary? initial;

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.initial?.firstName);
  late final _lastName = TextEditingController(text: widget.initial?.lastName);
  late final _email = TextEditingController(text: widget.initial?.email);
  final Set<String> _roles = {Roles.teacher};
  bool _saving = false;
  String? _error;
  String? _rolesError;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final initial = widget.initial;
    setState(() {
      _fieldErrors = const {};
      _rolesError = initial == null && _roles.isEmpty ? l10n.rolesRequired : null;
    });
    if (_saving || !_formKey.currentState!.validate() || _rolesError != null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final draft = UserDraft(firstName: _firstName.text, lastName: _lastName.text, email: _email.text);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(usersRepositoryProvider);
      if (initial == null) {
        final created = await repository.create(draft, _roles);
        ref.invalidate(usersProvider);
        if (!mounted) {
          return;
        }
        setState(() => _saving = false);
        await showTemporaryPasswordDialog(context, name: created.user.firstName, password: created.temporaryPassword);
        if (mounted) {
          final router = GoRouter.maybeOf(context);
          router == null ? Navigator.of(context).pop() : router.pushReplacement('${Routes.users}/${created.user.id}');
        }
      } else {
        await repository.update(initial.id, draft);
        ref.invalidate(usersProvider);
        ref.invalidate(userProvider(initial.id));
        messenger.showSnackBar(SnackBar(content: Text(l10n.userSaved)));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.fieldErrors;
        _rolesError = e.fieldErrors['roles'];
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
                  validator: (v) =>
                      FormValidators.required(v?.trim(), l10n.lastNameRequired) ?? _fieldErrors['lastName'],
                ),
                const SizedBox(height: MaktabSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l10n.emailLabel, prefixIcon: const Icon(Icons.mail_outline)),
                  validator: (v) => FormValidators.email(v, l10n) ?? _fieldErrors['email'],
                ),
                if (widget.initial == null) ...[
                  const SizedBox(height: MaktabSpacing.lg),
                  Text(l10n.rolesSection, style: theme.textTheme.titleSmall),
                  const SizedBox(height: MaktabSpacing.sm),
                  Wrap(
                    spacing: MaktabSpacing.sm,
                    children: [
                      for (final role in allRoles)
                        FilterChip(
                          label: Text(roleLabel(role, l10n)),
                          selected: _roles.contains(role),
                          onSelected: (on) => setState(() => on ? _roles.add(role) : _roles.remove(role)),
                        ),
                    ],
                  ),
                  if (_rolesError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: MaktabSpacing.xs),
                      child: Text(_rolesError!, style: TextStyle(color: theme.colorScheme.error)),
                    ),
                ],
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
