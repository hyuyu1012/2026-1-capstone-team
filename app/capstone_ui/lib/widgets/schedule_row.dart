import 'package:flutter/material.dart';

import '../models/schedule_item.dart';
import '../theme/app_colors.dart';

/// A checklist row: a circular checkbox + name + scheduled→actual time.
/// Shared by 홈 (tappable, pending = empty grey circle) and 기록 (static,
/// pending renders as a red ✕ "missed" state when [missed] is set).
class ScheduleRow extends StatelessWidget {
  const ScheduleRow({
    super.key,
    required this.item,
    required this.first,
    this.onTap,
    this.onLongPress,
    this.missed = false,
  });

  final ScheduleItem item;
  final bool first;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// When the item is not taken: `true` → missed (red ✕), `false` → pending.
  final bool missed;

  static const Color _strike = Color.fromRGBO(55, 56, 60, 0.32);

  @override
  Widget build(BuildContext context) {
    final taken = item.taken;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
      ),
      child: Row(
        children: [
          _Checkbox(taken: taken, missed: missed),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.0725, // -0.005em
                    color: taken ? AppColors.labelAlternative : AppColors.labelStrong,
                    decoration: taken ? TextDecoration.lineThrough : null,
                    decorationColor: _strike,
                    decorationThickness: 1,
                  ),
                ),
                const SizedBox(height: 2),
                _TimeLine(item: item),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null && onLongPress == null) return content;
    return InkWell(onTap: onTap, onLongPress: onLongPress, child: content);
  }
}

/// Scheduled time, plus `→ {actual}` (in primary) once taken.
class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.item});
  final ScheduleItem item;

  static const TextStyle _base = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0575, // 0.005em
    color: AppColors.labelAlternative,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(item.time, style: _base),
        if (item.taken && item.takenAt != null) ...[
          const SizedBox(width: 5),
          Text('→', style: _base.copyWith(fontSize: 10)),
          const SizedBox(width: 5),
          Text(
            item.takenAt!,
            style: _base.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.taken, required this.missed});
  final bool taken;
  final bool missed;

  @override
  Widget build(BuildContext context) {
    final borderColor = missed ? AppColors.red60 : AppColors.lineNormalNormal;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: taken ? AppColors.primary : Colors.transparent,
        border: taken ? null : Border.all(color: borderColor, width: 1.5),
      ),
      child: taken
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : missed
              ? const Icon(Icons.close_rounded, size: 13, color: AppColors.red60)
              : null,
    );
  }
}
