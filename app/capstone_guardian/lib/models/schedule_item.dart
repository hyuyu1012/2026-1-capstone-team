/// A single dose or meal on a given day. Mirrors the `ScheduleItem` sketch in
/// the design handoff README.
enum ScheduleKind {
  med,
  meal;

  /// Korean label used in row metadata ("약" / "식사").
  String get label => this == ScheduleKind.med ? '약' : '식사';

  static ScheduleKind fromName(String name) =>
      name == 'meal' ? ScheduleKind.meal : ScheduleKind.med;
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.time,
    this.dose,
    this.taken = false,
    this.takenAt,
    this.skipped = false,
    this.mealRelation,
    this.mealId,
  });

  final String id;
  final ScheduleKind kind;
  final String name;
  final String? dose; // med only — e.g. "1정"
  final String time; // "HH:mm" scheduled time
  final bool taken;
  final String? takenAt; // "HH:mm" completion time

  /// 오늘 하루 의도적으로 건너뛴 항목. 완료(taken)와 상호 배타적이며, 통계에서
  /// 누락으로 집계하지 않는다 (보호자가 "오늘은 안 함"으로 표시).
  final bool skipped;

  /// 약-식사 관계('before'/'after'/null) 및 연결된 식사 id. 등록 시 기록하며,
  /// 환자 앱이 식후약을 어느 식사에 맞춰 감지할지 결정하는 데 쓴다.
  final String? mealRelation;
  final String? mealId;

  /// Minutes since midnight for the scheduled [time] — handy for the 24h ring.
  int get scheduledMinutes => _toMinutes(time);

  /// Minutes since midnight for [takenAt], falling back to the scheduled time.
  int get markerMinutes => taken && takenAt != null ? _toMinutes(takenAt!) : scheduledMinutes;

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  ScheduleItem copyWith({
    String? name,
    String? dose,
    String? time,
    bool? taken,
    String? takenAt,
    bool? skipped,
    bool clearTakenAt = false,
    bool clearDose = false,
    String? mealRelation,
    String? mealId,
  }) {
    return ScheduleItem(
      id: id,
      kind: kind,
      name: name ?? this.name,
      dose: clearDose ? null : (dose ?? this.dose),
      time: time ?? this.time,
      taken: taken ?? this.taken,
      takenAt: clearTakenAt ? null : (takenAt ?? this.takenAt),
      skipped: skipped ?? this.skipped,
      mealRelation: mealRelation ?? this.mealRelation,
      mealId: mealId ?? this.mealId,
    );
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) => ScheduleItem(
        id: map['id'] as String,
        kind: ScheduleKind.fromName(map['kind'] as String),
        name: map['name'] as String,
        dose: map['dose'] as String?,
        time: map['time'] as String,
        taken: map['taken'] as bool? ?? false,
        takenAt: map['takenAt'] as String?,
        skipped: map['skipped'] as bool? ?? false,
        mealRelation: map['mealRelation'] as String?,
        mealId: map['mealId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'dose': dose,
        'time': time,
        'taken': taken,
        'takenAt': takenAt,
        'skipped': skipped,
        'mealRelation': mealRelation,
        'mealId': mealId,
      };
}
