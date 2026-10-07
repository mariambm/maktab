import 'package:flutter/material.dart';

import '../../../core/routing/destinations.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Stands in for a module until its roadmap phase is built, so navigation can be tried end to end.
class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({super.key, required this.destinationId, required this.phase});

  final String destinationId;
  final int phase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destination = allDestinations.firstWhere((d) => d.id == destinationId);
    final title = destination.label(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: MessageView(
        icon: destination.icon,
        title: l10n.moduleComingTitle(title),
        message: l10n.moduleComingBody(phase),
      ),
    );
  }
}
