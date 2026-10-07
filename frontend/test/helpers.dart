import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/core/auth/token_storage.dart';
import 'package:maktab/l10n/generated/app_localizations.dart';

AuthUser testUser({
  List<String> roles = const [Roles.teacher],
  Set<String> permissions = const {
    Permissions.studentRead,
    Permissions.classRead,
    Permissions.curriculumRead,
    Permissions.lessonRecord,
    Permissions.progressRecord,
    Permissions.reportRead,
  },
  bool mustChangePassword = false,
}) => AuthUser(
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
    Permissions.parentWrite,
    Permissions.classRead,
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

/// A fake API for repository tests: [handler] gets each request and returns (status, JSON body). Every request is
/// recorded so tests can check paths, query parameters and bodies.
class FakeApi implements HttpClientAdapter {
  FakeApi(this.handler);

  final (int, Object?) Function(RequestOptions request) handler;
  final requests = <RequestOptions>[];

  Dio get dio => Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A session that is already signed in as [user], for widget tests of signed-in screens.
class SignedInSession extends SessionController {
  SignedInSession(this.user);

  final AuthUser user;

  @override
  Future<AuthUser?> build() async => user;
}
