import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/modules/presentation/module_placeholder_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/users_screen.dart';
import '../auth/session_controller.dart';
import '../widgets/maktab_shell.dart';
import 'destinations.dart';
import 'redirect.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) =>
        resolveRedirect(session: ref.read(sessionControllerProvider), location: state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.changePassword, builder: (_, _) => const ChangePasswordScreen()),
      ShellRoute(
        builder: (context, state, child) => MaktabShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: Routes.dashboard, builder: (_, _) => const DashboardScreen()),
          for (final module in _placeholderModules)
            GoRoute(
              path: module.$1,
              builder: (context, _) => ModulePlaceholderScreen(destinationId: module.$2, phase: module.$3),
            ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
            routes: [GoRoute(path: 'users', builder: (_, _) => const UsersScreen())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Modules built in later phases: (path, destination id, roadmap phase).
const _placeholderModules = [
  ('/students', 'students', 2),
  ('/parents', 'parents', 2),
  ('/classes', 'classes', 2),
  ('/lessons', 'lessons', 3),
  ('/curriculum', 'curriculum', 3),
  ('/progress', 'progress', 4),
  ('/payments', 'payments', 5),
  ('/reports', 'reports', 6),
];

AppDestination destinationById(String id) => allDestinations.firstWhere((d) => d.id == id);
