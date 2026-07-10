// modules/photo/photo_repository.dart
// 역할: photos 테이블 CRUD. 모듈4(사진)와 모듈6(백업 복원)에서 사용.

import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/database.dart';
import 'photo_model.dart';

class PhotoRepository {
  final AppDatabase _appDb;
  PhotoRepository({AppDatabase? appDb}) : _appDb = appDb ?? AppDatabase.instance;

  Future<Database> get _db async => _appDb.database;

  Future<int> insert(Photo photo) async {
    final db = await _db;
    return db.insert(Tables.photos, photo.toMap());
  }

  Future<List<Photo>> getByPlant(int plantId) async {
    final db = await _db;
    final rows = await db.query(
      Tables.photos,
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'taken_at DESC',
    );
    return rows.map(Photo.fromMap).toList();
  }

  Future<Photo?> getById(int id) async {
    final db = await _db;
    final rows =
        await db.query(Tables.photos, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Photo.fromMap(rows.first);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(Tables.photos, where: 'id = ?', whereArgs: [id]);
  }
}
