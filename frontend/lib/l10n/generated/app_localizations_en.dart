// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Maktab';

  @override
  String get appTagline => 'Mosque Education Management';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navStudents => 'Students';

  @override
  String get navParents => 'Parents & Guardians';

  @override
  String get navClasses => 'Classes';

  @override
  String get navLessons => 'Lessons';

  @override
  String get navCurriculum => 'Curriculum';

  @override
  String get navProgress => 'Progress';

  @override
  String get navPayments => 'Payments';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get loginTitle => 'Welcome to Maktab';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get networkError =>
      'Cannot reach the server. Check your connection and try again.';

  @override
  String greeting(String name) {
    return 'Assalamu alaikum, $name';
  }

  @override
  String get teacherDashboardHint =>
      'Your lessons for today will appear here once classes are set up.';

  @override
  String get adminDashboardHint =>
      'An overview of attendance, progress and payments will appear here.';

  @override
  String moduleComingTitle(String module) {
    return '$module is on its way';
  }

  @override
  String moduleComingBody(int phase) {
    return 'This part of Maktab is built in phase $phase of the roadmap.';
  }

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordIntro =>
      'Please choose a new password before you continue.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmPasswordLabel => 'Confirm new password';

  @override
  String get newPasswordTooShort => 'Use at least 10 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordChanged => 'Your password has been changed';

  @override
  String get accountSection => 'Account';

  @override
  String get usersAndPermissions => 'Users & Permissions';

  @override
  String get usersEmpty => 'No users found';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleAdministrator => 'Administrator';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get inactive => 'Inactive';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';
}
