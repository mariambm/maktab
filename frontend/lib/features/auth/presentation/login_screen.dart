import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/organisation/organisation_name.dart';
import '../../../core/theme/maktab_colors.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/geometric_pattern.dart';
import '../../../core/widgets/maktab_logo.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'form_validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).signIn(_email.text, _password.text);
    } catch (e) {
      if (mounted) {
        setState(() => _error = errorMessage(e, AppLocalizations.of(context)));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                color: MaktabColors.teal,
                child: Stack(
                  children: [
                    Positioned.fill(child: GeometricPattern(color: Colors.white.withValues(alpha: 0.07))),
                    const Center(child: _Header()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MaktabSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.loginTitle, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: MaktabSpacing.xs),
                          Text(
                            l10n.loginSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: MaktabSpacing.lg),
                          if (_error != null) ...[
                            _ErrorBanner(message: _error!),
                            const SizedBox(height: MaktabSpacing.md),
                          ],
                          TextFormField(
                            key: const Key('login.email'),
                            controller: _email,
                            decoration: InputDecoration(
                              labelText: l10n.emailLabel,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            autocorrect: false,
                            validator: (v) => FormValidators.email(v, l10n),
                          ),
                          const SizedBox(height: MaktabSpacing.md),
                          TextFormField(
                            key: const Key('login.password'),
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => FormValidators.required(v, l10n.passwordRequired),
                          ),
                          const SizedBox(height: MaktabSpacing.lg),
                          FilledButton(
                            key: const Key('login.submit'),
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l10n.signIn),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Maktab mark with the mosque's name under it, once the server has told us the name.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(organisationNameProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MaktabLogo(size: 52, onDark: true),
        if (name != null) ...[
          const SizedBox(height: MaktabSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.lg),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(MaktabSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: MaktabSpacing.sm),
            Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer))),
          ],
        ),
      ),
    );
  }
}
