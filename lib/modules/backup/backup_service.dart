// modules/backup/backup_service.dart
// 역할: 백업 내보내기/가져오기 (명세 6번). 완전 오프라인 — 파일 공유 시트만 사용.
//   Export: plants+care_logs+photos → data.json + 사진 파일 전체를 하나의 zip 으로 묶어 공유.
//   Import: zip 선택 → 검증 → (호출부에서 확인 다이얼로그) → DB 복원 + 사진 복사.
//   data.json 에 schema_version 을 넣어 추후 마이그레이션에 대비한다.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/app_paths.dart';
import '../../core/constants.dart';
import '../../core/database.dart';

class BackupResult {
  final bool ok;
  final String message;
  const BackupResult(this.ok, this.message);
}

class BackupService {
  final AppDatabase _appDb;
  BackupService({AppDatabase? appDb}) : _appDb = appDb ?? AppDatabase.instance;

  // ---------------- Export ----------------

  Future<File> exportToZip() async {
    final db = await _appDb.database;

    final plants = await db.query(Tables.plants);
    final careLogs = await db.query(Tables.careLogs);
    final photos = await db.query(Tables.photos);

    final data = {
      'schema_version': AppConst.backupSchemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'plants': plants,
      'care_logs': careLogs,
      'photos': photos,
    };

    final archive = Archive();
    final jsonBytes = utf8.encode(const JsonEncoder().convert(data));
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    // 사진 파일 추가 (상대경로 그대로 zip 내부 경로로 사용)
    for (final row in photos) {
      final rel = row['file_path'] as String?;
      if (rel == null) continue;
      final file = File(AppPaths.abs(rel));
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        archive.addFile(ArchiveFile(rel, bytes.length, bytes));
      }
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    final tmpDir = await getTemporaryDirectory();
    final zipFile = File(p.join(tmpDir.path, 'groo_backup_$stamp.zip'));
    await zipFile.writeAsBytes(zipBytes);
    return zipFile;
  }

  Future<void> shareZip(File zip) async {
    await Share.shareXFiles([XFile(zip.path)], subject: '그루우 백업');
  }

  // ---------------- Import ----------------

  // zip 선택 (취소 시 null)
  Future<String?> pickBackupZip() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    return res?.files.single.path;
  }

  // zip 검증만 (data.json 존재 + schema_version 확인)
  Future<BackupResult> validate(String zipPath) async {
    try {
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) {
        return const BackupResult(false, '올바른 백업 파일이 아니에요 (data.json 없음)');
      }
      final map =
          jsonDecode(utf8.decode(dataFile.content as List<int>)) as Map;
      if (!map.containsKey('schema_version')) {
        return const BackupResult(false, '백업 형식을 확인할 수 없어요');
      }
      return const BackupResult(true, '검증 완료');
    } catch (e) {
      return BackupResult(false, '파일을 읽는 중 오류가 났어요: $e');
    }
  }

  // 실제 복원: 기존 데이터 삭제 → JSON 파싱해 DB 복원 → 사진 파일 복사.
  // (호출부에서 "기존 데이터를 덮어씁니다" 확인을 받은 뒤 호출할 것)
  Future<BackupResult> importFromZip(String zipPath) async {
    try {
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) {
        return const BackupResult(false, '올바른 백업 파일이 아니에요');
      }
      final data =
          jsonDecode(utf8.decode(dataFile.content as List<int>)) as Map;

      final db = await _appDb.database;

      await db.transaction((txn) async {
        // 기존 데이터 전체 삭제
        await txn.delete(Tables.photos);
        await txn.delete(Tables.careLogs);
        await txn.delete(Tables.plants);

        for (final row in (data['plants'] as List? ?? [])) {
          await txn.insert(Tables.plants, Map<String, Object?>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (data['care_logs'] as List? ?? [])) {
          await txn.insert(
              Tables.careLogs, Map<String, Object?>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (data['photos'] as List? ?? [])) {
          await txn.insert(Tables.photos, Map<String, Object?>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      // 사진 파일 복사 (data.json 외 모든 파일)
      for (final f in archive.files) {
        if (!f.isFile || f.name == 'data.json') continue;
        final out = File(AppPaths.abs(f.name));
        out.parent.createSync(recursive: true);
        out.writeAsBytesSync(f.content as List<int>);
      }

      return const BackupResult(true, '복원이 완료됐어요');
    } catch (e) {
      return BackupResult(false, '복원 중 오류가 났어요: $e');
    }
  }
}
