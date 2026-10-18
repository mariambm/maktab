import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/organisation/organisation_name.dart';
import '../../../core/theme/maktab_colors.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/mosque_mark.dart';
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
    final wide = MediaQuery.sizeOf(context).width >= MaktabSpacing.wideLayout;
    final form = Padding(
      padding: const EdgeInsets.all(MaktabSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
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
                if (_error != null) ...[_ErrorBanner(message: _error!), const SizedBox(height: MaktabSpacing.md)],
                TextFormField(
                  key: const Key('login.email'),
                  controller: _email,
                  decoration: InputDecoration(labelText: l10n.emailLabel, prefixIcon: const Icon(Icons.email_outlined)),
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
    );
    if (wide) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MaktabSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920, minHeight: 520),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: _BrandPanel()),
                      Expanded(child: Center(child: form)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // At least 260 high, but taller when a large system font or a long mosque name needs it.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 260, minWidth: double.infinity),
                child: const _BrandPanel(compact: true),
              ),
              form,
            ],
          ),
        ),
      ),
    );
  }
}

/// The welcoming side of the sign-in screen: the mosque mark, the mosque's name and a faint skyline.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MaktabColors.primaryContainer.withValues(alpha: 0.55),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: compact ? 110 : 160,
            child: MosqueSkyline(color: MaktabColors.primary.withValues(alpha: 0.08)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(MaktabSpacing.lg),
              child: _Header(compact: compact),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Maktab mark with the mosque's name under it, once the server has told us the name.
class _Header extends ConsumerWidget {
  const _Header({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = ref.watch(organisationNameProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MosqueMark(size: compact ? 64 : 96, color: MaktabColors.primary),
        const SizedBox(height: MaktabSpacing.sm),
        Text(
          'Maktab',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: MaktabColors.primaryDark),
        ),
        if (name != null)
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: MaktabColors.primaryDark),
          ),
        if (!compact) ...[
          const SizedBox(height: MaktabSpacing.md),
          Text(
            l10n.loginTagline,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: MaktabSpacing.sm),
            Expanded(
              child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}
