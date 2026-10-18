import 'package:flutter/material.dart';

import '../theme/maktab_spacing.dart';

/// A large figure with its label, as on the dashboard and the reports. A figure that signals a problem carries an
/// [icon] as well as its colour, so it never relies on colour alone.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, required this.color, this.icon, this.onTap});

  final String value;
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: MaktabSpacing.md, horizontal: MaktabSpacing.sm),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, color: color, size: 22), const SizedBox(width: 4)],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MaktabSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays figures out side by side: as many per row as fit at [minWidth], sharing the width, at most 180 wide each.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.tiles, this.minWidth = 104});

  final List<Widget> tiles;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = MaktabSpacing.sm;
        final fit = ((constraints.maxWidth + gap) / (minWidth + gap)).floor().clamp(1, tiles.length);
        final width = ((constraints.maxWidth - gap * (fit - 1)) / fit).clamp(0.0, 180.0);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
        );
      },
    );
  }
}
