// core/constants.dart
// 역할: 앱 전역에서 쓰는 상수 모음 (DB 이름, 테이블/케어타입 정의, 기본값 등).
//       매직 스트링을 한 곳에 모아 오타·중복을 줄인다.

class AppConst {
  AppConst._();

  static const String appName = '그루우';
  static const String dbName = 'groo.db';
  static const int dbVersion = 1;

  // 백업 JSON 스키마 버전 (모듈6 마이그레이션 대비)
  static const int backupSchemaVersion = 1;

  // 앱 documents 디렉토리 내 사진 저장 하위 폴더 (상대경로 기준점)
  static const String photoDirName = 'photos';

  // 기본 알림 시각
  static const int defaultNotifyHour = 9;
  static const int defaultNotifyMinute = 0;
}

// 테이블 이름
class Tables {
  Tables._();
  static const String plants = 'plants';
  static const String careLogs = 'care_logs';
  static const String photos = 'photos';
}

// 관리 이력 타입 — care_logs.type 컬럼에 저장되는 문자열 값
enum CareType { water, fertilizer, repot, prune, pest, etc }

extension CareTypeX on CareType {
  // DB 저장용 문자열
  String get key {
    switch (this) {
      case CareType.water:
        return 'water';
      case CareType.fertilizer:
        return 'fertilizer';
      case CareType.repot:
        return 'repot';
      case CareType.prune:
        return 'prune';
      case CareType.pest:
        return 'pest';
      case CareType.etc:
        return 'etc';
    }
  }

  // UI 표시용 한글 라벨
  String get label {
    switch (this) {
      case CareType.water:
        return '물주기';
      case CareType.fertilizer:
        return '비료';
      case CareType.repot:
        return '분갈이';
      case CareType.prune:
        return '가지치기';
      case CareType.pest:
        return '병충해';
      case CareType.etc:
        return '기타';
    }
  }

  static CareType fromKey(String key) {
    return CareType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => CareType.etc,
    );
  }
}
