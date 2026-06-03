import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_item.dart';

/// Reads the `patients/{patientId}/schedules` subcollection the guardian app
/// writes to. Read-only here — the patient app only displays what the guardian
/// registered (the sensor team writes taken/missed separately).
class ScheduleService {
  ScheduleService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<ScheduleItem>> schedulesFor(String patientId) {
    return _db
        .collection('patients')
        .doc(patientId)
        .collection('schedules')
        .orderBy('time')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ScheduleItem.fromMap({...d.data(), 'id': d.id}))
            .toList());
  }
}
