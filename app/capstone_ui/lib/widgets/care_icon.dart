import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/schedule_item.dart';

/// The pill / meal / check glyphs are inline SVGs in the handoff. Material has
/// no 1:1 match for the rotated-capsule pill or the fork-and-knife, so they're
/// reproduced here as a [CustomPainter] over the original 24×24 viewBox.
enum CareGlyph { med, meal, check }

class CareIcon extends StatelessWidget {
  const CareIcon(
    this.glyph, {
    super.key,
    this.size = 16,
    this.color = Colors.white,
    this.strokeWidth = 1.7,
  });

  // Can't be const: the glyph is chosen from [kind] at runtime.
  // ignore: prefer_const_constructors_in_immutables
  CareIcon.forKind(
    ScheduleKind kind, {
    Key? key,
    double size = 16,
    Color color = Colors.white,
    double strokeWidth = 1.7,
  }) : this(
          kind == ScheduleKind.med ? CareGlyph.med : CareGlyph.meal,
          key: key,
          size: size,
          color: color,
          strokeWidth: strokeWidth,
        );

  final CareGlyph glyph;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CareIconPainter(glyph, color, strokeWidth),
      ),
    );
  }
}

class _CareIconPainter extends CustomPainter {
  _CareIconPainter(this.glyph, this.color, this.strokeWidth);

  final CareGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything below is authored in the SVG's 24-unit space, then scaled.
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case CareGlyph.med:
        _paintMed(canvas, paint);
      case CareGlyph.meal:
        _paintMeal(canvas, paint);
      case CareGlyph.check:
        _paintCheck(canvas, paint);
    }
  }

  void _paintMed(Canvas canvas, Paint paint) {
    // Capsule rotated -30° about (12,12); split line drawn unrotated.
    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(-30 * math.pi / 180);
    canvas.translate(-12, -12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 9, 18, 6),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.restore();
    canvas.drawLine(const Offset(8.6, 7.4), const Offset(12.8, 14.7), paint);
  }

  void _paintMeal(Canvas canvas, Paint paint) {
    // Fork
    final fork = Path()
      ..moveTo(6, 3)
      ..lineTo(6, 11)
      ..arcToPoint(const Offset(9, 14), radius: const Radius.circular(3), clockwise: false)
      ..lineTo(9, 21);
    canvas.drawPath(fork, paint);
    canvas.drawLine(const Offset(9, 3), const Offset(9, 9), paint);
    // Knife
    final knife = Path()
      ..moveTo(15, 3)
      ..cubicTo(13.5, 3, 12, 4.5, 12, 7)
      ..cubicTo(12, 9.5, 13.5, 11, 15, 11)
      ..lineTo(15.5, 11)
      ..lineTo(15.5, 21)
      ..lineTo(18, 21)
      ..lineTo(18, 3)
      ..close();
    canvas.drawPath(knife, paint);
  }

  void _paintCheck(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(5, 12.5)
        ..lineTo(9.5, 17)
        ..lineTo(20, 7),
      paint..strokeWidth = 2.6,
    );
  }

  @override
  bool shouldRepaint(_CareIconPainter old) =>
      old.glyph != glyph || old.color != color || old.strokeWidth != strokeWidth;
}
