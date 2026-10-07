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

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get remove => 'Remove';

  @override
  String get notSet => 'Not set';

  @override
  String get optional => 'Optional';

  @override
  String get filterAll => 'All';

  @override
  String get statusActive => 'Active';

  @override
  String get selectDate => 'Select date';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get searchStudentsHint => 'Search by name';

  @override
  String get filterAllClasses => 'All classes';

  @override
  String get studentsEmpty => 'No students found';

  @override
  String get studentsEmptyHint => 'Try another search or filter.';

  @override
  String get studentsEmptyTeacher =>
      'Students appear here once you are assigned to a class.';

  @override
  String get addStudent => 'Add Student';

  @override
  String get editStudent => 'Edit student';

  @override
  String get studentNoClass => 'No class';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get dateOfBirthLabel => 'Date of birth';

  @override
  String get dateOfBirthRequired => 'Date of birth is required';

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderNotRecorded => 'Not recorded';

  @override
  String get joinedOnLabel => 'Joined on';

  @override
  String get leftOnLabel => 'Left on';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint =>
      'Anything teachers should know, for example how the child is collected';

  @override
  String get classSection => 'Class';

  @override
  String get classHistory => 'Class history';

  @override
  String get moveToClass => 'Move to another class';

  @override
  String get placeInClass => 'Place in a class';

  @override
  String get removeFromClass => 'Remove from class';

  @override
  String get parentsSection => 'Parents & Guardians';

  @override
  String get noParents => 'No parents or guardians linked yet';

  @override
  String get primaryContact => 'Primary contact';

  @override
  String get makePrimaryContact => 'Make primary contact';

  @override
  String get manageParents => 'Manage parents';

  @override
  String get deactivateStudent => 'Deactivate';

  @override
  String get reactivateStudent => 'Reactivate';

  @override
  String get deactivateConfirmBody =>
      'They leave their class today. Their history is kept and you can reactivate them later.';

  @override
  String get studentDeactivated => 'Student deactivated';

  @override
  String get studentReactivated => 'Student reactivated';

  @override
  String get studentSaved => 'Student saved';

  @override
  String get studentCreated => 'Student added';

  @override
  String get moreComingNote =>
      'Attendance, progress, behaviour and lesson history appear here in later phases.';

  @override
  String get relationshipMother => 'Mother';

  @override
  String get relationshipFather => 'Father';

  @override
  String get relationshipGuardian => 'Guardian';

  @override
  String get relationshipOther => 'Other';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get classOptionalLabel => 'Class (optional)';

  @override
  String get noClassOption => 'No class yet';

  @override
  String get chooseClass => 'Choose a class';

  @override
  String get addParentLink => 'Add parent or guardian';

  @override
  String get newParent => 'New parent or guardian';

  @override
  String get chooseExistingParent => 'Choose an existing parent or guardian';

  @override
  String get moveDateLabel => 'Start date in the new class';

  @override
  String get parentsEmpty => 'No parents or guardians found';

  @override
  String get searchParentsHint => 'Search by name, phone or email';

  @override
  String get addParentTitle => 'Add parent or guardian';

  @override
  String get editParent => 'Edit parent or guardian';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneInvalid => 'Enter a valid phone number';

  @override
  String get emailOptionalLabel => 'Email (optional)';

  @override
  String get childrenSection => 'Children';

  @override
  String get noChildren => 'No children linked yet';

  @override
  String get parentSaved => 'Parent or guardian saved';

  @override
  String get contactSection => 'Contact';

  @override
  String get classesEmpty => 'No classes yet';

  @override
  String get classesEmptyTeacher => 'You are not assigned to a class yet.';

  @override
  String get addClass => 'Add class';

  @override
  String get editClass => 'Edit class';

  @override
  String get classNameLabel => 'Class name';

  @override
  String get levelLabel => 'Curriculum level';

  @override
  String get levelRequired => 'Choose a curriculum level';

  @override
  String get newLevel => 'New level';

  @override
  String get levelNameLabel => 'Level name';

  @override
  String get roomLabel => 'Room';

  @override
  String get classActiveLabel => 'Class is active';

  @override
  String get classInactiveHint => 'Inactive classes cannot take new students.';

  @override
  String get teachersSection => 'Teachers';

  @override
  String get noTeachers => 'No teacher assigned';

  @override
  String get editTeachers => 'Edit teachers';

  @override
  String get scheduleSection => 'Weekly schedule';

  @override
  String get noSchedule => 'No schedule yet';

  @override
  String get editSchedule => 'Edit schedule';

  @override
  String get addSlot => 'Add time slot';

  @override
  String get startTimeLabel => 'Start';

  @override
  String get endTimeLabel => 'End';

  @override
  String get endAfterStart => 'End time must be after start time';

  @override
  String get studentsSection => 'Students';

  @override
  String get classNoStudents => 'No students in this class yet';

  @override
  String get classSaved => 'Class saved';

  @override
  String get weekdayMONDAY => 'Monday';

  @override
  String get weekdayTUESDAY => 'Tuesday';

  @override
  String get weekdayWEDNESDAY => 'Wednesday';

  @override
  String get weekdayTHURSDAY => 'Thursday';

  @override
  String get weekdayFRIDAY => 'Friday';

  @override
  String get weekdaySATURDAY => 'Saturday';

  @override
  String get weekdaySUNDAY => 'Sunday';

  @override
  String ageYears(int age) {
    return '$age years';
  }

  @override
  String showingSome(int shown, int total) {
    return 'Showing $shown of $total. Search to narrow the list.';
  }

  @override
  String currentClassSince(String date) {
    return 'Since $date';
  }

  @override
  String enrollmentPeriod(String from, String to) {
    return '$from to $to';
  }

  @override
  String enrollmentSince(String from) {
    return 'From $from';
  }

  @override
  String removeFromClassConfirm(String name, String className) {
    return '$name will no longer be in $className. Their class history is kept.';
  }

  @override
  String deactivateConfirmTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String movedToClass(String className) {
    return 'Moved to $className';
  }

  @override
  String childrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
      zero: 'No children',
    );
    return '$_temp0';
  }

  @override
  String studentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
      zero: 'No students',
    );
    return '$_temp0';
  }
}
