import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';

class PatientLinkException implements Exception {
  PatientLinkException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads/writes the `patients/{id}` docs that hold the patient profile + the
/// `guardianIds` array that joins guardians (this app) to them.
class PatientService {
  PatientService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // 6-char alphanumeric, no ambiguous 0/O/1/I/L.
  static const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  final _rng = Random.secure();

  CollectionReference<Map<String, dynamic>> get _patients =>
      _db.collection('patients');

  Future<Patient> createPatient({
    required String guardianUid,
    required String name,
    required String relation,
    required int birthYear,
    required int birthMonth,
    required int birthDay,
    required String gender,
    String? note,
  }) async {
    final docRef = _patients.doc();
    final code = await _generateUniqueCode();
    final data = <String, dynamic>{
      'name': name,
      'relation': relation,
      'birthYear': birthYear,
      'birthMonth': birthMonth,
      'birthDay': birthDay,
      'gender': gender,
      'note': note,
      'userId': null,
      'guardianIds': [guardianUid],
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    return Patient.fromMap({...data, 'id': docRef.id});
  }

  Future<Patient> linkByInviteCode({
    required String code,
    required String guardianUid,
  }) async {
    final normalized = code.toUpperCase().trim();
    final query = await _patients
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw PatientLinkException('잘못된 초대 코드예요. 다시 확인해주세요.');
    }
    final doc = query.docs.first;
    final data = doc.data();
    final guardianIds = List<String>.from(data['guardianIds'] as List? ?? const []);
    if (!guardianIds.contains(guardianUid)) {
      await doc.reference.update({
        'guardianIds': FieldValue.arrayUnion([guardianUid]),
      });
      guardianIds.add(guardianUid);
    }
    return Patient.fromMap({...data, 'id': doc.id, 'guardianIds': guardianIds});
  }

  Stream<List<Patient>> patientsForGuardian(String guardianUid) {
    return _patients
        .where('guardianIds', arrayContains: guardianUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Patient.fromMap({...d.data(), 'id': d.id}))
            .toList());
  }

  Future<String> _generateUniqueCode() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = List.generate(
        6,
        (_) => _codeAlphabet[_rng.nextInt(_codeAlphabet.length)],
      ).join();
      final clash = await _patients
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (clash.docs.isEmpty) return code;
    }
    throw PatientLinkException('초대 코드 생성에 실패했어요. 다시 시도해주세요.');
  }
}
