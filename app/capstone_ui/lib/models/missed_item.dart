/// A frequently-missed dose/meal, shown in 통계 → 자주 누락한 항목.
class MissedItem {
  const MissedItem({
    required this.name,
    required this.time,
    required this.missed,
    required this.total,
  });

  final String name; // "아토르바스타틴 10mg"
  final String time; // "20:00"
  final int missed; // days missed this month
  final int total; // days elapsed (denominator)

  factory MissedItem.fromMap(Map<String, dynamic> map) => MissedItem(
        name: map['name'] as String,
        time: map['time'] as String,
        missed: (map['missed'] as num).toInt(),
        total: (map['total'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'time': time,
        'missed': missed,
        'total': total,
      };
}
