import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/care_repository.dart';
import '../data/daily_log_service.dart';
import '../data/patient_service.dart';
import '../data/schedule_service.dart';
import '../models/med.dart';
import '../models/missed_item.dart';
import '../models/patient.dart';
import '../models/schedule_item.dart';

/// Holds all data-backed state for the four tabs. The patient + today's
/// schedule come from Firestore (subscribed once a guardian uid is bound), and
/// 기록 / 통계 read the per-day adherence history from [DailyLogService]
/// (written by the patient sensor, and by the 홈 toggle as a fallback). Meds /
/// guardians still come from the mock [CareRepository].
class CareProvider extends ChangeNotifier {
  CareProvider(
    this._repo,
    this._patientService,
    this._scheduleService,
    this._dailyLogService,
  );

  final CareRepository _repo;
  final PatientService _patientService;
  final ScheduleService _scheduleService;
  final DailyLogService _dailyLogService;

  /// Current wall-clock time as "HH:mm" — the default completion stamp when the
  /// guardian checks an item without entering an explicit time.
  static String _nowStamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  String? _boundUid;
  StreamSubscription<List<Patient>>? _patientsSub;
  StreamSubscription<List<ScheduleItem>>? _schedulesSub;

  bool _patientLoading = false;
  bool get patientLoading => _patientLoading;

  bool _restLoading = false;
  bool get loading => _patientLoading || _restLoading;

  Patient? _patient;
  Patient? get patient => _patient;

  List<ScheduleItem> _todayItems = const [];
  List<ScheduleItem> get todayItems => _todayItems;

  MonthOverview? _month;
  MonthOverview? get month => _month;

  List<Med> _meds = const [];
  List<Med> get meds => _meds;

  List<Guardian> _guardians = const [];
  List<Guardian> get guardians => _guardians;

  List<MissedItem> _missed = const [];
  List<MissedItem> get missed => _missed;

  int get doneCount => _todayItems.where((i) => i.taken).length;
  // 건너뛴 항목은 분모에서 제외 — 의도적 스킵은 완료율을 깎지 않는다.
  int get totalCount => _todayItems.where((i) => !i.skipped).length;

  /// Start listening for any patient whose `guardianIds` contains [uid]. Safe
  /// to call repeatedly with the same uid (no-op). Switches subscription if a
  /// different uid is passed.
  void bindToGuardian(String uid) {
    if (_boundUid == uid) return;
    _patientsSub?.cancel();
    _boundUid = uid;
    _patientLoading = true;
    notifyListeners();
    _patientsSub = _patientService.patientsForGuardian(uid).listen((list) {
      _patientLoading = false;
      final next = list.isEmpty ? null : list.first;
      final changed = next?.id != _patient?.id;
      _patient = next;
      if (changed && next != null) {
        _loadRest();
        _bindSchedules(next.id);
      } else if (next == null) {
        _clearRest();
      }
      notifyListeners();
    });
  }

  /// Subscribe to the bound patient's Firestore schedules — drives 홈's
  /// 오늘의 일정 (and 기록 day detail) live.
  void _bindSchedules(String patientId) {
    _schedulesSub?.cancel();
    _schedulesSub = _scheduleService.schedulesFor(patientId).listen((items) {
      _todayItems = items;
      notifyListeners();
    });
  }

  /// Drop the subscription and reset everything. Call on sign-out.
  void unbindFromGuardian() {
    _patientsSub?.cancel();
    _patientsSub = null;
    _boundUid = null;
    _patient = null;
    _patientLoading = false;
    _clearRest();
    notifyListeners();
  }

  Future<void> _loadRest() async {
    final patient = _patient;
    if (patient == null) return;
    _restLoading = true;
    notifyListeners();
    // 오늘의 일정(_todayItems)은 _bindSchedules의 Firestore 스트림이 채운다.
    // 월간 그리드/누락 통계는 dailyLogs(센서 기록)에서, 약/보호자는 아직 mock.
    final now = DateTime.now();
    // 신규 계정이면 직전 달 더미 이력을 한 번만 시드한다(이미 있으면 no-op).
    await _dailyLogService.seedDummy(patient.id, now);
    final results = await Future.wait([
      _dailyLogService.monthOverview(patient.id, now.year, now.month, now),
      _repo.fetchMeds(),
      _repo.fetchGuardians(),
      _dailyLogService.missedItems(patient.id, now.year, now.month),
    ]);
    _month = results[0] as MonthOverview;
    _meds = results[1] as List<Med>;
    _guardians = results[2] as List<Guardian>;
    _missed = results[3] as List<MissedItem>;
    _restLoading = false;
    notifyListeners();
  }

  void _clearRest() {
    _schedulesSub?.cancel();
    _schedulesSub = null;
    _todayItems = const [];
    _month = null;
    _meds = const [];
    _guardians = const [];
    _missed = const [];
    _restLoading = false;
  }

