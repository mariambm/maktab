import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import 'destinations.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const dashboard = '/dashboard';
  static const users = '/settings/users';
}

/// Where the router should send the user, or null to stay. Pure so it can be unit tested.
String? resolveRedirect({required AsyncValue<AuthUser?> session, required String location}) {
  if (session.isLoading && !session.hasValue) {
    return location == Routes.splash ? null : Routes.splash;
  }
  final user = session.value;
  if (user == null) {
    return location == Routes.login ? null : Routes.login;
  }
  if (user.mustChangePassword) {
    return location == Routes.changePassword ? null : Routes.changePassword;
  }
  if (location == Routes.login || location == Routes.splash) {
    return Routes.dashboard;
  }
  if (location.startsWith(Routes.users) && !user.can(Permissions.userManage)) {
    return Routes.dashboard;
  }
  final writePermission = _writePermissionFor(location);
  if (writePermission != null && !user.can(writePermission)) {
    return Routes.dashboard;
  }
  final destination = destinationForLocation(location);
  if (destination != null && !destination.isVisibleTo(user)) {
    return Routes.dashboard;
  }
  return null;
}

/// Create and edit screens need the module's write permission, not just read access.
String? _writePermissionFor(String location) {
  final segments = Uri.parse(location).pathSegments;
  if (segments.length < 2 || (segments.last != 'new' && segments.last != 'edit')) {
    return null;
  }
  return switch (segments.first) {
    'students' => Permissions.studentWrite,
    'parents' => Permissions.parentWrite,
    'classes' => Permissions.classManage,
    _ => null,
  };
}
