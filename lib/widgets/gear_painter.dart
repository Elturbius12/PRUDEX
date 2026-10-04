import 'dart:math';
import 'package:flutter/material.dart';

/// Pinta tres engranajes entrelazados que giran, estilo "La cerradura".
class GearPainter extends CustomPainter {
  final double rotation;
  final double progress;
  final Color color1;
  final Color color2;
  final Color color3;

  GearPainter({
    required this.rotation,
    required this.progress,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Tres engranajes con diferentes posiciones, tamaños y direcciones
    _drawGear(canvas, Offset(cx - 70, cy - 10), 52, 12, rotation, color1, progress);
    _drawGear(canvas, Offset(cx + 55, cy - 30), 40, 10, -rotation * 1.3, color2, progress);
    _drawGear(canvas, Offset(cx + 10, cy + 50), 34, 8, rotation * 1.625, color3, progress);

    // Conexiones sutiles entre engranajes
    if (progress > 0.3) {
      final linePaint = Paint()
        ..color = color1.withAlpha((progress * 40).toInt())
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(cx - 70 + 52, cy - 10),
        Offset(cx + 55 - 40, cy - 30),
        linePaint,
      );
    }
  }

  void _drawGear(Canvas canvas, Offset center, double outerR, int teeth,
      double rot, Color color, double prog) {
    final innerR = outerR * 0.72;
    final toothDepth = outerR * 0.18;
    final holeR = outerR * 0.3;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    // Cuerpo del engranaje
    final bodyPaint = Paint()
      ..color = color.withAlpha((150 + prog * 105).toInt().clamp(0, 255))
      ..style = PaintingStyle.fill;

    final path = Path();
    final angleStep = 2 * pi / teeth;
    for (int i = 0; i < teeth; i++) {
      final a0 = i * angleStep;
      final a1 = a0 + angleStep * 0.15;
      final a2 = a0 + angleStep * 0.35;
      final a3 = a0 + angleStep * 0.5;
      final a4 = a0 + angleStep * 0.65;
      final a5 = a0 + angleStep * 0.85;

      if (i == 0) {
        path.moveTo(innerR * cos(a0), innerR * sin(a0));
      }
      path.lineTo(innerR * cos(a1), innerR * sin(a1));
      path.lineTo((innerR + toothDepth) * cos(a2), (innerR + toothDepth) * sin(a2));
      path.lineTo((innerR + toothDepth) * cos(a3), (innerR + toothDepth) * sin(a3));
      path.lineTo((innerR + toothDepth) * cos(a4), (innerR + toothDepth) * sin(a4));
      path.lineTo(innerR * cos(a5), innerR * sin(a5));
      path.lineTo(innerR * cos(a0 + angleStep), innerR * sin(a0 + angleStep));
    }
    path.close();
    canvas.drawPath(path, bodyPaint);

    // Borde del engranaje
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Agujero central
    final holePaint = Paint()
      ..color = const Color(0xFF0D1517)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, holeR, holePaint);

    // Borde del agujero
    canvas.drawCircle(
      Offset.zero,
      holeR,
      Paint()
        ..color = color.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cruz central
    final crossPaint = Paint()
      ..color = color.withAlpha(100)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cr = holeR * 0.55;
    canvas.drawLine(Offset(-cr, 0), Offset(cr, 0), crossPaint);
    canvas.drawLine(Offset(0, -cr), Offset(0, cr), crossPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(GearPainter old) =>
      old.rotation != rotation || old.progress != progress;
}
