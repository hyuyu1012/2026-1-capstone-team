import 'schedule_item.dart';

/// One day's adherence record, stored at
/// `patients/{patientId}/dailyLogs/{yyyy-MM-dd}`. The patient sensor (and, as a
/// fallback, the 홈 toggle) writes these; 기록 / 통계 read them back.
///
/// Items are keyed by their schedule id in Firestore so a single dose can be
/// updated without rewriting the whole day:
/// `items: { "<scheduleId>": { kind, name, dose, time, taken, takenAt } }`.
class DailyLog {
  const DailyLog({required this.date, required this.items});

  final String date; // "2026-05-27"
  final List<ScheduleItem> items; // sorted by scheduled time

  int get total => items.length;
  int get done => items.where((i) => i.taken).length;

  /// 건너뛴(의도적 스킵) 항목을 제외한 완료율의 분모 — 스킵은 완료율을 깎지 않는다.
  int get _counted => items.where((i) => !i.skipped).length;

  /// 0..1 adherence for the day, or null when there are no (non-skipped) items.
  double? get completion => _counted == 0 ? null : done / _counted;

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    final raw = (map['items'] as Map<String, dynamic>?) ?? const {};
    final items = raw.entries.map((e) {
      final m = Map<String, dynamic>.from(e.value as Map);
      return ScheduleItem.fromMap({...m, 'id': e.key});
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return DailyLog(date: map['date'] as String? ?? '', items: items);
  }
}
