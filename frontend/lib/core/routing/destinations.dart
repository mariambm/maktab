import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../auth/auth_models.dart';

/// A top-level module in the main navigation. [isVisibleTo] mirrors the backend's permission rules so users only
/// see modules they can use; the backend still enforces every rule itself.
class AppDestination {
  const AppDestination({
    required this.id,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isVisibleTo,
  });

  final String id;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) label;
  final bool Function(AuthUser user) isVisibleTo;
}

bool _always(AuthUser _) => true;

final List<AppDestination> allDestinations = [
  AppDestination(
    id: 'dashboard',
    path: '/dashboard',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard,
    label: (l) => l.navDashboard,
    isVisibleTo: _always,
  ),
  AppDestination(
    id: 'students',
    path: '/students',
    icon: Icons.school_outlined,
    selectedIcon: Icons.school,
    label: (l) => l.navStudents,
    isVisibleTo: (u) => u.can(Permissions.studentRead),
  ),
  AppDestination(
    id: 'parents',
    path: '/parents',
    icon: Icons.family_restroom_outlined,
    selectedIcon: Icons.family_restroom,
    label: (l) => l.navParents,
    isVisibleTo: (u) => u.can(Permissions.parentRead),
  ),
  AppDestination(
    id: 'classes',
    path: '/classes',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    label: (l) => l.navClasses,
    isVisibleTo: (u) => u.can(Permissions.classRead),
  ),
  AppDestination(
    id: 'lessons',
    path: '/lessons',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
    label: (l) => l.navLessons,
    isVisibleTo: (u) => u.can(Permissions.lessonRecord),
  ),
  AppDestination(
    id: 'curriculum',
    path: '/curriculum',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    label: (l) => l.navCurriculum,
    isVisibleTo: (u) => u.can(Permissions.curriculumRead),
  ),
  AppDestination(
    id: 'progress',
    path: '/progress',
    icon: Icons.trending_up_outlined,
    selectedIcon: Icons.trending_up,
    label: (l) => l.navProgress,
    isVisibleTo: (u) => u.can(Permissions.progressRecord),
  ),
  AppDestination(
    id: 'payments',
    path: '/payments',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    label: (l) => l.navPayments,
    isVisibleTo: (u) => u.can(Permissions.paymentRead),
  ),
  AppDestination(
    id: 'reports',
    path: '/reports',
    icon: Icons.insert_chart_outlined,
    selectedIcon: Icons.insert_chart,
    label: (l) => l.navReports,
    isVisibleTo: (u) => u.can(Permissions.reportRead),
  ),
  AppDestination(
    id: 'settings',
    path: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: (l) => l.navSettings,
    isVisibleTo: _always,
  ),
];

List<AppDestination> visibleDestinations(AuthUser user) =>
    allDestinations.where((d) => d.isVisibleTo(user)).toList(growable: false);

/// The (up to four) destinations shown in the phone's bottom bar; the rest go under "More". Teachers get their
/// daily tools first.
List<AppDestination> primaryDestinations(AuthUser user) {
  final order = user.isTeacherOnly
      ? const ['dashboard', 'lessons', 'students', 'progress']
      : const ['dashboard', 'students', 'classes', 'payments'];
  final visible = visibleDestinations(user);
  return [for (final id in order) ...visible.where((d) => d.id == id)].take(4).toList(growable: false);
}

List<AppDestination> secondaryDestinations(AuthUser user) {
  final primary = primaryDestinations(user).map((d) => d.id).toSet();
  return visibleDestinations(user).where((d) => !primary.contains(d.id)).toList(growable: false);
}

AppDestination? destinationForLocation(String location) {
  for (final destination in allDestinations) {
    if (location == destination.path || location.startsWith('${destination.path}/')) {
      return destination;
    }
  }
  return null;
}
