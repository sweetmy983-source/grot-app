// modules/history/care_log_repository.dart
// 역할: care_logs 테이블 CRUD. 모듈2는 물주기 기록 insert 에 사용하고,
//       모듈3(이력 UI)·모듈5(캘린더)에서 조회 메서드를 확장해 사용한다.

import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/database.dart';
import 'care_log_model.dart';

class CareLogRepository {
  final AppDatabase _appDb;
  CareLogRepository({AppDatabase? appDb})
      : _appDb = appDb ?? AppDatabase.instance;

  Future<Database> get _db async => _appDb.database;

  Future<int> insert(CareLog log) async {
    final db = await _db;
    return db.insert(Tables.careLogs, log.toMap());
  }

  Future<void> update(CareLog log) async {
    final db = await _db;
    await db.update(
      Tables.careLogs,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(Tables.careLogs, where: 'id = ?', whereArgs: [id]);
  }

  // 특정 화분의 이력 (최신순)
  Future<List<CareLog>> getByPlant(int plantId) async {
    final db = await _db;
    final rows = await db.query(
      Tables.careLogs,
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'logged_at DESC',
    );
    return rows.map(CareLog.fromMap).toList();
  }

  // 전체 이력 (모듈5 캘린더용)
  Future<List<CareLog>> getAll() async {
    final db = await _db;
    final rows =
        await db.query(Tables.careLogs, orderBy: 'logged_at DESC');
    return rows.map(CareLog.fromMap).toList();
  }
}
