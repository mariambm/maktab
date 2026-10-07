import '../../../core/auth/auth_models.dart';
import '../../../l10n/generated/app_localizations.dart';

String roleLabel(String role, AppLocalizations l10n) => switch (role) {
      Roles.admin => l10n.roleAdmin,
      Roles.administrator => l10n.roleAdministrator,
      Roles.teacher => l10n.roleTeacher,
      _ => role,
    };
