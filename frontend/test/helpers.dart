import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/auth/token_storage.dart';
import 'package:maktab/l10n/generated/app_localizations.dart';

AuthUser testUser({
  List<String> roles = const [Roles.teacher],
  Set<String> permissions = const {
    Permissions.studentRead,
    Permissions.curriculumRead,
    Permissions.lessonRecord,
    Permissions.progressRecord,
    Permissions.reportRead,
  },
  bool mustChangePassword = false,
}) =>
    AuthUser(
      id: 'u1',
      email: 'aisha@test.local',
      firstName: 'Aisha',
      lastName: 'Yilmaz',
      roles: roles,
      permissions: permissions,
      mustChangePassword: mustChangePassword,
    );

AuthUser adminUser() => testUser(
      roles: const [Roles.admin],
      permissions: const {
        Permissions.userManage,
        Permissions.settingsManage,
        Permissions.auditRead,
        Permissions.studentRead,
        Permissions.studentWrite,
        Permissions.parentRead,
        Permissions.classManage,
        Permissions.curriculumRead,
        Permissions.lessonRecord,
        Permissions.progressRecord,
        Permissions.paymentRead,
        Permissions.reportRead,
      },
    );

/// Wraps a widget with the app's localisations for widget tests.
Widget localized(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// In-memory stand-in for secure storage.
class InMemoryTokenStorage implements TokenStorage {
  String? _access;
  String? refresh;

  @override
  String? get accessToken => _access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    _access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    refresh = null;
  }
}
