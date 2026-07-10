// core/database.dart
// 역할: SQLite 초기화 및 스키마/마이그레이션 관리 (명세 2번).
//       모든 모듈의 repository 가 이 single instance 의 Database 를 공유한다.
//       외래키(ON DELETE CASCADE)를 켜서 화분 삭제 시 이력/사진도 함께 정리된다.

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'constants.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // 백업 복원 호환을 위해 documents 디렉토리 하위에 DB 를 둔다.
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, AppConst.dbName);

    return openDatabase(
      dbPath,
      version: AppConst.dbVersion,
      onConfigure: (db) async {
        // 외래키 제약 활성화 (기본은 꺼져 있음)
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 화분
    await db.execute('''
      CREATE TABLE ${Tables.plants} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT,
        location TEXT,
        watering_interval_days INTEGER NOT NULL,
        last_watered_at TEXT,
        notify_hour INTEGER DEFAULT ${AppConst.defaultNotifyHour},
        notify_minute INTEGER DEFAULT ${AppConst.defaultNotifyMinute},
        main_photo_id INTEGER,
        memo TEXT,
        created_at TEXT NOT NULL,
        is_archived INTEGER DEFAULT 0
      )
    ''');

    // 관리 이력 (물주기 포함 모든 행위 기록)
    await db.execute('''
      CREATE TABLE ${Tables.careLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id INTEGER NOT NULL REFERENCES ${Tables.plants}(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        memo TEXT,
        logged_at TEXT NOT NULL
      )
    ''');

    // 사진
    await db.execute('''
      CREATE TABLE ${Tables.photos} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id INTEGER NOT NULL REFERENCES ${Tables.plants}(id) ON DELETE CASCADE,
        file_path TEXT NOT NULL,
        memo TEXT,
        taken_at TEXT NOT NULL
      )
    ''');

    // 조회 성능용 인덱스
    await db.execute(
        'CREATE INDEX idx_care_logs_plant ON ${Tables.careLogs}(plant_id)');
    await db.execute(
        'CREATE INDEX idx_photos_plant ON ${Tables.photos}(plant_id)');
  }

  // 향후 스키마 변경 시 version 을 올리고 여기에 단계별 마이그레이션을 추가한다.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 예: if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  // 백업 Import 등에서 전체 초기화가 필요할 때 사용 (모듈6).
  Future<void> wipeAll() async {
    final db = await database;
    await db.delete(Tables.photos);
    await db.delete(Tables.careLogs);
    await db.delete(Tables.plants);
  }
}
