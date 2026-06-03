import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/care_repository.dart';
import '../../models/schedule_item.dart';
import '../../state/care_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common.dart';
import '../../widgets/schedule_row.dart';

const List<String> _weekLabels = ['일', '월', '화', '수', '목', '금', '토'];

/// 기록 — month calendar (navigable) + the selected day's detailed schedule,
/// backed by the patient's dailyLogs in Firestore.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late int _year;
  late int _month;
  int? _selectedDate;
  MonthOverview? _overview;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final care = context.read<CareProvider>();
    final m = await care.monthOverview(_year, _month);
    if (!mounted) return;
    setState(() {
      _overview = m;
      _selectedDate = m.isCurrentMonth ? m.today : 1;
    });
  }

  bool get _atCurrentMonth {
    final now = DateTime.now();
    return _year == now.year && _month == now.month;
  }

  void _shiftMonth(int delta) {
    if (delta > 0 && _atCurrentMonth) return; // no future months (no data)
    var y = _year;
    var m = _month + delta;
    if (m < 1) {
      m = 12;
      y--;
    } else if (m > 12) {
      m = 1;
      y++;
    }
    setState(() {
      _year = y;
      _month = m;
      _overview = null;
      _selectedDate = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patient = care.patient;
    final month = _overview;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        PageHeader(
          title: '복용 기록을 확인하세요',
          subtitle: patient == null ? null : '${patient.relation} · ${patient.name}',
        ),

        // 달력 카드
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: month == null
              ? const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    _CalendarHeader(
                      label: month.label,
                      onPrev: () => _shiftMonth(-1),
                      onNext: _atCurrentMonth ? null : () => _shiftMonth(1),
                    ),
                    const SizedBox(height: 14),
                    _WeekdayRow(),
                    const SizedBox(height: 8),
                    _CalendarGrid(
                      month: month,
                      selected: _selectedDate ?? month.today,
                      onSelect: (d) => setState(() => _selectedDate = d),
                    ),
                    const SizedBox(height: 14),
                    const _Legend(),
                  ],
                ),
        ),

        // 선택일 상세
        if (month != null) ...[
          const SizedBox(height: 28),
          _DayDetail(
            care: care,
            month: month,
            selected: _selectedDate ?? month.today,
          ),
        ],
      ],
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.label, required this.onPrev, this.onNext});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left_rounded, AppColors.labelNeutral, onPrev),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.07, // -0.005em
              color: AppColors.labelStrong,
            ).tabular,
          ),
          _navButton(
            Icons.chevron_right_rounded,
            onNext == null ? AppColors.lineNormalNeutral : AppColors.labelAlternative,
            onNext,
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, Color color, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 20, color: color),
        ),
      );
}

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(
              _weekLabels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.42, // 0.04em
                color: i == 0 ? AppColors.statusCautionary : AppColors.labelAlternative,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.onSelect,
  });

  final MonthOverview month;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < month.firstWeekdayOffset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= month.daysInMonth; d++) {
      final isToday = month.isCurrentMonth && d == month.today;
      cells.add(_DateCell(
        day: d,
        value: month.completion[d - 1],
        today: isToday,
        future: d > month.today,
        selected: d == selected,
        onTap: d > month.today ? null : () => onSelect(d),
      ));
    }
    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.day,
    required this.value,
    required this.today,
    required this.future,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final double? value;
  final bool today;
  final bool future;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = value;
    Color bg = Colors.transparent;
    if (!future && v != null && v != 0) {
      if (v <= 0.34) {
        bg = AppColors.primary18;
      } else if (v <= 0.67) {
        bg = AppColors.primary40;
      } else if (v < 1) {
        bg = AppColors.primary68;
      } else {
        bg = AppColors.primary;
      }
    }
    final highFill = v != null && v > 0.5;
    final numColor = future
        ? AppColors.labelAlternative
        : highFill
            ? Colors.white
            : AppColors.labelStrong;

    final Border border = Border.all(
      color: (selected || today) ? AppColors.labelStrong : Colors.transparent,
      width: selected ? 2 : 1.5,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: (today || selected) ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: -0.065, // -0.005em
            color: numColor,
          ).tabular,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static const List<Color> _dots = [
    AppColors.fillAlternative,
    AppColors.primary18,
    AppColors.primary40, // 0.66 falls in the <=0.67 bucket
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
      ),
      child: Row(
        children: [
          const _LegendText('적음'),
          for (final c in _dots) ...[
            const SizedBox(width: 6),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
          ],
          const SizedBox(width: 6),
          const _LegendText('많음'),
        ],
      ),
    );
  }
}

class _LegendText extends StatelessWidget {
  const _LegendText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.21, // 0.02em
          color: AppColors.labelAlternative,
        ),
      );
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({
    required this.care,
    required this.month,
    required this.selected,
  });

  final CareProvider care;
  final MonthOverview month;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final dow = _weekLabels[(month.firstWeekdayOffset + selected - 1) % 7];
    final isToday = month.isCurrentMonth && selected == month.today;
    return FutureBuilder<List<ScheduleItem>>(
      future: care.dayDetail(month.year, month.month, selected),
      builder: (context, snap) {
        final day = snap.data ?? const <ScheduleItem>[];
        final done = day.where((d) => d.taken).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.07,
                          color: AppColors.labelStrong,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        children: [
                          TextSpan(text: '${month.month}월 $selected일 $dow요일'),
                          if (isToday)
                            const TextSpan(
                              text: '  오늘',
                              style: TextStyle(color: AppColors.primary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '$done / ${day.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.07,
                      color: AppColors.labelAlternative,
                    ).tabular,
                  ),
                ],
              ),
            ),
            if (day.isEmpty)
              const AppCard(
                radius: 14,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      '이 날의 기록이 없어요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.labelAlternative,
                      ),
                    ),
                  ),
                ),
              )
            else
              AppCard(
                radius: 14,
                clip: true,
                child: Column(
                  children: [
                    for (var i = 0; i < day.length; i++)
                      ScheduleRow(
                        item: day[i],
                        first: i == 0,
                        missed: !day[i].taken,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
