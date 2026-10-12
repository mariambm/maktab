import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../features/settings/presentation/role_label.dart';
import '../auth/auth_models.dart';
import '../auth/session_controller.dart';
import '../organisation/organisation_name.dart';
import '../routing/destinations.dart';
import '../theme/maktab_colors.dart';
import '../theme/maktab_spacing.dart';
import 'maktab_logo.dart';

/// The signed-in frame: a bottom navigation bar with "More" on phones; on tablets and wider a dark green sidebar
/// with a top bar showing the mosque and who is signed in.
/// Only destinations the user may use are shown.
class MaktabShell extends ConsumerWidget {
  const MaktabShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = AppLocalizations.of(context);
    final current = destinationForLocation(location);
    final wide = MediaQuery.sizeOf(context).width >= MaktabSpacing.wideLayout;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(destinations: visibleDestinations(user), currentId: current?.id),
            Expanded(
              child: Column(
                children: [
                  _TopBar(user: user),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final primary = primaryDestinations(user);
    final secondary = secondaryDestinations(user);
    final primaryIndex = primary.indexWhere((d) => d.id == current?.id);
    final moreIndex = primary.length;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: primaryIndex >= 0 ? primaryIndex : (secondary.isEmpty ? 0 : moreIndex),
        onDestinationSelected: (i) {
          if (i < primary.length) {
            context.go(primary[i].path);
          } else {
            _showMore(context, secondary, l10n);
          }
        },
        destinations: [
          for (final d in primary)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label(l10n)),
          if (secondary.isNotEmpty) NavigationDestination(icon: const Icon(Icons.more_horiz), label: l10n.navMore),
        ],
      ),
    );
  }

  void _showMore(BuildContext context, List<AppDestination> destinations, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final d in destinations)
              ListTile(
                minTileHeight: MaktabSpacing.touchTarget,
                leading: Icon(d.icon),
                title: Text(d.label(l10n)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(d.path);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// The wide-screen navigation: every module the user may use, with Settings and Sign out at the bottom.
class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.destinations, required this.currentId});

  final List<AppDestination> destinations;
  final String? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final main = destinations.where((d) => d.id != 'settings').toList();
    final settings = destinations.where((d) => d.id == 'settings');
    final mosque = ref.watch(organisationNameProvider).value;
    return Container(
      width: 232,
      color: MaktabColors.sidebar,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MaktabSpacing.md,
                MaktabSpacing.lg,
                MaktabSpacing.md,
                MaktabSpacing.lg,
              ),
              child: MaktabLogo(size: 40, onDark: true, subtitle: mosque),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.sm),
                children: [
                  for (final d in main)
                    _SidebarItem(
                      icon: d.id == currentId ? d.selectedIcon : d.icon,
                      label: d.label(l10n),
                      selected: d.id == currentId,
                      onTap: () => context.go(d.path),
                    ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.12), indent: MaktabSpacing.md, endIndent: MaktabSpacing.md),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MaktabSpacing.sm,
                MaktabSpacing.xs,
                MaktabSpacing.sm,
                MaktabSpacing.md,
              ),
              child: Column(
                children: [
                  for (final d in settings)
                    _SidebarItem(
                      icon: d.id == currentId ? d.selectedIcon : d.icon,
                      label: d.label(l10n),
                      selected: d.id == currentId,
                      onTap: () => context.go(d.path),
                    ),
                  _SidebarItem(
                    icon: Icons.logout,
                    label: l10n.signOut,
                    selected: false,
                    onTap: () => ref.read(sessionControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.78);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? MaktabColors.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The white bar above every wide-screen page: the mosque's name and who is signed in.
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mosque = ref.watch(organisationNameProvider).value;
    final initials = '${user.firstName.characters.firstOrNull ?? ''}${user.lastName.characters.firstOrNull ?? ''}';
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.lg),
      decoration: const BoxDecoration(
        color: MaktabColors.surface,
        border: Border(bottom: BorderSide(color: MaktabColors.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              mosque ?? '',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(color: MaktabColors.primaryDark, fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${user.firstName} ${user.lastName}', style: theme.textTheme.labelLarge),
              Text(
                user.roles.map((r) => roleLabel(r, l10n)).join(', '),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(width: MaktabSpacing.sm),
          CircleAvatar(
            radius: 18,
            backgroundColor: MaktabColors.primaryContainer,
            foregroundColor: MaktabColors.primaryDark,
            child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
