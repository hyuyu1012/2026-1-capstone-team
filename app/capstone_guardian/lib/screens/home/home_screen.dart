import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_item.dart';
import '../../state/care_provider.dart';
import '../register_sheets.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_icon.dart';
import '../../widgets/common.dart';
import '../../widgets/schedule_row.dart';
import 'today_ring.dart';

/// 홈 — today's adherence at a glance: 24h ring, 6-cell grid, schedule checklist.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final items = care.todayItems;
    final patient = care.patient;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        PageHeader(
          title: '오늘 현황을 확인하세요',
          subtitle: patient == null ? null : '${patient.relation} · ${patient.name}',
        ),

        // 한눈에 보기 — 24h ring.
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardLabel('한눈에 보기'),
              const SizedBox(height: 4),
              TodayRing(items: items),
            ],
          ),
        ),

        // 오늘 일정 — 6-cell grid.
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardLabel('오늘 일정'),
              const SizedBox(height: 16),
              _TodayGrid(items: items, onToggle: care.toggleItem),
            ],
          ),
        ),

        // 복용 일정 — list.
        const SizedBox(height: 20),
        SectionHeader(label: '복용 일정', trailing: '${care.doneCount} / ${care.totalCount}'),
        _ScheduleList(items: items),
      ],
    );
  }
}

/// Swipe-to-delete checklist of today's items. Stateful so a per-minute ticker
/// can re-flag items whose scheduled time has passed (overdue → red), matching
/// the live "지금" hand on [TodayRing].
class _ScheduleList extends StatefulWidget {
  const _ScheduleList({required this.items});

  final List<ScheduleItem> items;

  @override
  State<_ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<_ScheduleList> {
  late DateTime _now;
  Timer? _timer;

  int get _nowMin => _now.hour * 60 + _now.minute;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleTick();
  }

  /// Refresh on the next minute boundary, then every minute after.
  void _scheduleTick() {
    final next = DateTime(_now.year, _now.month, _now.day, _now.hour, _now.minute)
        .add(const Duration(minutes: 1));
    _timer = Timer(next.difference(_now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final items = widget.items;
    return AppCard(
      radius: 14,
      clip: true,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Dismissible(
              key: ValueKey(items[i].id),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              confirmDismiss: (_) => _confirmDelete(context, items[i]),
              onDismissed: (_) => _deleteItem(context, items[i].id),
              child: ScheduleRow(
                item: items[i],
                first: i == 0,
                overdue: !items[i].taken && items[i].scheduledMinutes < _nowMin,
                onTap: () => care.toggleItem(items[i].id),
                onLongPress: () => ScheduleEditSheet.show(context, items[i]),
              ),
            ),
        ],
      ),
    );
  }

  /// Confirmation dialog before removing a schedule item.
  Future<bool> _confirmDelete(BuildContext context, ScheduleItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('"${item.name}" 일정을 삭제할까요?\n환자 앱에서도 더 이상 표시되지 않아요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.statusNegative),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Removes the item via the provider and surfaces failures.
  Future<void> _deleteItem(BuildContext context, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<CareProvider>().deleteItem(id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }
}

/// Red trailing panel revealed while swiping a schedule row left.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.statusNegative,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.15, // 0.1em
        color: AppColors.labelNeutral,
      ),
    );
  }
}

/// Square toggle cells, one per schedule item (home.jsx `TodayGrid`).
class _TodayGrid extends StatelessWidget {
  const _TodayGrid({required this.items, required this.onToggle});

  final List<ScheduleItem> items;
  final Future<void> Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _Cell(item: items[i], onTap: () => onToggle(items[i].id))),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.item, required this.onTap});

  final ScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taken = item.taken;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: taken ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: taken
                ? null
                : Border.all(color: AppColors.lineNormalNormal, width: 1.5),
            boxShadow: taken
                ? const [BoxShadow(color: AppColors.primary18, blurRadius: 6, offset: Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: CareIcon.forKind(
            item.kind,
            size: 16,
            strokeWidth: 1.7,
            color: taken ? Colors.white : AppColors.labelAlternative,
          ),
        ),
      ),
    );
  }
}
