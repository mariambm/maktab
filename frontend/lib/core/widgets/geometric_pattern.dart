import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A faint tiling of eight-pointed stars, the one decorative Islamic motif in the app. Used on the login header only.
class GeometricPattern extends StatelessWidget {
  const GeometricPattern({super.key, required this.color, this.tileSize = 56});

  final Color color;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter(color: color, tileSize: tileSize), size: Size.infinite);
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.color, required this.tileSize});

  final Color color;
  final double tileSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final half = tileSize * 0.3;
    for (double y = 0; y < size.height + tileSize; y += tileSize) {
      for (double x = 0; x < size.width + tileSize; x += tileSize) {
        final center = Offset(x, y);
        canvas.drawRect(Rect.fromCenter(center: center, width: half * 2, height: half * 2), paint);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color || oldDelegate.tileSize != tileSize;
}
