// modules/photo/photo_provider.dart
// 역할: 특정 화분의 사진 목록 상태관리. 추가(카메라/갤러리)·삭제·대표사진 지정.
//       대표사진 지정은 PlantRepository.setMainPhoto 를 통해 plants 테이블을 갱신한다.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_paths.dart';
import '../plant/plant_repository.dart';
import 'photo_model.dart';
import 'photo_repository.dart';
import 'photo_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoRepository _repo;
  final PhotoService _service;
  final PlantRepository _plantRepo;

  PhotoProvider({
    PhotoRepository? repo,
    PhotoService? service,
    PlantRepository? plantRepo,
  })  : _repo = repo ?? PhotoRepository(),
        _service = service ?? PhotoService(),
        _plantRepo = plantRepo ?? PlantRepository();

  int? _plantId;
  List<Photo> _photos = [];
  int? _mainPhotoId;
  bool _loading = false;

  List<Photo> get photos => _photos;
  int? get mainPhotoId => _mainPhotoId;
  bool get loading => _loading;
  bool get isEmpty => !_loading && _photos.isEmpty;

  Future<void> loadFor(int plantId) async {
    _plantId = plantId;
    _loading = true;
    notifyListeners();
    _photos = await _repo.getByPlant(plantId);
    final plant = await _plantRepo.getById(plantId);
    _mainPhotoId = plant?.mainPhotoId;
    _loading = false;
    notifyListeners();
  }

  // 사진 추가: 촬영/선택 → 리사이즈 저장 → DB insert. 첫 사진이면 자동 대표 지정.
  Future<void> addFromSource(ImageSource source) async {
    if (_plantId == null) return;
    final rel = await _service.pickAndSave(source);
    if (rel == null) return; // 취소
    final id = await _repo.insert(Photo(
      plantId: _plantId!,
      filePath: rel,
      takenAt: DateTime.now(),
    ));
    final wasEmpty = _photos.isEmpty;
    await loadFor(_plantId!);
    if (wasEmpty) {
      await setMain(id);
    }
  }

  Future<void> setMain(int photoId) async {
    if (_plantId == null) return;
    await _plantRepo.setMainPhoto(_plantId!, photoId);
    _mainPhotoId = photoId;
    notifyListeners();
  }

  Future<void> delete(Photo photo) async {
    if (photo.id == null) return;
    // 파일 삭제
    final f = File(AppPaths.abs(photo.filePath));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await _repo.delete(photo.id!);
    // 대표사진이 삭제되면 대표 해제 (남은 사진 중 최신으로 대체)
    if (_mainPhotoId == photo.id && _plantId != null) {
      final remaining = await _repo.getByPlant(_plantId!);
      final newMain = remaining.isNotEmpty ? remaining.first.id : null;
      await _plantRepo.setMainPhoto(_plantId!, newMain);
    }
    if (_plantId != null) await loadFor(_plantId!);
  }
}
