import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/missed_item.dart';
import '../../state/care_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common.dart';

/// 통계 — weekly bars, a monthly area chart, and most-missed items.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final month = care.month;
    final patient = care.patient;
    if (month == null) return const SizedBox.shrink();

    // 이번 주: 오늘이 포함된 월~일. value = completion[date-1].
    final today = month.today;
    final todayDate = DateTime(month.year, month.month, today);
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final week = <_Day>[];
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final inMonth = d.year == month.year && d.month == month.month;
      week.add(_Day(
        label: const ['월', '화', '수', '목', '금', '토', '일'][i],
        value: inMonth ? month.completion[d.day - 1] : null,
        isToday: inMonth && d.day == today,
      ));
    }
    final weekVals = week.map((d) => d.value).whereType<double>().toList();
    final weekAvg = weekVals.isEmpty ? 0.0 : weekVals.reduce((a, b) => a + b) / weekVals.length;

    final monthVals = month.completion.whereType<double>().toList();
    final monthAvg = monthVals.isEmpty ? 0.0 : monthVals.reduce((a, b) => a + b) / monthVals.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        PageHeader(
          title: '복용 패턴을 살펴보세요',
          subtitle: patient == null ? null : '${patient.relation} · ${patient.name}',
        ),

        // 이번 주
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _CardHeader(label: '이번 주', value: '주평균 ${(weekAvg * 100).round()}%'),
              const SizedBox(height: 18),
              _WeeklyBars(week: week),
            ],
          ),
        ),

        // 이번 달
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _CardHeader(label: '이번 달', value: '월평균 ${(monthAvg * 100).round()}%'),
              const SizedBox(height: 18),
              SizedBox(
                height: 150,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MonthlyAreaPainter(
                      month.completion, month.today, month.daysInMonth),
                ),
              ),
            ],
          ),
        ),

        // 자주 누락한 항목
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text('자주 누락한 항목', style: AppType.sectionLabel),
        ),
        AppCard(
          radius: 14,
          clip: true,
          child: Column(
            children: [
              for (var i = 0; i < care.missed.length; i++)
                _MissedRow(item: care.missed[i], first: i == 0, maxMissed: _maxMissed(care.missed)),
            ],
          ),
        ),
      ],
    );
  }

  int _maxMissed(List<MissedItem> items) =>
      items.isEmpty ? 1 : items.map((i) => i.missed).reduce((a, b) => a > b ? a : b);
}

class _Day {
  const _Day({required this.label, required this.value, this.isToday = false});
  final String label;
  final double? value;
  final bool isToday;
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppType.sectionLabel),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.0625, // -0.005em
            color: AppColors.labelStrong,
          ).tabular,
        ),
      ],
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.week});
  final List<_Day> week;

  static const double _h = 130;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < week.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _Bar(day: week[i])),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < week.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  week[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: week[i].isToday ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.44, // 0.04em
                    color: week[i].isToday ? AppColors.labelStrong : AppColors.labelAlternative,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day});
  final _Day day;

  @override
  Widget build(BuildContext context) {
    final v = day.value;
    final hasValue = v != null;
    final heightFactor = hasValue ? (v.clamp(0.04, 1.0)) : null;

    return SizedBox(
      height: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // baseline
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(height: 1, width: double.infinity, child: ColoredBox(color: AppColors.lineNormalNeutral)),
          ),
          if (hasValue)
            FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: heightFactor,
              child: Container(
                width: 18,
                decoration: BoxDecoration(
                  color: day.isToday ? AppColors.primary : AppColors.primary32,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
          else
            Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fillAlternative,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          if (day.isToday && hasValue)
            Positioned(
              bottom: _WeeklyBars._h * heightFactor! + 6,
              child: Text(
                '${(v * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.21,
                  color: AppColors.primary,
                ).tabular,
              ),
            ),
        ],
      ),
    );
  }
}

class _MissedRow extends StatelessWidget {
  const _MissedRow({required this.item, required this.first, required this.maxMissed});
  final MissedItem item;
  final bool first;
  final int maxMissed;

