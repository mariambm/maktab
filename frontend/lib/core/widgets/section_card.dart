import 'package:flutter/material.dart';

import '../theme/maktab_spacing.dart';

/// A titled card used to group information on detail screens, with an optional action in the header.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children, this.action});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.sm, MaktabSpacing.sm, MaktabSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: MaktabSpacing.touchTarget),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                  ?action,
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A label and value row inside a [SectionCard].
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: MaktabSpacing.sm, bottom: MaktabSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// A status label with icon and text, so status is never shown by colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.icon, this.muted = false});

  final String label;
  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: muted ? scheme.onSurfaceVariant : scheme.primary),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: muted ? scheme.surfaceContainerHighest : scheme.primaryContainer,
      side: BorderSide.none,
    );
  }
}
