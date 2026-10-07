import '../../../core/auth/auth_models.dart';
import '../../../l10n/generated/app_localizations.dart';

String roleLabel(String role, AppLocalizations l10n) => switch (role) {
      Roles.admin => l10n.roleAdmin,
      Roles.administrator => l10n.roleAdministrator,
      Roles.teacher => l10n.roleTeacher,
      _ => role,
    };

const allRoles = [Roles.admin, Roles.administrator, Roles.teacher];

/// Every permission the backend knows, in the order they are offered as extra grants.
const allPermissions = [
  'STUDENT_READ',
  'STUDENT_WRITE',
  'PARENT_READ',
  'PARENT_WRITE',
  'CLASS_READ',
  'CLASS_MANAGE',
  'CURRICULUM_READ',
  'CURRICULUM_WRITE',
  'LESSON_RECORD',
  'PROGRESS_RECORD',
  'TARGET_MANAGE',
  'OBSERVATION_RECORD',
  'PAYMENT_READ',
  'PAYMENT_WRITE',
  'REPORT_READ',
  'USER_MANAGE',
  'SETTINGS_MANAGE',
  'AUDIT_READ',
];

String permissionLabel(String permission, AppLocalizations l10n) => switch (permission) {
      'USER_MANAGE' => l10n.permUSER_MANAGE,
      'SETTINGS_MANAGE' => l10n.permSETTINGS_MANAGE,
      'AUDIT_READ' => l10n.permAUDIT_READ,
      'STUDENT_READ' => l10n.permSTUDENT_READ,
      'STUDENT_WRITE' => l10n.permSTUDENT_WRITE,
      'PARENT_READ' => l10n.permPARENT_READ,
      'PARENT_WRITE' => l10n.permPARENT_WRITE,
      'CLASS_READ' => l10n.permCLASS_READ,
      'CLASS_MANAGE' => l10n.permCLASS_MANAGE,
      'CURRICULUM_READ' => l10n.permCURRICULUM_READ,
      'CURRICULUM_WRITE' => l10n.permCURRICULUM_WRITE,
      'LESSON_RECORD' => l10n.permLESSON_RECORD,
      'PROGRESS_RECORD' => l10n.permPROGRESS_RECORD,
      'TARGET_MANAGE' => l10n.permTARGET_MANAGE,
      'OBSERVATION_RECORD' => l10n.permOBSERVATION_RECORD,
      'PAYMENT_READ' => l10n.permPAYMENT_READ,
      'PAYMENT_WRITE' => l10n.permPAYMENT_WRITE,
      'REPORT_READ' => l10n.permREPORT_READ,
      _ => permission,
    };
