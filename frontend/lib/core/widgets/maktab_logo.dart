import 'package:flutter/material.dart';

import '../theme/maktab_colors.dart';
import 'mosque_mark.dart';

/// The Maktab mark: a mosque, with the wordmark beside it and optionally a second line such as the mosque's name.
class MaktabLogo extends StatelessWidget {
  const MaktabLogo({super.key, this.size = 40, this.showWordmark = true, this.onDark = false, this.subtitle});

  final double size;
  final bool showWordmark;
  final bool onDark;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : MaktabColors.primaryDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MosqueMark(size: size, color: onDark ? Colors.white : MaktabColors.primary),
        if (showWordmark) ...[
          SizedBox(width: size * 0.25),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maktab',
                  style: TextStyle(
                    fontSize: size * 0.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: size * 0.26, color: textColor.withValues(alpha: 0.8), height: 1.2),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
