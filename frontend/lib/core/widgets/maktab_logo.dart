import 'package:flutter/material.dart';

import '../theme/maktab_colors.dart';

/// The Maktab mark: an open book inside a rounded tile, with the wordmark beside it.
class MaktabLogo extends StatelessWidget {
  const MaktabLogo({super.key, this.size = 40, this.showWordmark = true, this.onDark = false});

  final double size;
  final bool showWordmark;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : MaktabColors.tealDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onDark ? Colors.white.withValues(alpha: 0.12) : MaktabColors.teal,
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(color: MaktabColors.gold, width: 1.5),
          ),
          child: Icon(Icons.menu_book_rounded, color: Colors.white, size: size * 0.55),
        ),
        if (showWordmark) ...[
          SizedBox(width: size * 0.3),
          Text(
            'Maktab',
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
