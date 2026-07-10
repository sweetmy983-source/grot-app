// modules/photo/photo_model.dart
// 역할: photos 테이블 대응 모델. file_path 는 documents 기준 '상대경로'로 저장한다
//       (폰 교체/복원 호환 — 명세 2번). 실제 접근은 AppPaths.abs() 로 절대경로 변환.

class Photo {
  final int? id;
  final int plantId;
  final String filePath; // 상대경로 (예: photos/169....jpg)
  final String? memo;
  final DateTime takenAt;

  const Photo({
    this.id,
    required this.plantId,
    required this.filePath,
    this.memo,
    required this.takenAt,
  });

  factory Photo.fromMap(Map<String, dynamic> m) {
    return Photo(
      id: m['id'] as int?,
      plantId: m['plant_id'] as int,
      filePath: m['file_path'] as String,
      memo: m['memo'] as String?,
      takenAt:
          DateTime.tryParse(m['taken_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plant_id': plantId,
      'file_path': filePath,
      'memo': memo,
      'taken_at': takenAt.toIso8601String(),
    };
  }
}