  /// Optimistically flip an item's taken state, then persist. When checking on,
  /// the completion time is [takenAt] (the time the guardian entered) or the
  /// current wall-clock time if omitted; unchecking clears it.
  Future<void> toggleItem(String id, {String? takenAt}) async {
    final idx = _todayItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final current = _todayItems[idx];
    final nextTaken = !current.taken;
    final stamp = nextTaken ? (takenAt ?? _nowStamp()) : null;
    final updated = current.copyWith(
      taken: nextTaken,
      takenAt: stamp,
      clearTakenAt: !nextTaken,
      // 완료 처리하면 "건너뜀"은 자동 해제 (상호 배타적).
      skipped: nextTaken ? false : null,
    );
    _todayItems = [..._todayItems]..[idx] = updated;
    notifyListeners();
    final patient = _patient;
    if (patient != null) {
      await _scheduleService.setTaken(patient.id, id,
          taken: nextTaken, takenAt: stamp);
      // 홈 체크를 오늘자 dailyLog에 하루치 스냅샷으로 기록해, 오늘 완료율이
      // 홈과 일치하고 기록/통계에 반영되도록 한다.
      final today = DateTime.now();
      await _dailyLogService.recordDay(
        patient.id,
        DailyLogService.dateId(today.year, today.month, today.day),
        _todayItems,
      );
      _month =
          await _dailyLogService.monthOverview(patient.id, today.year, today.month, today);
      _missed = await _dailyLogService.missedItems(patient.id, today.year, today.month);
      notifyListeners();
    } else {
      await _repo.setItemTaken(id, nextTaken);
    }
  }

  /// 오늘 항목을 의도적으로 "건너뜀"으로 토글한다. 완료 상태와 상호 배타적이라
  /// 건너뛰면 완료/완료시각은 비운다. 건너뛴 항목은 통계에서 누락으로 잡히지
  /// 않는다. 낙관적 갱신 후 Firestore + 오늘자 dailyLog에 반영한다.
  Future<void> skipItem(String id) async {
    final idx = _todayItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final current = _todayItems[idx];
    final nextSkipped = !current.skipped;
    final updated = current.copyWith(
      skipped: nextSkipped,
      taken: false,
      clearTakenAt: true,
    );
    _todayItems = [..._todayItems]..[idx] = updated;
    notifyListeners();
    final patient = _patient;
    if (patient == null) return; // mock 모드 — 로컬 상태만 변경
    await _scheduleService.setSkipped(patient.id, id, skipped: nextSkipped);
    // 오늘자 dailyLog 스냅샷 갱신 후 통계(_month/_missed) 재계산.
    final today = DateTime.now();
    await _dailyLogService.recordDay(
      patient.id,
      DailyLogService.dateId(today.year, today.month, today.day),
      _todayItems,
    );
    _month = await _dailyLogService.monthOverview(
        patient.id, today.year, today.month, today);
    _missed =
        await _dailyLogService.missedItems(patient.id, today.year, today.month);
    notifyListeners();
  }

  /// Remove a schedule item (meal or med) from the patient's schedule.
  /// Optimistically drops it from the list, then deletes from Firestore; the
  /// snapshot stream reconciles afterwards. Restores the item if the write
  /// fails. With no bound patient (mock mode) it just removes locally.
  Future<void> deleteItem(String id) async {
    final idx = _todayItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final removed = _todayItems[idx];
    _todayItems = [..._todayItems]..removeAt(idx);
    notifyListeners();
    final patient = _patient;
    if (patient == null) return;
    try {
      await _scheduleService.deleteSchedule(patient.id, id);
    } catch (e) {
      _todayItems = [..._todayItems]..insert(idx, removed);
      notifyListeners();
      rethrow;
    }
  }

  /// Edit a schedule item's name / time / dose (long-press → 편집). Optimistic;
  /// re-sorts by time to match the Firestore `orderBy('time')` stream, and
  /// restores the previous list if the write fails.
  Future<void> updateItem(
    String id, {
    required String name,
    required String time,
    String? dose,
  }) async {
    final idx = _todayItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final prevList = _todayItems;
    final updated = _todayItems[idx]
        .copyWith(name: name, time: time, dose: dose, clearDose: dose == null);
    _todayItems = [..._todayItems]
      ..[idx] = updated
      ..sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
    final patient = _patient;
    if (patient == null) return;
    try {
      await _scheduleService.updateSchedule(patient.id, id,
          name: name, time: time, dose: dose);
    } catch (e) {
      _todayItems = prevList;
      notifyListeners();
      rethrow;
    }
  }

  /// 기록 — calendar metadata + per-day completion for an arbitrary month
  /// (drives month navigation). Falls back to mock with no bound patient.
  Future<MonthOverview> monthOverview(int year, int month) async {
    final patient = _patient;
    if (patient == null) return _repo.fetchMonth();
    return _dailyLogService.monthOverview(
        patient.id, year, month, DateTime.now());
  }

  /// 기록 — the adherence record for a specific day, from dailyLogs. Empty when
  /// the sensor hasn't logged that day; falls back to mock with no patient.
  Future<List<ScheduleItem>> dayDetail(int year, int month, int day) async {
    final patient = _patient;
    if (patient == null) return _repo.fetchDayDetail(day);
    final log = await _dailyLogService.logForDay(patient.id, year, month, day);
    return log?.items ?? const <ScheduleItem>[];
  }

  @override
  void dispose() {
    _patientsSub?.cancel();
    _schedulesSub?.cancel();
    super.dispose();
  }
}
