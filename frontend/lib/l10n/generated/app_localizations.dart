import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Maktab'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Mosque Education Management'**
  String get appTagline;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get navStudents;

  /// No description provided for @navParents.
  ///
  /// In en, this message translates to:
  /// **'Parents & Guardians'**
  String get navParents;

  /// No description provided for @navClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get navClasses;

  /// No description provided for @navLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get navLessons;

  /// No description provided for @navCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get navCurriculum;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Maktab'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum, {name}'**
  String greeting(String name);

  /// No description provided for @teacherDashboardHint.
  ///
  /// In en, this message translates to:
  /// **'Your lessons for today will appear here once classes are set up.'**
  String get teacherDashboardHint;

  /// No description provided for @adminDashboardHint.
  ///
  /// In en, this message translates to:
  /// **'An overview of attendance, progress and payments will appear here.'**
  String get adminDashboardHint;

  /// No description provided for @moduleComingTitle.
  ///
  /// In en, this message translates to:
  /// **'{module} is on its way'**
  String moduleComingTitle(String module);

  /// No description provided for @moduleComingBody.
  ///
  /// In en, this message translates to:
  /// **'This part of Maktab is built in phase {phase} of the roadmap.'**
  String moduleComingBody(int phase);

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Please choose a new password before you continue.'**
  String get changePasswordIntro;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmPasswordLabel;

  /// No description provided for @newPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters'**
  String get newPasswordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed'**
  String get passwordChanged;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @usersAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Users & Permissions'**
  String get usersAndPermissions;

  /// No description provided for @usersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get usersEmpty;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdministrator;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @searchStudentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchStudentsHint;

  /// No description provided for @filterAllClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get filterAllClasses;

  /// No description provided for @studentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get studentsEmpty;

  /// No description provided for @studentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try another search or filter.'**
  String get studentsEmptyHint;

  /// No description provided for @studentsEmptyTeacher.
  ///
  /// In en, this message translates to:
  /// **'Students appear here once you are assigned to a class.'**
  String get studentsEmptyTeacher;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudent;

  /// No description provided for @editStudent.
  ///
  /// In en, this message translates to:
  /// **'Edit student'**
  String get editStudent;

  /// No description provided for @studentNoClass.
  ///
  /// In en, this message translates to:
  /// **'No class'**
  String get studentNoClass;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirthLabel;

  /// No description provided for @dateOfBirthRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get dateOfBirthRequired;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get genderNotRecorded;

  /// No description provided for @joinedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined on'**
  String get joinedOnLabel;

  /// No description provided for @leftOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Left on'**
  String get leftOnLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Anything teachers should know, for example how the child is collected'**
  String get notesHint;

  /// No description provided for @classSection.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classSection;

  /// No description provided for @classHistory.
  ///
  /// In en, this message translates to:
  /// **'Class history'**
  String get classHistory;

  /// No description provided for @moveToClass.
  ///
  /// In en, this message translates to:
  /// **'Move to another class'**
  String get moveToClass;

  /// No description provided for @placeInClass.
  ///
  /// In en, this message translates to:
  /// **'Place in a class'**
  String get placeInClass;

  /// No description provided for @removeFromClass.
  ///
  /// In en, this message translates to:
  /// **'Remove from class'**
  String get removeFromClass;

  /// No description provided for @parentsSection.
  ///
  /// In en, this message translates to:
  /// **'Parents & Guardians'**
  String get parentsSection;

  /// No description provided for @noParents.
  ///
  /// In en, this message translates to:
  /// **'No parents or guardians linked yet'**
  String get noParents;

  /// No description provided for @primaryContact.
  ///
  /// In en, this message translates to:
  /// **'Primary contact'**
  String get primaryContact;

  /// No description provided for @makePrimaryContact.
  ///
  /// In en, this message translates to:
  /// **'Make primary contact'**
  String get makePrimaryContact;

  /// No description provided for @manageParents.
  ///
  /// In en, this message translates to:
  /// **'Manage parents'**
  String get manageParents;

  /// No description provided for @deactivateStudent.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateStudent;

  /// No description provided for @reactivateStudent.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateStudent;

  /// No description provided for @deactivateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They leave their class today. Their history is kept and you can reactivate them later.'**
  String get deactivateConfirmBody;

  /// No description provided for @studentDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Student deactivated'**
  String get studentDeactivated;

  /// No description provided for @studentReactivated.
  ///
  /// In en, this message translates to:
  /// **'Student reactivated'**
  String get studentReactivated;

  /// No description provided for @studentSaved.
  ///
  /// In en, this message translates to:
  /// **'Student saved'**
  String get studentSaved;

  /// No description provided for @studentCreated.
  ///
  /// In en, this message translates to:
  /// **'Student added'**
  String get studentCreated;

  /// No description provided for @moreComingNote.
  ///
  /// In en, this message translates to:
  /// **'Attendance, progress, behaviour and lesson history appear here in later phases.'**
  String get moreComingNote;

  /// No description provided for @relationshipMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationshipMother;

  /// No description provided for @relationshipFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationshipFather;

  /// No description provided for @relationshipGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get relationshipGuardian;

  /// No description provided for @relationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipLabel;

  /// No description provided for @classOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Class (optional)'**
  String get classOptionalLabel;

  /// No description provided for @noClassOption.
  ///
  /// In en, this message translates to:
  /// **'No class yet'**
  String get noClassOption;

  /// No description provided for @chooseClass.
  ///
  /// In en, this message translates to:
  /// **'Choose a class'**
  String get chooseClass;

  /// No description provided for @addParentLink.
  ///
  /// In en, this message translates to:
  /// **'Add parent or guardian'**
  String get addParentLink;

  /// No description provided for @newParent.
  ///
  /// In en, this message translates to:
  /// **'New parent or guardian'**
  String get newParent;

  /// No description provided for @chooseExistingParent.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing parent or guardian'**
  String get chooseExistingParent;

  /// No description provided for @moveDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date in the new class'**
  String get moveDateLabel;

  /// No description provided for @parentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No parents or guardians found'**
  String get parentsEmpty;

  /// No description provided for @searchParentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or email'**
  String get searchParentsHint;

  /// No description provided for @addParentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add parent or guardian'**
  String get addParentTitle;

  /// No description provided for @editParent.
  ///
  /// In en, this message translates to:
  /// **'Edit parent or guardian'**
  String get editParent;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get phoneInvalid;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptionalLabel;

  /// No description provided for @childrenSection.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get childrenSection;

  /// No description provided for @noChildren.
  ///
  /// In en, this message translates to:
  /// **'No children linked yet'**
  String get noChildren;

  /// No description provided for @parentSaved.
  ///
  /// In en, this message translates to:
  /// **'Parent or guardian saved'**
  String get parentSaved;

  /// No description provided for @contactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactSection;

  /// No description provided for @classesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No classes yet'**
  String get classesEmpty;

  /// No description provided for @classesEmptyTeacher.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to a class yet.'**
  String get classesEmptyTeacher;

  /// No description provided for @addClass.
  ///
  /// In en, this message translates to:
  /// **'Add class'**
  String get addClass;

  /// No description provided for @editClass.
  ///
  /// In en, this message translates to:
  /// **'Edit class'**
  String get editClass;

  /// No description provided for @classNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get classNameLabel;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Curriculum level'**
  String get levelLabel;

  /// No description provided for @levelRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a curriculum level'**
  String get levelRequired;

  /// No description provided for @newLevel.
  ///
  /// In en, this message translates to:
  /// **'New level'**
  String get newLevel;

  /// No description provided for @levelNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Level name'**
  String get levelNameLabel;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomLabel;

  /// No description provided for @classActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Class is active'**
  String get classActiveLabel;

  /// No description provided for @classInactiveHint.
  ///
  /// In en, this message translates to:
  /// **'Inactive classes cannot take new students.'**
  String get classInactiveHint;

  /// No description provided for @teachersSection.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachersSection;

  /// No description provided for @noTeachers.
  ///
  /// In en, this message translates to:
  /// **'No teacher assigned'**
  String get noTeachers;

  /// No description provided for @editTeachers.
  ///
  /// In en, this message translates to:
  /// **'Edit teachers'**
  String get editTeachers;

  /// No description provided for @scheduleSection.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get scheduleSection;

  /// No description provided for @noSchedule.
  ///
  /// In en, this message translates to:
  /// **'No schedule yet'**
  String get noSchedule;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get editSchedule;

  /// No description provided for @addSlot.
  ///
  /// In en, this message translates to:
  /// **'Add time slot'**
  String get addSlot;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endTimeLabel;

  /// No description provided for @endAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endAfterStart;

  /// No description provided for @studentsSection.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsSection;

  /// No description provided for @classNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students in this class yet'**
  String get classNoStudents;

  /// No description provided for @classSaved.
  ///
  /// In en, this message translates to:
  /// **'Class saved'**
  String get classSaved;

  /// No description provided for @weekdayMONDAY.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMONDAY;

  /// No description provided for @weekdayTUESDAY.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTUESDAY;

  /// No description provided for @weekdayWEDNESDAY.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWEDNESDAY;

  /// No description provided for @weekdayTHURSDAY.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayTHURSDAY;

  /// No description provided for @weekdayFRIDAY.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFRIDAY;

  /// No description provided for @weekdaySATURDAY.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySATURDAY;

  /// No description provided for @weekdaySUNDAY.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySUNDAY;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String ageYears(int age);

  /// No description provided for @showingSome.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}. Search to narrow the list.'**
  String showingSome(int shown, int total);

  /// No description provided for @currentClassSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String currentClassSince(String date);

  /// No description provided for @enrollmentPeriod.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String enrollmentPeriod(String from, String to);

  /// No description provided for @enrollmentSince.
  ///
  /// In en, this message translates to:
  /// **'From {from}'**
  String enrollmentSince(String from);

  /// No description provided for @removeFromClassConfirm.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be in {className}. Their class history is kept.'**
  String removeFromClassConfirm(String name, String className);

  /// No description provided for @deactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String deactivateConfirmTitle(String name);

  /// No description provided for @movedToClass.
  ///
  /// In en, this message translates to:
  /// **'Moved to {className}'**
  String movedToClass(String className);

  /// No description provided for @childrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No children} =1{1 child} other{{count} children}}'**
  String childrenCount(int count);

  /// No description provided for @studentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No students} =1{1 student} other{{count} students}}'**
  String studentCount(int count);

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUser;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get searchUsersHint;

  /// No description provided for @userSaved.
  ///
  /// In en, this message translates to:
  /// **'User saved'**
  String get userSaved;

  /// No description provided for @rolesSection.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get rolesSection;

  /// No description provided for @rolesRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one role'**
  String get rolesRequired;

  /// No description provided for @editRoles.
  ///
  /// In en, this message translates to:
  /// **'Edit roles'**
  String get editRoles;

  /// No description provided for @extraPermissionsSection.
  ///
  /// In en, this message translates to:
  /// **'Extra permissions'**
  String get extraPermissionsSection;

  /// No description provided for @extraPermissionsHint.
  ///
  /// In en, this message translates to:
  /// **'Given on top of what their roles already allow.'**
  String get extraPermissionsHint;

  /// No description provided for @noExtraPermissions.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noExtraPermissions;

  /// No description provided for @editPermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit extra permissions'**
  String get editPermissions;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountDetails;

  /// No description provided for @lastSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in'**
  String get lastSignInLabel;

  /// No description provided for @neverSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverSignedIn;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @mustChangePasswordChip.
  ///
  /// In en, this message translates to:
  /// **'Must choose a new password'**
  String get mustChangePasswordChip;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password for {name}?'**
  String resetPasswordConfirmTitle(String name);

  /// No description provided for @resetPasswordConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They are signed out everywhere and get a new temporary password.'**
  String get resetPasswordConfirmBody;

  /// No description provided for @temporaryPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get temporaryPasswordTitle;

  /// No description provided for @temporaryPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Give this password to {name} in person or by phone. It is shown only once. They choose their own password when they first sign in.'**
  String temporaryPasswordBody(String name);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @deactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get deactivateUser;

  /// No description provided for @reactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Reactivate account'**
  String get reactivateUser;

  /// No description provided for @deactivateUserConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They are signed out everywhere and can no longer sign in. You can reactivate the account later.'**
  String get deactivateUserConfirmBody;

  /// No description provided for @userDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated'**
  String get userDeactivated;

  /// No description provided for @userReactivated.
  ///
  /// In en, this message translates to:
  /// **'Account reactivated'**
  String get userReactivated;

  /// No description provided for @permUSER_MANAGE.
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get permUSER_MANAGE;

  /// No description provided for @permSETTINGS_MANAGE.
  ///
  /// In en, this message translates to:
  /// **'Manage settings'**
  String get permSETTINGS_MANAGE;

  /// No description provided for @permAUDIT_READ.
  ///
  /// In en, this message translates to:
  /// **'View audit log'**
  String get permAUDIT_READ;

  /// No description provided for @permSTUDENT_READ.
  ///
  /// In en, this message translates to:
  /// **'View students'**
  String get permSTUDENT_READ;

  /// No description provided for @permSTUDENT_WRITE.
  ///
  /// In en, this message translates to:
  /// **'Edit students'**
  String get permSTUDENT_WRITE;

  /// No description provided for @permPARENT_READ.
  ///
  /// In en, this message translates to:
  /// **'View parents'**
  String get permPARENT_READ;

  /// No description provided for @permPARENT_WRITE.
  ///
  /// In en, this message translates to:
  /// **'Edit parents'**
  String get permPARENT_WRITE;

  /// No description provided for @permCLASS_READ.
  ///
  /// In en, this message translates to:
  /// **'View classes'**
  String get permCLASS_READ;

  /// No description provided for @permCLASS_MANAGE.
  ///
  /// In en, this message translates to:
  /// **'Manage classes'**
  String get permCLASS_MANAGE;

  /// No description provided for @permCURRICULUM_READ.
  ///
  /// In en, this message translates to:
  /// **'View curriculum'**
  String get permCURRICULUM_READ;

  /// No description provided for @permCURRICULUM_WRITE.
  ///
  /// In en, this message translates to:
  /// **'Edit curriculum'**
  String get permCURRICULUM_WRITE;

  /// No description provided for @permLESSON_RECORD.
  ///
  /// In en, this message translates to:
  /// **'Record lessons'**
  String get permLESSON_RECORD;

  /// No description provided for @permPROGRESS_RECORD.
  ///
  /// In en, this message translates to:
  /// **'Record progress'**
  String get permPROGRESS_RECORD;

  /// No description provided for @permTARGET_MANAGE.
  ///
  /// In en, this message translates to:
  /// **'Manage targets'**
  String get permTARGET_MANAGE;

  /// No description provided for @permOBSERVATION_RECORD.
  ///
  /// In en, this message translates to:
  /// **'Record observations'**
  String get permOBSERVATION_RECORD;

  /// No description provided for @permPAYMENT_READ.
  ///
  /// In en, this message translates to:
  /// **'View payments'**
  String get permPAYMENT_READ;

  /// No description provided for @permPAYMENT_WRITE.
  ///
  /// In en, this message translates to:
  /// **'Record payments'**
  String get permPAYMENT_WRITE;

  /// No description provided for @permREPORT_READ.
  ///
  /// In en, this message translates to:
  /// **'View reports'**
  String get permREPORT_READ;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
