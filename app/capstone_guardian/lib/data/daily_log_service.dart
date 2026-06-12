import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_log.dart';
import '../models/missed_item.dart';
import '../models/schedule_item.dart';
import 'care_repository.dart';

/// Reads/writes `patients/{patientId}/dailyLogs/{yyyy-MM-dd}` — the per-day
/// adherence history behind 기록 (calendar + day detail) and 통계 (week/month
/// averages + most-missed). The patient sensor is the primary writer; the 홈
/// toggle records into the same docs via [recordItemTaken].
class DailyLogService {
  DailyLogService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _logs(String patientId) =>
      _db.collection('patients').doc(patientId).collection('dailyLogs');

  /// Doc id for a calendar day, e.g. (2026, 5, 7) -> "2026-05-07".
  static String dateId(int year, int month, int day) =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  static int _daysIn(int year, int month) => DateTime(year, month + 1, 0).day;

  /// All logs for a calendar month, queried by the yyyy-MM-dd doc-id range.
  Future<List<DailyLog>> logsForMonth(String patientId, int year, int month) async {
    final snap = await _logs(patientId)
        .where(FieldPath.documentId,
            isGreaterThanOrEqualTo: dateId(year, month, 1))
        .where(FieldPath.documentId,
            isLessThanOrEqualTo: dateId(year, month, _daysIn(year, month)))
        .get();
    return snap.docs
        .map((d) => DailyLog.fromMap({...d.data(), 'date': d.id}))
        .toList();
  }

  /// A single day's record, or null if the sensor hasn't logged that day.
  Future<DailyLog?> logForDay(String patientId, int year, int month, int day) async {
    final doc = await _logs(patientId).doc(dateId(year, month, day)).get();
    if (!doc.exists) return null;
    return DailyLog.fromMap({...doc.data()!, 'date': doc.id});
  }

  /// Calendar metadata + per-day completion for the 기록 month grid. [now] is
  /// the real clock; it decides which days are "future" (null) and whether this
  /// is the current month (drives the 오늘 marker).
  Future<MonthOverview> monthOverview(
      String patientId, int year, int month, DateTime now) async {
    final logs = await logsForMonth(patientId, year, month);
    final byDay = {
      for (final l in logs) int.parse(l.date.split('-')[2]): l,
    };
    final days = _daysIn(year, month);
    final completion = <double?>[
      for (var d = 1; d <= days; d++) byDay[d]?.completion,
    ];

    final isCurrentMonth = now.year == year && now.month == month;
    final firstOfMonth = DateTime(year, month, 1);
    // today: real day if current month; daysInMonth for a past month (nothing
    // future); 0 for a future month (everything future).
    final today = isCurrentMonth
        ? now.day
        : (firstOfMonth.isAfter(DateTime(now.year, now.month, now.day)) ? 0 : days);

    return MonthOverview(
      label: '$year년 $month월',
      year: year,
      month: month,
      completion: completion,
      today: today,
      isCurrentMonth: isCurrentMonth,
      firstWeekdayOffset: firstOfMonth.weekday % 7, // Sun=0
      daysInMonth: days,
    );
  }

  /// 통계 — most-missed items for a month, descending by miss count. Total is
  /// the number of days that actually have a log (the elapsed denominator).
  Future<List<MissedItem>> missedItems(String patientId, int year, int month) async {
    final logs = await logsForMonth(patientId, year, month);
    final elapsed = logs.length;
    final counts = <String, int>{}; // "name|time" -> missed days
    for (final log in logs) {
      for (final it in log.items) {
        // 건너뛴 항목은 의도적 스킵이므로 누락으로 집계하지 않는다.
        if (!it.taken && !it.skipped) {
          final key = '${it.name}|${it.time}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    final result = counts.entries.map((e) {
      final parts = e.key.split('|');
      return MissedItem(
          name: parts[0], time: parts[1], missed: e.value, total: elapsed);
    }).toList()
      ..sort((a, b) => b.missed.compareTo(a.missed));
    return result.take(4).toList();
  }

  static Map<String, dynamic> _itemMap(ScheduleItem i) => {
        'kind': i.kind.name,
        'name': i.name,
        'dose': i.dose,
        'time': i.time,
        'taken': i.taken,
        'takenAt': i.takenAt,
        'skipped': i.skipped,
      };

  /// Record a full day's schedule snapshot (the 홈 toggle path). Writes every
  /// item so the day's total/completion matches what 홈 shows. Merges, so a
  /// concurrent sensor write to other fields is preserved.
  Future<void> recordDay(
      String patientId, String dateId, List<ScheduleItem> items) {
    return _logs(patientId).doc(dateId).set({
      'date': dateId,
      'items': {for (final i in items) i.id: _itemMap(i)},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> hasAnyLogs(String patientId) async {
    final snap = await _logs(patientId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  // --- Demo seeding ---------------------------------------------------------

  /// Generic 3-dose template used for the dummy history. Names are intentionally
  /// generic (no real drug names) per the demo spec.
  static const List<List<String>> _seedDefs = [
    ['m-morning', '아침약', '08:00'],
    ['m-lunch', '점심약', '12:30'],
    ['m-evening', '저녁약', '20:00'],
  ];

  /// Seed dummy adherence for the month *before* [now] (a full month) plus the
  /// elapsed days of the current month, so 기록/통계 have history to show on a
  /// fresh account. Idempotent: no-op once any log exists.
  Future<void> seedDummy(String patientId, DateTime now) async {
    if (await hasAnyLogs(patientId)) return;

    final batch = _db.batch();
    void seedDay(int year, int month, int day) {
      // Deterministic variety: most days full, some 2/3, occasional 1/3.
      final int takenCount = day % 7 == 0 ? 1 : (day % 3 == 0 ? 2 : 3);
      final items = <String, dynamic>{};
      for (var i = 0; i < _seedDefs.length; i++) {
        final taken = i < takenCount; // evening (last) is missed first
        final time = _seedDefs[i][2];
        items[_seedDefs[i][0]] = {
          'kind': 'med',
          'name': _seedDefs[i][1],
          'dose': '1정',
          'time': time,
          'taken': taken,
          'takenAt': taken ? _drift(time, day, i) : null,
        };
      }
      batch.set(_logs(patientId).doc(dateId(year, month, day)), {
        'date': dateId(year, month, day),
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Previous month, in full.
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    for (var d = 1; d <= _daysIn(prevYear, prevMonth); d++) {
      seedDay(prevYear, prevMonth, d);
    }
    // Current month up to (but not including) today — today fills via live use.
    for (var d = 1; d < now.day; d++) {
      seedDay(now.year, now.month, d);
    }
    await batch.commit();
  }

  /// Small deterministic minute drift around the scheduled time, so the seeded
  /// takenAt values look organic in the 기록 day detail.
  static String _drift(String hhmm, int day, int idx) {
    final parts = hhmm.split(':');
    final base = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final mins = (base + ((day * 7 + idx * 13) % 17) - 4).clamp(0, 24 * 60 - 1);
    final hh = (mins ~/ 60).toString().padLeft(2, '0');
    final mm = (mins % 60).toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
