// modules/plant/plant_repository.dart
// 역할: plants 테이블 CRUD 를 담당하는 데이터 접근 계층.
//       모듈 간 결합 최소화를 위해 다른 모듈은 이 repository 를 직접 부르지 않고
//       PlantProvider 를 통해 접근한다.

import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/database.dart';
import 'plant_model.dart';

class PlantRepository {
  final AppDatabase _appDb;
  PlantRepository({AppDatabase? appDb}) : _appDb = appDb ?? AppDatabase.instance;

  Future<Database> get _db async => _appDb.database;

  // 보관 여부에 따라 화분 목록 조회 (기본: 활성 화분만)
  Future<List<Plant>> getPlants({bool archived = false}) async {
    final db = await _db;
    final rows = await db.query(
      Tables.plants,
      where: 'is_archived = ?',
      whereArgs: [archived ? 1 : 0],
      orderBy: 'created_at DESC',
    );
    return rows.map(Plant.fromMap).toList();
  }

  // 보관 여부 무관 전체 화분 (캘린더 이름 조회 등)
  Future<List<Plant>> getAllPlants() async {
    final db = await _db;
    final rows = await db.query(Tables.plants, orderBy: 'created_at DESC');
    return rows.map(Plant.fromMap).toList();
  }

  Future<Plant?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      Tables.plants,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Plant.fromMap(rows.first);
  }

  Future<int> insert(Plant plant) async {
    final db = await _db;
    return db.insert(Tables.plants, plant.toMap());
  }

  Future<void> update(Plant plant) async {
    final db = await _db;
    await db.update(
      Tables.plants,
      plant.toMap(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  // 보관/복원 토글 (삭제 대신)
  Future<void> setArchived(int id, bool archived) async {
    final db = await _db;
    await db.update(
      Tables.plants,
      {'is_archived': archived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 대표 사진 지정 (모듈4에서 사용)
  Future<void> setMainPhoto(int plantId, int? photoId) async {
    final db = await _db;
    await db.update(
      Tables.plants,
      {'main_photo_id': photoId},
      where: 'id = ?',
      whereArgs: [plantId],
    );
  }

  // 물주기 갱신: last_watered_at 을 지정 시각으로 업데이트 (모듈2)
  Future<void> updateLastWatered(int plantId, DateTime at) async {
    final db = await _db;
    await db.update(
      Tables.plants,
      {'last_watered_at': at.toIso8601String()},
      where: 'id = ?',
      whereArgs: [plantId],
    );
  }

  // 완전 삭제 — care_logs/photos 는 ON DELETE CASCADE 로 함께 삭제됨
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(Tables.plants, where: 'id = ?', whereArgs: [id]);
  }

  // 각 화분의 대표사진 상대경로 맵 (홈 카드 썸네일용). main_photo_id 가 가리키는 사진.
  Future<Map<int, String>> getMainPhotoRelPaths() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.id AS pid, ph.file_path AS fp
      FROM ${Tables.plants} p
      JOIN ${Tables.photos} ph ON p.main_photo_id = ph.id
    ''');
    final map = <int, String>{};
    for (final r in rows) {
      final pid = r['pid'] as int?;
      final fp = r['fp'] as String?;
      if (pid != null && fp != null) map[pid] = fp;
    }
    return map;
  }
}
