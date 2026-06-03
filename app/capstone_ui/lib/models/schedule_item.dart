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
  });

  final String id;
  final ScheduleKind kind;
  final String name;
  final String? dose; // med only — e.g. "1정"
  final String time; // "HH:mm" scheduled time
  final bool taken;
  final String? takenAt; // "HH:mm" completion time

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
    bool clearTakenAt = false,
    bool clearDose = false,
  }) {
    return ScheduleItem(
      id: id,
      kind: kind,
      name: name ?? this.name,
      dose: clearDose ? null : (dose ?? this.dose),
      time: time ?? this.time,
      taken: taken ?? this.taken,
      takenAt: clearTakenAt ? null : (takenAt ?? this.takenAt),
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
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'dose': dose,
        'time': time,
        'taken': taken,
        'takenAt': takenAt,
      };
}
