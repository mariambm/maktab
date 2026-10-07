import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/formatting.dart';
import '../../../core/routing/redirect.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/user_summary.dart';
import '../data/users_repository.dart';
import 'role_label.dart';
import 'selection_sheet.dart';
import 'temporary_password_dialog.dart';

/// One account: details, roles, extra permissions, and the reset-password and (de)activate actions.
class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(userProvider(userId));
    return Scaffold(
      appBar: AppBar(
        title: Text(user.value?.displayName ?? l10n.usersAndPermissions),
        actions: [
          if (user.hasValue)
            IconButton(
              tooltip: l10n.editUser,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('${Routes.users}/$userId/edit'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(userProvider(userId).future),
        child: AsyncView(
          value: user,
          onRetry: () => ref.invalidate(userProvider(userId)),
          data: (u) => _UserDetails(user: u),
        ),
      ),
    );
  }
}

class _UserDetails extends ConsumerWidget {
  const _UserDetails({required this.user});

  final UserSummary user;

  void _refresh(WidgetRef ref) {
    ref.invalidate(userProvider(user.id));
    ref.invalidate(usersProvider);
  }

  Future<void> _editRoles(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final saved = await showSelectionSheet(
      context,
      title: l10n.editRoles,
      options: allRoles,
      labelOf: (r) => roleLabel(r, l10n),
      selected: user.roles.toSet(),
      requiredMessage: l10n.rolesRequired,
      onSave: (roles) => ref.read(usersRepositoryProvider).replaceRoles(user.id, roles),
    );
    if (saved ?? false) {
      _refresh(ref);
    }
  }

  Future<void> _editPermissions(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final saved = await showSelectionSheet(
      context,
      title: l10n.editPermissions,
      hint: l10n.extraPermissionsHint,
      options: allPermissions,
      labelOf: (p) => permissionLabel(p, l10n),
      selected: user.grantedPermissions.toSet(),
      locked: user.permissionsFromRoles,
      onSave: (permissions) => ref
          .read(usersRepositoryProvider)
          .replacePermissions(user.id, permissions.difference(user.permissionsFromRoles)),
    );
    if (saved ?? false) {
      _refresh(ref);
    }
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.resetPasswordConfirmTitle(user.displayName),
      body: l10n.resetPasswordConfirmBody,
      action: l10n.resetPassword,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      final created = await ref.read(usersRepositoryProvider).resetPassword(user.id);
      if (context.mounted) {
        await showTemporaryPasswordDialog(context, name: user.firstName, password: created.temporaryPassword);
      }
      _refresh(ref);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e, l10n))));
      }
    }
  }

  Future<void> _setActive(BuildContext context, WidgetRef ref, {required bool active}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!active) {
      final confirmed = await _confirm(
        context,
        title: l10n.deactivateConfirmTitle(user.displayName),
        body: l10n.deactivateUserConfirmBody,
        action: l10n.deactivateUser,
      );
      if (!confirmed) {
        return;
      }
    }
    try {
      await ref.read(usersRepositoryProvider).setActive(user.id, active: active);
      _refresh(ref);
      messenger.showSnackBar(SnackBar(content: Text(active ? l10n.userReactivated : l10n.userDeactivated)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.fieldErrors['active'] ?? errorMessage(e, l10n))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isMe = ref.watch(sessionControllerProvider).value?.id == user.id;
    final lastLogin = user.lastLoginAt;
    return ListView(
      padding: const EdgeInsets.all(MaktabSpacing.md),
      children: [
        Wrap(
          spacing: MaktabSpacing.sm,
          runSpacing: MaktabSpacing.sm,
          children: [
            if (isMe) StatusChip(label: l10n.youLabel, icon: Icons.person_outline),
            if (user.active)
              StatusChip(label: l10n.statusActive, icon: Icons.check_circle_outline)
            else
              StatusChip(label: l10n.inactive, icon: Icons.block, muted: true),
            if (user.mustChangePassword)
              StatusChip(label: l10n.mustChangePasswordChip, icon: Icons.password, muted: true),
          ],
        ),
        const SizedBox(height: MaktabSpacing.sm),
        SectionCard(
          title: l10n.accountDetails,
          children: [
            InfoRow(label: l10n.emailLabel, value: user.email),
            InfoRow(
              label: l10n.lastSignInLabel,
              value: lastLogin == null ? l10n.neverSignedIn : formatDateTime(lastLogin),
            ),
          ],
        ),
        const SizedBox(height: MaktabSpacing.sm),
        SectionCard(
          title: l10n.rolesSection,
          action: TextButton(onPressed: () => _editRoles(context, ref), child: Text(l10n.edit)),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
              child: Text(user.roles.map((r) => roleLabel(r, l10n)).join(', ')),
            ),
          ],
        ),
        const SizedBox(height: MaktabSpacing.sm),
        SectionCard(
          title: l10n.extraPermissionsSection,
          action: TextButton(onPressed: () => _editPermissions(context, ref), child: Text(l10n.edit)),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
              child: Text(
                user.grantedPermissions.isEmpty
                    ? l10n.noExtraPermissions
                    : user.grantedPermissions.map((p) => permissionLabel(p, l10n)).join(', '),
              ),
            ),
          ],
        ),
        const SizedBox(height: MaktabSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => _resetPassword(context, ref),
          icon: const Icon(Icons.lock_reset_outlined),
          label: Text(l10n.resetPassword),
        ),
        if (!isMe) ...[
          const SizedBox(height: MaktabSpacing.sm),
          if (user.active)
            OutlinedButton.icon(
              onPressed: () => _setActive(context, ref, active: false),
              icon: const Icon(Icons.person_off_outlined),
              label: Text(l10n.deactivateUser),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _setActive(context, ref, active: true),
              icon: const Icon(Icons.person_outline),
              label: Text(l10n.reactivateUser),
            ),
        ],
      ],
    );
  }
}

Future<bool> _confirm(BuildContext context, {required String title, required String body, required String action}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(action)),
      ],
    ),
  );
  return result ?? false;
}
