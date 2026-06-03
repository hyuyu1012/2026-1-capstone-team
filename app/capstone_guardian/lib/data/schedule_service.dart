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
