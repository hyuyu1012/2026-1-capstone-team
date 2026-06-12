import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_item.dart';
import '../../state/care_provider.dart';
import '../register_sheets.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
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

        // 일정 목록 — 등록된 약·식사 (탭 → 수정, 편집·삭제 아이콘).
        const SizedBox(height: 20),
        SectionHeader(label: '일정 목록', trailing: '${care.doneCount} / ${care.totalCount}'),
        _ScheduleList(items: items),
      ],
    );
  }
}

/// Tapping a schedule item: if it's not yet done, ask the guardian for the
/// completion time (시:분, defaulting to now) and mark it done at that time; if
/// it's already done, a tap just clears it. Cancelling the picker leaves the
/// item unchanged.
Future<void> toggleWithTime(BuildContext context, ScheduleItem item) async {
  final care = context.read<CareProvider>();
  if (item.taken) {
    await care.toggleItem(item.id); // 완료 해제 — 시각 입력 불필요
    return;
  }
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    initialEntryMode: TimePickerEntryMode.inputOnly,
    helpText: '완료 시간 입력',
  );
  if (picked == null) return; // 취소 — 그대로 둠
  final stamp = '${picked.hour.toString().padLeft(2, '0')}:'
      '${picked.minute.toString().padLeft(2, '0')}';
  await care.toggleItem(item.id, takenAt: stamp);
}

/// 항목을 건너뜀 토글한다. 새로 "건너뜀"으로 바꾸는 식사에 묶인 미완료 식후약이
/// 있으면, 그 약은 (식사 감지 없이) 예정 시간에 그대로 진행된다고 안내한다 —
/// 환자 앱의 "식사 스킵 → 식후약 시계 창" 동작과 일치하는 메시지.
void _skipWithHint(
    BuildContext context, List<ScheduleItem> items, ScheduleItem item) {
  final messenger = ScaffoldMessenger.of(context);
  final skippingOn = !item.skipped; // 현재 안 건너뛴 상태 → 이번 탭이 건너뜀 ON
  context.read<CareProvider>().skipItem(item.id);
  if (item.kind != ScheduleKind.meal || !skippingOn) return;
  final dependents = items
      .where((d) =>
          d.kind == ScheduleKind.med &&
          d.mealRelation == 'after' &&
          d.mealId == item.id &&
          !d.taken &&
          !d.skipped)
      .length;
  if (dependents == 0) return;
  messenger.showSnackBar(SnackBar(
    content: Text('이 식사의 식후약 $dependents개는 예정 시간에 그대로 진행돼요.'),
  ));
}

/// 등록된 일정을 patient 앱과 같은 타일 카드로 보여준다. 타일을 누르면 완료
/// 체크가 토글되고(위쪽 [_TodayGrid]와 동일한 toggleWithTime), 오른쪽
/// 건너뛰기·수정·삭제 아이콘으로 각 동작을 한다. 완료된 항목은 은은한 파란
/// 타일로 비춰 보여준다 (patient 앱과 동일한 표현).
class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.items});

  final List<ScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptySchedules();
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ScheduleTile(
            item: items[i],
            onToggle: () => toggleWithTime(context, items[i]),
            onSkip: () => _skipWithHint(context, items, items[i]),
            onEdit: () => ScheduleEditSheet.show(context, items[i]),
            onDelete: () => _confirmAndDelete(context, items[i]),
          ),
        ],
      ],
    );
  }
}

/// A single schedule tile (patient `_ScheduleTile` look): icon chip + name /
/// 약·용량 + scheduled(또는 완료) 시각, with trailing 건너뛰기·수정·삭제 아이콘.
/// The whole tile is tappable → 완료 체크 토글; the icon buttons sit above that
/// gesture so tapping 건너뛰기/수정/삭제 won't also toggle. A 건너뛴(skipped) item
/// turns grey with a "건너뜀" badge instead of its time.
class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.item,
    required this.onToggle,
    required this.onSkip,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleItem item;
  final VoidCallback onToggle;
  final VoidCallback onSkip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isMed = item.kind == ScheduleKind.med;
    final isSkipped = item.skipped;
    final isDone = item.taken && !isSkipped;
    final sub = [item.kind.label, if (item.dose != null) item.dose!].join(' · ');

    final chipBg = isSkipped
        ? AppColors.fillNeutral
        : isDone
            ? AppColors.primary
            : AppColors.primary08;
    final chipIcon = isSkipped
        ? AppColors.labelAlternative
        : isDone
            ? Colors.white
            : AppColors.primary;

    return Material(
      color: isDone ? AppColors.primary04 : AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDone ? AppColors.primary20 : AppColors.lineNormalNormal,
        ),
      ),
      child: InkWell(
        onTap: isSkipped ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isMed ? Icons.medication_outlined : Icons.restaurant_outlined,
                  size: 21,
                  color: chipIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.075,
                        color: isSkipped
                            ? AppColors.labelAlternative
                            : AppColors.labelStrong,
                        decoration:
                            isSkipped ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.labelAlternative,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.06,
                        color: AppColors.labelNeutral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSkipped)
                const _SkipBadge()
              else
                Text(
                  isDone && item.takenAt != null ? item.takenAt! : item.time,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.155,
                    color: isDone ? AppColors.primary78 : AppColors.labelStrong,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              const SizedBox(width: 2),
              _IconBtn(
                icon: isSkipped ? Icons.undo_rounded : Icons.skip_next_rounded,
                tooltip: isSkipped ? '건너뛰기 취소' : '오늘 건너뛰기',
                color: isSkipped
                    ? AppColors.primary
                    : AppColors.labelAlternative,
                onTap: onSkip,
              ),
              _IconBtn(
                icon: Icons.edit_outlined,
                tooltip: '수정',
                color: AppColors.labelAlternative,
                onTap: onEdit,
              ),
              _IconBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: '삭제',
                color: AppColors.statusNegative,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small grey "건너뜀" pill shown in place of the time for a skipped item.
class _SkipBadge extends StatelessWidget {
  const _SkipBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fillNeutral,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '건너뜀',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.06,
          color: AppColors.labelNeutral,
        ),
      ),
    );
  }
}

/// Placeholder when no schedules are registered yet (patient `_Empty` 톤).
class _EmptySchedules extends StatelessWidget {
  const _EmptySchedules();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineNormalNormal),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_note_outlined,
              size: 36, color: AppColors.labelAlternative),
          const SizedBox(height: 10),
          const Text(
            '아직 등록된 일정이 없어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.labelStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 + 버튼으로 약·식사 일정을 등록해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppColors.labelNeutral,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirm, then remove the item via the provider (surfacing failures).
Future<void> _confirmAndDelete(BuildContext context, ScheduleItem item) async {
  final messenger = ScaffoldMessenger.of(context);
  final care = context.read<CareProvider>();
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
  if (confirmed != true) return;
  try {
    await care.deleteItem(item.id);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
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