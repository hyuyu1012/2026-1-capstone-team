import '../models/med.dart';
import '../models/missed_item.dart';
import '../models/patient.dart';
import '../models/schedule_item.dart';
import 'care_repository.dart';

/// In-memory [CareRepository] holding the exact sample data from
/// `screens/prototype/shared.jsx`. A small artificial delay simulates network
/// latency so the loading states behave like the eventual Firebase backend.
class MockCareRepository implements CareRepository {
  static const Duration _latency = Duration(milliseconds: 250);

  static const Patient _patient = Patient(
    id: 'mock-patient',
    name: '이순자',
    relation: '어머니',
    birthYear: 1947,
    birthMonth: 6,
    birthDay: 15,
    gender: 'female',
    guardianIds: ['mock-guardian'],
    inviteCode: 'ABC123',
  );

  static const int today = 27;
  static const String monthLabel = '2026년 5월';
  static const int firstOffset = 5; // 5월 1일 = 금요일 (일=0)
  static const int daysInMonth = 31;

  /// Per-day completion (0..1), null = future. 31 entries.
  static const List<double?> _monthData = [
    1.0, 0.83, 1.0, 1.0, 0.67, 1.0, 1.0, //
    0.83, 1.0, 1.0, 0.50, 1.0, 1.0, 1.0, //
    1.0, 0.67, 1.0, 1.0, 0.83, 0.33, 1.0, //
    1.0, 1.0, 1.0, 1.0, 0.83, 0.50, null, //
    null, null, null,
  ];

  static const List<ScheduleItem> _initialToday = [
    ScheduleItem(id: '1', kind: ScheduleKind.med, name: '암로디핀 5mg', dose: '1정', time: '08:00', taken: true, takenAt: '08:12'),
    ScheduleItem(id: '2', kind: ScheduleKind.meal, name: '아침 식사', time: '08:30', taken: true, takenAt: '08:38'),
    ScheduleItem(id: '3', kind: ScheduleKind.med, name: '메트포르민 500mg', dose: '1정', time: '12:30', taken: true, takenAt: '12:41'),
    ScheduleItem(id: '4', kind: ScheduleKind.meal, name: '점심 식사', time: '12:30', taken: false),
    ScheduleItem(id: '5', kind: ScheduleKind.meal, name: '저녁 식사', time: '18:30', taken: false),
    ScheduleItem(id: '6', kind: ScheduleKind.med, name: '아토르바스타틴 10mg', dose: '1정', time: '20:00', taken: false),
  ];

  /// Template used to synthesise an arbitrary day's schedule (no taken state).
  static const List<ScheduleItem> _dayTemplate = [
    ScheduleItem(id: 't0', kind: ScheduleKind.med, name: '암로디핀 5mg', dose: '1정', time: '08:00'),
    ScheduleItem(id: 't1', kind: ScheduleKind.meal, name: '아침 식사', time: '08:30'),
    ScheduleItem(id: 't2', kind: ScheduleKind.med, name: '메트포르민 500mg', dose: '1정', time: '12:30'),
    ScheduleItem(id: 't3', kind: ScheduleKind.meal, name: '점심 식사', time: '12:30'),
    ScheduleItem(id: 't4', kind: ScheduleKind.meal, name: '저녁 식사', time: '18:30'),
    ScheduleItem(id: 't5', kind: ScheduleKind.med, name: '아토르바스타틴 10mg', dose: '1정', time: '20:00'),
  ];

  static const List<Med> _meds = [
    Med(id: 'm1', name: '암로디핀', dose: '5mg', count: '1정', schedule: '매일 08:00', purpose: '혈압', completion: 0.96),
    Med(id: 'm2', name: '메트포르민', dose: '500mg', count: '1정', schedule: '매일 12:30', purpose: '당뇨', completion: 0.93),
    Med(id: 'm3', name: '아토르바스타틴', dose: '10mg', count: '1정', schedule: '매일 20:00', purpose: '콜레스테롤', completion: 0.78),
  ];

  static const List<Guardian> _guardians = [
    Guardian(id: 'g1', name: '이지원', relation: '딸', active: true),
    Guardian(id: 'g2', name: '이정훈', relation: '아들', active: true),
  ];

  static const List<MissedItem> _missed = [
    MissedItem(name: '아토르바스타틴 10mg', time: '20:00', missed: 6, total: 27),
    MissedItem(name: '저녁 식사', time: '18:30', missed: 4, total: 27),
    MissedItem(name: '점심 식사', time: '12:30', missed: 3, total: 27),
    MissedItem(name: '메트포르민 500mg', time: '12:30', missed: 2, total: 27),
  ];

  @override
  Future<Patient> fetchPatient() => _delayed(_patient);

  @override
  Future<List<Guardian>> fetchGuardians() => _delayed(_guardians);

  @override
  Future<List<Med>> fetchMeds() => _delayed(_meds);

  @override
  Future<List<ScheduleItem>> fetchTodayItems() => _delayed(_initialToday);

  @override
  Future<MonthOverview> fetchMonth() => _delayed(const MonthOverview(
        label: monthLabel,
        year: 2026,
        month: 5,
        completion: _monthData,
        today: today,
        firstWeekdayOffset: firstOffset,
        daysInMonth: daysInMonth,
        isCurrentMonth: true,
      ));

  @override
  Future<List<MissedItem>> fetchMissedItems() => _delayed(_missed);

  @override
  Future<List<ScheduleItem>> fetchDayDetail(int dayOfMonth) =>
      _delayed(_generateDay(dayOfMonth));

  @override
  Future<void> setItemTaken(String itemId, bool taken) async {
    // No-op for the mock — the provider keeps the optimistic state. A Firebase
    // implementation would write the mutation and let the snapshot propagate.
  }

  Future<T> _delayed<T>(T value) => Future.delayed(_latency, () => value);

  /// Port of `generateDay()` in shared.jsx: deterministically marks some items
  /// missed based on the day's completion ratio, with a small time drift on
  /// the ones taken.
  static List<ScheduleItem> _generateDay(int date) {
    final pct = (date >= 1 && date <= _monthData.length) ? _monthData[date - 1] : null;
    if (pct == null) {
      return [
        for (final t in _dayTemplate) t.copyWith(taken: false, clearTakenAt: true),
      ];
    }
    final total = _dayTemplate.length;
    final totalToTake = (pct * total).round();
    const order = [3, 4, 5, 0, 2, 1];
    final missedSet = order.sublist(0, total - totalToTake).toSet();

    final result = <ScheduleItem>[];
    for (var i = 0; i < total; i++) {
      final t = _dayTemplate[i];
      if (missedSet.contains(i)) {
        result.add(t.copyWith(taken: false, clearTakenAt: true));
        continue;
      }
      final parts = t.time.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final drift = ((date * 7 + i * 13) % 17) - 4;
      final mins = h * 60 + m + drift;
      final hh = (mins ~/ 60).toString().padLeft(2, '0');
      final mm = (mins % 60).toString().padLeft(2, '0');
      result.add(t.copyWith(taken: true, takenAt: '$hh:$mm'));
    }
    return result;
  }
}
