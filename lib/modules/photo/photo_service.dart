// modules/photo/photo_service.dart
// 역할: 카메라/갤러리에서 사진을 골라 긴 변 1600px로 리사이즈 후 앱 전용 폴더에 저장.
//       DB에는 상대경로만 넣으므로 여기선 저장된 '상대경로'를 반환한다 (명세 4번).

import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/app_paths.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  static const int _maxLongSide = 1600;

  // source: 카메라 또는 갤러리. 취소 시 null 반환.
  Future<String?> pickAndSave(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 3000,
      maxHeight: 3000,
      imageQuality: 95,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // 긴 변 기준 1600px로 축소 (이미 작으면 그대로)
    img.Image out = decoded;
    final longSide =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longSide > _maxLongSide) {
      if (decoded.width >= decoded.height) {
        out = img.copyResize(decoded, width: _maxLongSide);
      } else {
        out = img.copyResize(decoded, height: _maxLongSide);
      }
    }

    final relPath = AppPaths.newPhotoRelPath();
    final absPath = AppPaths.abs(relPath);
    await File(absPath).writeAsBytes(img.encodeJpg(out, quality: 88));
    return relPath;
  }
}
