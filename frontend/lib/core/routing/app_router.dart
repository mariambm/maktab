import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/classes/presentation/class_detail_screen.dart';
import '../../features/classes/presentation/class_form_screen.dart';
import '../../features/classes/presentation/classes_screen.dart';
import '../../features/curriculum/presentation/curriculum_period_form_screen.dart';
import '../../features/curriculum/presentation/curriculum_period_screen.dart';
import '../../features/curriculum/presentation/curriculum_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/lessons/presentation/lesson_detail_screen.dart';
import '../../features/lessons/presentation/lessons_screen.dart';
import '../../features/modules/presentation/module_placeholder_screen.dart';
import '../../features/parents/presentation/parent_detail_screen.dart';
import '../../features/parents/presentation/parent_form_screen.dart';
import '../../features/parents/presentation/parents_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/user_detail_screen.dart';
import '../../features/settings/presentation/user_form_screen.dart';
import '../../features/settings/presentation/users_screen.dart';
import '../../features/students/presentation/student_form_screen.dart';
import '../../features/students/presentation/student_profile_screen.dart';
import '../../features/students/presentation/students_screen.dart';
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
          GoRoute(
            path: '/students',
            builder: (_, _) => const StudentsScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, _) => const StudentFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => StudentProfileScreen(studentId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => StudentFormScreen(studentId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/parents',
            builder: (_, _) => const ParentsScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, _) => const ParentFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => ParentDetailScreen(parentId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => ParentFormScreen(parentId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/classes',
            builder: (_, _) => const ClassesScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, _) => const ClassFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => ClassDetailScreen(classId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => ClassFormScreen(classId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/lessons',
            builder: (_, _) => const LessonsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => LessonDetailScreen(lessonId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/curriculum',
            builder: (_, _) => const CurriculumScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, _) => const CurriculumPeriodFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => CurriculumPeriodScreen(periodId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) =>
                        CurriculumPeriodFormScreen(periodId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          for (final module in _placeholderModules)
            GoRoute(
              path: module.$1,
              builder: (context, _) => ModulePlaceholderScreen(destinationId: module.$2, phase: module.$3),
            ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'users',
                builder: (_, _) => const UsersScreen(),
                routes: [
                  GoRoute(path: 'new', builder: (_, _) => const UserFormScreen()),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => UserDetailScreen(userId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) => UserFormScreen(userId: state.pathParameters['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
  ('/progress', 'progress', 4),
  ('/payments', 'payments', 5),
  ('/reports', 'reports', 6),
];

AppDestination destinationById(String id) => allDestinations.firstWhere((d) => d.id == id);
