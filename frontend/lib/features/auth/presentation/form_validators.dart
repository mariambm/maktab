import '../../../l10n/generated/app_localizations.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Client-side checks that mirror the backend's rules, for instant feedback. The backend validates again.
abstract final class FormValidators {
  static String? email(String? value, AppLocalizations l10n) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return l10n.emailRequired;
    }
    if (!_emailPattern.hasMatch(text)) {
      return l10n.emailInvalid;
    }
    return null;
  }

  static String? required(String? value, String message) => (value == null || value.isEmpty) ? message : null;

  static String? newPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    return value.length < 10 ? l10n.newPasswordTooShort : null;
  }
}
