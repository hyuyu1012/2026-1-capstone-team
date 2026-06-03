/// A registered medication managed under 설정 → 복용 일정 관리.
class Med {
  const Med({
    required this.id,
    required this.name,
    required this.dose,
    required this.count,
    required this.schedule,
    required this.purpose,
    required this.completion,
  });

  final String id;
  final String name; // "암로디핀"
  final String dose; // "5mg"
  final String count; // "1정"
  final String schedule; // "매일 08:00"
  final String purpose; // "혈압"
  final double completion; // 0..1 adherence

  factory Med.fromMap(Map<String, dynamic> map) => Med(
        id: map['id'] as String,
        name: map['name'] as String,
        dose: map['dose'] as String,
        count: map['count'] as String,
        schedule: map['schedule'] as String,
        purpose: map['purpose'] as String,
        completion: (map['completion'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dose': dose,
        'count': count,
        'schedule': schedule,
        'purpose': purpose,
        'completion': completion,
      };
}
