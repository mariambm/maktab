import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../auth/session_controller.dart';
import '../routing/destinations.dart';
import '../theme/maktab_spacing.dart';
import 'maktab_logo.dart';

/// The signed-in frame: a bottom navigation bar with "More" on phones, a navigation rail on tablets and wider.
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
      final destinations = visibleDestinations(user);
      final selected = destinations.indexWhere((d) => d.id == current?.id);
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: MaktabSpacing.md),
                child: MaktabLogo(size: 32, showWordmark: false),
              ),
              selectedIndex: selected < 0 ? null : selected,
              onDestinationSelected: (i) => context.go(destinations[i].path),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label(l10n)),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
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
          if (secondary.isNotEmpty)
            NavigationDestination(icon: const Icon(Icons.more_horiz), label: l10n.navMore),
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
