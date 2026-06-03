import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/schedule_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/care_icon.dart';

/// 24-hour ring (home.jsx `TodayRing`): a track + a 0h→now progress arc, hour
/// ticks, a "now" dot, and one marker per medication positioned at the time it
/// was taken (or is scheduled). "Now" is the prototype's fixed 16:30.
class TodayRing extends StatelessWidget {
  const TodayRing({super.key, required this.items});

  final List<ScheduleItem> items;

  static const double _size = 220;
  static const double _r = 88;
  static const double _cx = _size / 2;
  static const double _cy = _size / 2;
  static const int _nowMin = 16 * 60 + 30; // 16:30

  static Offset _polar(num minutes, double radius) {
    final deg = (minutes / (24 * 60)) * 360 - 90;
    final a = deg * math.pi / 180;
    return Offset(_cx + math.cos(a) * radius, _cy + math.sin(a) * radius);
  }

  @override
  Widget build(BuildContext context) {
    final meds = items.where((i) => i.kind == ScheduleKind.med).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Arc, track, ticks, now-dot, markers.
              CustomPaint(
                size: const Size(_size, _size),
                painter: _RingPainter(meds),
              ),

              // Pill glyphs centered over each medication marker.
              for (final m in meds) _pillOverlay(m),

              // Center "지금" + time.
              const Positioned.fill(child: _CenterLabel()),

              // Outer hour labels — anchored per quadrant like the CSS transforms.
              _hourLabel(0, const Offset(-0.5, -1.0)),
              _hourLabel(6, const Offset(0, -0.5)),
              _hourLabel(12, const Offset(-0.5, 0)),
              _hourLabel(18, const Offset(-1.0, -0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillOverlay(ScheduleItem m) {
    final overdue = !m.taken && m.scheduledMinutes < _nowMin;
    final pos = _polar(m.markerMinutes, _r);
    final color = m.taken
        ? Colors.white
        : overdue
            ? AppColors.statusCautionary
            : AppColors.labelAlternative;
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: CareIcon(CareGlyph.med, size: 11, color: color, strokeWidth: 1.8),
      ),
    );
  }

  Widget _hourLabel(int hour, Offset anchor) {
    final pos = _polar(hour * 60, _r + 6);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: FractionalTranslation(
        translation: anchor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            '$hour시',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppColors.labelAlternative,
            ).tabular,
          ),
        ),
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '지금',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.95, // 0.1em
            color: AppColors.labelNeutral,
          ),
        ),
        SizedBox(height: 2),
        Text(
          '16:30',
          style: TextStyle(
            fontFamily: AppType.displayFamily,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.52, // -0.02em
            height: 1,
            color: AppColors.labelStrong,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.meds);

  final List<ScheduleItem> meds;

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(TodayRing._cx, TodayRing._cy);
    final rect = Rect.fromCircle(center: center, radius: TodayRing._r);

    // Track.
    canvas.drawCircle(
      center,
      TodayRing._r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = AppColors.fillAlternative,
    );

    // Progress arc 0h → now (rounded caps).
    const start = -math.pi / 2; // top
    final sweep = (TodayRing._nowMin / (24 * 60)) * 2 * math.pi;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary20,
    );

    // Hour ticks every 3h.
    final tickPaint = Paint()
      ..color = AppColors.lineNormalNormal
      ..strokeWidth = 1;
    for (final h in const [0, 3, 6, 9, 12, 15, 18, 21]) {
      final p1 = TodayRing._polar(h * 60, TodayRing._r + 6);
      final p2 = TodayRing._polar(h * 60, TodayRing._r + 11);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Now indicator.
    final now = TodayRing._polar(TodayRing._nowMin, TodayRing._r);
    canvas.drawCircle(now, 4.5, Paint()..color = AppColors.labelStrong);

    // Medication markers.
    for (final m in meds) {
      final overdue = !m.taken && m.scheduledMinutes < TodayRing._nowMin;
      final pos = TodayRing._polar(m.markerMinutes, TodayRing._r);
      canvas.drawCircle(
        pos,
        12,
        Paint()..color = m.taken ? AppColors.primary : Colors.white,
      );
      if (!m.taken) {
        canvas.drawCircle(
          pos,
          12,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = overdue ? AppColors.statusCautionary : AppColors.lineNormalNormal,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.meds != meds;
}
