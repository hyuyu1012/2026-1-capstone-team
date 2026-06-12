import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_item.dart';

/// Reads/writes the `patients/{patientId}/schedules/{id}` subcollection — the
/// meds & meals a guardian registers. The patient-side app reads the same
/// subcollection to show what its guardian set up; the sensor team writes
/// `taken`/`takenAt` later.
class ScheduleService {
  ScheduleService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _schedules(String patientId) =>
      _db.collection('patients').doc(patientId).collection('schedules');

  /// Live list for a patient, ordered by scheduled time. Used by both apps.
  Stream<List<ScheduleItem>> schedulesFor(String patientId) {
    return _schedules(patientId).orderBy('time').snapshots().map((snap) => snap
        .docs
        .map((d) => ScheduleItem.fromMap({...d.data(), 'id': d.id}))
        .toList());
  }

  /// Flip a schedule item's `taken` state (home toggle). Stamps/clears takenAt.
  Future<void> setTaken(
    String patientId,
    String scheduleId, {
    required bool taken,
    String? takenAt,
  }) {
    return _schedules(patientId).doc(scheduleId).update({
      'taken': taken,
      'takenAt': taken ? takenAt : null,
      // 완료 처리하면 "건너뜀"은 자동 해제 (상호 배타적).
      if (taken) 'skipped': false,
    });
  }

  /// 오늘 하루 일정을 의도적으로 건너뛴(또는 그 해제) 상태로 표시. 건너뛰면
  /// 완료 상태는 비운다. 통계에서 누락으로 집계되지 않도록 환자 앱·기록이 이
  /// 필드를 읽는다.
  Future<void> setSkipped(
    String patientId,
    String scheduleId, {
    required bool skipped,
  }) {
    return _schedules(patientId).doc(scheduleId).update({
      'skipped': skipped,
      if (skipped) 'taken': false,
      if (skipped) 'takenAt': null,
    });
  }

  /// Append one schedule item. Returns the created doc id.
  Future<String> addSchedule(
    String patientId, {
    required ScheduleKind kind,
    required String name,
    required String time,
    String? dose,
    List<String> days = const [],
    String? mealRelation,
    String? mealId,
  }) async {
    final doc = _schedules(patientId).doc();
    await doc.set({
      'kind': kind.name,
      'name': name,
      'dose': dose,
      'time': time,
      'days': days,
      'taken': false,
      'takenAt': null,
      'skipped': false,
      // 환자 앱 연동: 식후약(mealRelation='after')은 'mealId'가 가리키는 식사가
      // 감지 완료되는 시점에 복약 감시 창이 열린다. 식전은 시계 기반(라벨 용도).
      'mealRelation': ?mealRelation,
      'mealId': ?mealId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Remove a schedule item entirely (meal or med). The patient-side app stops
  /// showing it on the next snapshot.
  Future<void> deleteSchedule(String patientId, String scheduleId) {
    return _schedules(patientId).doc(scheduleId).delete();
  }

  /// Edit a schedule item's content (name / time / dose). Leaves the `taken`
  /// state and `days` untouched.
  Future<void> updateSchedule(
    String patientId,
    String scheduleId, {
    required String name,
    required String time,
    String? dose,
  }) {
    return _schedules(patientId).doc(scheduleId).update({
      'name': name,
      'time': time,
      'dose': dose,
    });
  }
}