  @override
  Widget build(BuildContext context) {
    final widthPct = item.missed / maxMissed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: item.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.0675,
                          color: AppColors.labelStrong,
                        ),
                      ),
                      TextSpan(
                        text: '  ${item.time}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.22,
                          color: AppColors.labelNeutral,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.missed}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.0625,
                        color: AppColors.red60,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: ' / ${item.total}일',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.labelAlternative,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 4,
              color: AppColors.fillAlternative,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widthPct,
                child: Container(color: AppColors.red60),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly adherence area chart (stats.jsx `MonthlyArea`).
class _MonthlyAreaPainter extends CustomPainter {
  _MonthlyAreaPainter(this.data, this.today, this.daysInMonth);

  final List<double?> data;
  final int today;
  final int daysInMonth;

  static const double _padT = 8;
  static const double _padB = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width;
    final chartH = size.height - _padT - _padB;
    final n = data.length;
    double xOf(int i) => (i / (n - 1)) * chartW;
    double yOf(double v) => _padT + (1 - v) * chartH;

    final points = <MapEntry<int, double>>[
      for (var i = 0; i < n; i++)
        if (data[i] != null) MapEntry(i, data[i]!),
    ];
    if (points.isEmpty) return;

    // Horizontal grids at 0 / 50 / 100% (0 solid, others dashed).
    final gridPaint = Paint()
      ..color = AppColors.lineNormalNeutral
      ..strokeWidth = 1;
    for (final g in const [0.0, 0.5, 1.0]) {
      final y = yOf(g);
      if (g == 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      } else {
        _dashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint, 3, 3);
      }
    }

    // Line path.
    final line = Path()..moveTo(xOf(points.first.key), yOf(points.first.value));
    for (var k = 1; k < points.length; k++) {
      line.lineTo(xOf(points[k].key), yOf(points[k].value));
    }

    // Area fill (gradient).
    final area = Path.from(line)
      ..lineTo(xOf(points.last.key), _padT + chartH)
      ..lineTo(xOf(points.first.key), _padT + chartH)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(0, 102, 255, 0.28), Color.fromRGBO(0, 102, 255, 0.02)],
        ).createShader(Rect.fromLTWH(0, _padT, size.width, chartH)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );

    // Today marker.
    final todayIdx = today - 1;
    if (todayIdx >= 0 && todayIdx < n && data[todayIdx] != null) {
      final tv = data[todayIdx]!;
      final tx = xOf(todayIdx);
      _dashedLine(canvas, Offset(tx, yOf(tv)), Offset(tx, _padT + chartH),
          Paint()..color = AppColors.labelStrong..strokeWidth = 1, 2, 3);
      canvas.drawCircle(Offset(tx, yOf(tv)), 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(tx, yOf(tv)),
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.labelStrong,
      );
    }

    // X labels.
    final ticks = {1, 8, 15, 22, today, daysInMonth}.toList()..sort();
    for (final d in ticks) {
      final isToday = d == today;
      _text(
        canvas,
        '$d일',
        Offset(xOf(d - 1), size.height - 16),
        fontSize: 10,
        weight: isToday ? FontWeight.w700 : FontWeight.w500,
        color: isToday ? AppColors.labelStrong : AppColors.labelAlternative,
        align: TextAlign.center,
      );
    }

    // Y labels (right edge).
    for (final g in const [0.0, 0.5, 1.0]) {
      _text(
        canvas,
        '${(g * 100).round()}%',
        Offset(size.width, yOf(g) - 14),
        fontSize: 9,
        weight: FontWeight.w500,
        color: AppColors.labelAlternative,
        align: TextAlign.right,
        anchorRight: true,
      );
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint, double on, double off) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var dist = 0.0;
    while (dist < total) {
      final start = a + dir * dist;
      final end = a + dir * (dist + on).clamp(0, total);
      canvas.drawLine(start, end, paint);
      dist += on + off;
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset pos, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
    TextAlign align = TextAlign.left,
    bool anchorRight = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppType.family,
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: 0.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = pos.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    if (anchorRight) dx -= tp.width;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(_MonthlyAreaPainter old) =>
      old.data != data || old.today != today || old.daysInMonth != daysInMonth;
}
