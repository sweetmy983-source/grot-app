// modules/history/care_log_model.dart
// 역할: care_logs 테이블에 대응하는 관리 이력 모델 (물주기·비료·분갈이 등).
//       모듈2(물주기)에서 물주기 기록 저장에 먼저 쓰이고, 모듈3에서 전체 이력 UI 로 확장된다.

import '../../core/constants.dart';

class CareLog {
  final int? id;
  final int plantId;
  final CareType type;
  final String? memo;
  final DateTime loggedAt;

  const CareLog({
    this.id,
    required this.plantId,
    required this.type,
    this.memo,
    required this.loggedAt,
  });

  factory CareLog.fromMap(Map<String, dynamic> m) {
    return CareLog(
      id: m['id'] as int?,
      plantId: m['plant_id'] as int,
      type: CareTypeX.fromKey(m['type'] as String),
      memo: m['memo'] as String?,
      loggedAt: DateTime.tryParse(m['logged_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plant_id': plantId,
      'type': type.key,
      'memo': memo,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  CareLog copyWith({
    int? id,
    int? plantId,
    CareType? type,
    String? memo,
    DateTime? loggedAt,
  }) {
    return CareLog(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      type: type ?? this.type,
      memo: memo ?? this.memo,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}
