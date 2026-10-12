import 'package:flutter/material.dart';

/// A simple mosque: a central dome with a crescent, two minarets and an arched door. Drawn rather than an image, so
/// it stays sharp at any size and takes the colour it is given.
class MosqueMark extends StatelessWidget {
  const MosqueMark({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _MosquePainter(color: color),
  );
}

/// A wide, faint mosque skyline for backgrounds: the mark with two smaller domes beside it.
class MosqueSkyline extends StatelessWidget {
  const MosqueSkyline({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SkylinePainter(color: color),
    size: Size.infinite,
  );
}

class _MosquePainter extends CustomPainter {
  _MosquePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    drawMosque(canvas, Offset.zero & size, color, door: true);
  }

  @override
  bool shouldRepaint(_MosquePainter old) => old.color != color;
}

class _SkylinePainter extends CustomPainter {
  _SkylinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final main = height * 0.95;
    final side = main * 0.62;
    final centre = size.width / 2;
    final paint = Paint()..color = color;
    // Two smaller domed halls, then the main mosque in front of them.
    for (final dx in [-main * 0.78, main * 0.78]) {
      _dome(canvas, Rect.fromLTWH(centre + dx - side / 2, height - side, side, side), paint);
    }
    drawMosque(canvas, Rect.fromLTWH(centre - main / 2, height - main, main, main), color, door: false);
    canvas.drawRect(Rect.fromLTWH(0, height - height * 0.03, size.width, height * 0.03), paint);
  }

  void _dome(Canvas canvas, Rect r, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(r.left + r.width * 0.12, r.top + r.height * 0.5, r.width * 0.76, r.height * 0.5),
      paint,
    );
    final dome = Path()
      ..moveTo(r.left + r.width * 0.16, r.top + r.height * 0.52)
      ..cubicTo(
        r.left + r.width * 0.14,
        r.top + r.height * 0.22,
        r.left + r.width * 0.42,
        r.top + r.height * 0.2,
        r.left + r.width * 0.5,
        r.top + r.height * 0.06,
      )
      ..cubicTo(
        r.left + r.width * 0.58,
        r.top + r.height * 0.2,
        r.left + r.width * 0.86,
        r.top + r.height * 0.22,
        r.left + r.width * 0.84,
        r.top + r.height * 0.52,
      )
      ..close();
    canvas.drawPath(dome, paint);
  }

  @override
  bool shouldRepaint(_SkylinePainter old) => old.color != color;
}

/// Draws the mosque inside [r]. With [door], an arched doorway is cut out of the hall.
void drawMosque(Canvas canvas, Rect r, Color color, {required bool door}) {
  final paint = Paint()..color = color;
  double x(double f) => r.left + r.width * f;
  double y(double f) => r.top + r.height * f;

  canvas.saveLayer(r.inflate(2), Paint());
  // Hall.
  canvas.drawRect(Rect.fromLTRB(x(0.24), y(0.58), x(0.76), y(1)), paint);
  // Onion dome with a short drum under it.
  canvas.drawRect(Rect.fromLTRB(x(0.3), y(0.52), x(0.7), y(0.6)), paint);
  final dome = Path()
    ..moveTo(x(0.29), y(0.54))
    ..cubicTo(x(0.22), y(0.36), x(0.42), y(0.3), x(0.5), y(0.16))
    ..cubicTo(x(0.58), y(0.3), x(0.78), y(0.36), x(0.71), y(0.54))
    ..close();
  canvas.drawPath(dome, paint);
  // Finial and crescent.
  canvas.drawRect(Rect.fromLTRB(x(0.49), y(0.09), x(0.51), y(0.17)), paint);
  final crescent = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: Offset(x(0.5), y(0.07)), radius: r.width * 0.045)),
    Path()..addOval(Rect.fromCircle(center: Offset(x(0.52), y(0.06)), radius: r.width * 0.038)),
  );
  canvas.drawPath(crescent, paint);
  // Minarets with pointed caps.
  for (final left in [0.08, 0.84]) {
    canvas.drawRect(Rect.fromLTRB(x(left), y(0.34), x(left + 0.08), y(1)), paint);
    canvas.drawRect(Rect.fromLTRB(x(left - 0.015), y(0.42), x(left + 0.095), y(0.45)), paint);
    final cap = Path()
      ..moveTo(x(left - 0.005), y(0.35))
      ..lineTo(x(left + 0.04), y(0.22))
      ..lineTo(x(left + 0.085), y(0.35))
      ..close();
    canvas.drawPath(cap, paint);
  }
  if (door) {
    final arch = Path()
      ..moveTo(x(0.42), y(1))
      ..lineTo(x(0.42), y(0.8))
      ..quadraticBezierTo(x(0.42), y(0.7), x(0.5), y(0.68))
      ..quadraticBezierTo(x(0.58), y(0.7), x(0.58), y(0.8))
      ..lineTo(x(0.58), y(1))
      ..close();
    canvas.drawPath(arch, Paint()..blendMode = BlendMode.clear);
  }
  canvas.restore();
}
