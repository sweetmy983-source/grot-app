// modules/plant/plant_provider.dart
// 역할: 화분 목록/상세의 상태관리 (provider). UI 는 오직 이 provider 를 통해
//       화분 데이터를 읽고 변경한다. 홈 목록 정렬 규칙(연체 우선 → 임박 순)도 여기서 담당.
//
// 참고: "물 줬어요" 는 last_watered_at 갱신까지만 여기서 처리한다.
//       care_logs 기록 추가와 알림 재예약은 모듈2(watering)에서 이 provider 를
//       구독/호출해 연결한다. (모듈 간 결합 최소화)

import 'package:flutter/foundation.dart';

import '../../core/app_paths.dart';
import 'plant_model.dart';
import 'plant_repository.dart';

class PlantProvider extends ChangeNotifier {
  final PlantRepository _repo;
  PlantProvider({PlantRepository? repo}) : _repo = repo ?? PlantRepository();

  List<Plant> _plants = [];
  Map<int, String> _mainPhotoRel = {};
  bool _loading = false;

  List<Plant> get plants => _plants;
  bool get loading => _loading;
  bool get isEmpty => !_loading && _plants.isEmpty;

  // 홈 카드 썸네일용 대표사진 절대경로 (없으면 null)
  String? mainPhotoPath(int plantId) {
    final rel = _mainPhotoRel[plantId];
    return rel == null ? null : AppPaths.abs(rel);
  }

  // 물 준 뒤 UI 를 다른 모듈에 알리기 위한 콜백. 모듈2가 여기 등록해
  // care_logs 기록 + 알림 재예약을 수행한다.
  Future<void> Function(Plant plant, DateTime wateredAt)? onWatered;

  // 활성 화분 로드 + 정렬
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _plants = await _repo.getPlants(archived: false);
    _mainPhotoRel = await _repo.getMainPhotoRelPaths();
    _sort();
    _loading = false;
    notifyListeners();
  }

  // 연체(지난) 화분을 최상단, 그 안에서는 더 오래 지난 순 → 이후 임박 순.
  void _sort() {
    _plants.sort((a, b) {
      final da = a.daysUntilNextWatering();
      final db = b.daysUntilNextWatering();
      return da.compareTo(db);
    });
  }

  Future<int> add(Plant plant) async {
    final id = await _repo.insert(plant);
    await load();
    return id;
  }

  Future<void> update(Plant plant) async {
    await _repo.update(plant);
    await load();
  }

  Future<void> archive(int id, {bool archived = true}) async {
    await _repo.setArchived(id, archived);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }

  // 원터치 물주기: last_watered_at 갱신 후 모듈2 콜백 실행.
  Future<void> water(Plant plant, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    if (plant.id != null) {
      await _repo.updateLastWatered(plant.id!, when);
    }
    await load();
    // 갱신된 최신 화분을 콜백에 전달
    final updated = _plants.firstWhere(
      (p) => p.id == plant.id,
      orElse: () => plant.copyWith(lastWateredAt: when),
    );
    await onWatered?.call(updated, when);
  }

  // 상세 화면 등에서 특정 화분을 다시 읽어올 때
  Future<Plant?> getById(int id) => _repo.getById(id);

  Future<List<Plant>> getArchived() => _repo.getPlants(archived: true);
}
