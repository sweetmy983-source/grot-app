// core/app_paths.dart
// 역할: 앱 전용 documents 디렉토리와 사진 저장 폴더 경로 관리.
//   - DB에는 '상대경로'(예: photos/xxx.jpg)만 저장하고, 실제 접근 시 abs()로 절대경로 변환.
//   - 폰 교체/재설치(백업 복원) 후에도 사진이 깨지지 않게 하기 위함 (명세 2·4번).
// main()에서 init()을 먼저 호출해 docDir을 캐싱한다(카드 렌더 시 동기 접근 위함).

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

class AppPaths {
  AppPaths._();

  static String _docDir = '';

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _docDir = dir.path;
    // 사진 폴더 보장
    final photos = Directory(photosDir);
    if (!photos.existsSync()) {
      photos.createSync(recursive: true);
    }
  }

  static String get docDir => _docDir;

  // 사진 저장 폴더(절대경로)
  static String get photosDir => p.join(_docDir, AppConst.photoDirName);

  // 상대경로 → 절대경로
  static String abs(String relativePath) => p.join(_docDir, relativePath);

  // 절대경로 → documents 기준 상대경로
  static String rel(String absolutePath) =>
      p.relative(absolutePath, from: _docDir);

  // 사진 파일용 상대경로 생성 (photos/<타임스탬프>.jpg)
  static String newPhotoRelPath() {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    return p.join(AppConst.photoDirName, name);
  }
}
