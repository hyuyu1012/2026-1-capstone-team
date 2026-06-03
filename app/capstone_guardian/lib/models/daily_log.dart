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

  /// 0..1 adherence for the day, or null when there are no items.
  double? get completion => total == 0 ? null : done / total;

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
