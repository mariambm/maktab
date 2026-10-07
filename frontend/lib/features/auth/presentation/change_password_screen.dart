import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/routing/redirect.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'form_validators.dart';

/// Shown automatically after signing in with a temporary password, and reachable from Settings.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(currentPassword: _current.text, newPassword: _new.text);
      await ref.read(sessionControllerProvider.notifier).reload();
      messenger.showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
      if (mounted) {
        context.go(Routes.dashboard);
      }
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? errorMessage(e, l10n) : null;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final forced = ref.watch(sessionControllerProvider).value?.mustChangePassword ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changePasswordTitle),
        automaticallyImplyLeading: !forced,
        actions: [
          if (forced)
            TextButton(
              onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
              child: Text(l10n.signOut),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MaktabSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (forced) ...[
                    Text(l10n.changePasswordIntro),
                    const SizedBox(height: MaktabSpacing.lg),
                  ],
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: MaktabSpacing.md),
                  ],
                  TextFormField(
                    controller: _current,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.currentPasswordLabel),
                    autofillHints: const [AutofillHints.password],
                    validator: (v) =>
                        FormValidators.required(v, l10n.passwordRequired) ?? _fieldErrors['currentPassword'],
                  ),
                  const SizedBox(height: MaktabSpacing.md),
                  TextFormField(
                    controller: _new,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.newPasswordLabel),
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => FormValidators.newPassword(v, l10n) ?? _fieldErrors['newPassword'],
                  ),
                  const SizedBox(height: MaktabSpacing.md),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.confirmPasswordLabel),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => v == _new.text ? null : l10n.passwordsDoNotMatch,
                  ),
                  const SizedBox(height: MaktabSpacing.lg),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
