// modules/plant/plant_model.dart
// 역할: 화분(plants) 테이블에 대응하는 불변 데이터 모델.
//       DB Map <-> 객체 변환과, 다음 물주기/지연일 계산 같은 파생 로직을 담는다.

class Plant {
  final int? id;
  final String name; // 애칭 (필수)
  final String? species; // 품종
  final String? location; // 위치
  final int wateringIntervalDays; // 물주기 주기(일, 필수)
  final DateTime? lastWateredAt;
  final int notifyHour;
  final int notifyMinute;
  final int? mainPhotoId;
  final String? memo;
  final DateTime createdAt;
  final bool isArchived;

  const Plant({
    this.id,
    required this.name,
    this.species,
    this.location,
    required this.wateringIntervalDays,
    this.lastWateredAt,
    this.notifyHour = 9,
    this.notifyMinute = 0,
    this.mainPhotoId,
    this.memo,
    required this.createdAt,
    this.isArchived = false,
  });

  // 다음 물주기 예정일. 물을 준 적 없으면 등록일 기준으로 계산.
  DateTime get nextWateringDate {
    final base = lastWateredAt ?? createdAt;
    return base.add(Duration(days: wateringIntervalDays));
  }

  // 오늘 기준 남은 일수. 음수면 지난 것(연체).
  // 자정 기준으로 계산해 "몇 밤 남았는지" 직관과 맞춘다.
  int daysUntilNextWatering({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final due = _dateOnly(nextWateringDate);
    return due.difference(today).inDays;
  }

  bool isOverdue({DateTime? now}) => daysUntilNextWatering(now: now) < 0;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  factory Plant.fromMap(Map<String, dynamic> m) {
    return Plant(
      id: m['id'] as int?,
      name: m['name'] as String,
      species: m['species'] as String?,
      location: m['location'] as String?,
      wateringIntervalDays: m['watering_interval_days'] as int,
      lastWateredAt: _parse(m['last_watered_at'] as String?),
      notifyHour: (m['notify_hour'] as int?) ?? 9,
      notifyMinute: (m['notify_minute'] as int?) ?? 0,
      mainPhotoId: m['main_photo_id'] as int?,
      memo: m['memo'] as String?,
      createdAt: _parse(m['created_at'] as String?) ?? DateTime.now(),
      isArchived: (m['is_archived'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'species': species,
      'location': location,
      'watering_interval_days': wateringIntervalDays,
      'last_watered_at': lastWateredAt?.toIso8601String(),
      'notify_hour': notifyHour,
      'notify_minute': notifyMinute,
      'main_photo_id': mainPhotoId,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'is_archived': isArchived ? 1 : 0,
    };
  }

  Plant copyWith({
    int? id,
    String? name,
    String? species,
    String? location,
    int? wateringIntervalDays,
    DateTime? lastWateredAt,
    bool clearLastWatered = false,
    int? notifyHour,
    int? notifyMinute,
    int? mainPhotoId,
    bool clearMainPhoto = false,
    String? memo,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      location: location ?? this.location,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      lastWateredAt:
          clearLastWatered ? null : (lastWateredAt ?? this.lastWateredAt),
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      mainPhotoId: clearMainPhoto ? null : (mainPhotoId ?? this.mainPhotoId),
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  static DateTime? _parse(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);
}
