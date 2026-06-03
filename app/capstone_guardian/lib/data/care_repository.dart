import '../models/med.dart';
import '../models/missed_item.dart';
import '../models/patient.dart';
import '../models/schedule_item.dart';

/// Calendar metadata for the 기록 month view. Bundled so a backend can return
/// the visible month in one round-trip.
class MonthOverview {
  const MonthOverview({
    required this.label,
    required this.year,
    required this.month,
    required this.completion,
    required this.today,
    required this.firstWeekdayOffset,
    required this.daysInMonth,
    this.isCurrentMonth = true,
  });

  final String label; // "2026년 5월"
  final int year; // 2026
  final int month; // 1..12
  final List<double?> completion; // per-day 0..1, null = no log / future
  final int today; // day-of-month considered "today" (see DailyLogService)
  final int firstWeekdayOffset; // weekday of the 1st (Sun=0)
  final int daysInMonth;
  final bool isCurrentMonth; // gates the 오늘 marker for past/future months
}

/// All data the four tabs need. The app talks only to this interface, so the
/// mock implementation can later be replaced by a Firebase-backed one without
/// touching any widget or provider.
abstract interface class CareRepository {
  Future<Patient> fetchPatient();
  Future<List<Guardian>> fetchGuardians();
  Future<List<Med>> fetchMeds();

  /// 홈 — today's schedule with its real completion state.
  Future<List<ScheduleItem>> fetchTodayItems();

  /// 기록 — the schedule for an arbitrary day of the current month.
  Future<List<ScheduleItem>> fetchDayDetail(int dayOfMonth);

  /// 기록 / 통계 — month completion grid + calendar metadata.
  Future<MonthOverview> fetchMonth();

  /// 통계 — most frequently missed items this month.
  Future<List<MissedItem>> fetchMissedItems();

  /// Mutation for the 홈 toggle. Mock no-ops; Firebase writes + syncs.
  Future<void> setItemTaken(String itemId, bool taken);
}
