// modules/history/care_log_provider.dart
// 역할: 특정 화분의 관리 이력 상태관리. 상세 화면 "이력" 탭에서 사용.
//       타입 필터, 추가/수정/삭제를 제공한다.
//
// 물주기 반영: 이력이 바뀔 때마다 '물주기(water)' 이력 중 가장 최근 날짜를
//   화분의 last_watered_at 에 반영한다 → 다음 물주기 예정일/알림이 이력과 일치하게 된다.
//   데이터가 실제로 바뀌면 revision 을 올려, 상세 화면이 헤더 갱신·알림 재예약을 하도록 신호한다.

import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../plant/plant_repository.dart';
import 'care_log_model.dart';
import 'care_log_repository.dart';

class CareLogProvider extends ChangeNotifier {
  final CareLogRepository _repo;
  final PlantRepository _plantRepo;
  CareLogProvider({CareLogRepository? repo, PlantRepository? plantRepo})
      : _repo = repo ?? CareLogRepository(),
        _plantRepo = plantRepo ?? PlantRepository();

  int? _plantId;
  List<CareLog> _all = [];
  CareType? _filter; // null = 전체
  bool _loading = false;

  // 이력 데이터가 실제로 바뀐 횟수 (필터 변경은 포함하지 않음).
  // 상세 화면이 이 값 변화를 보고 헤더 갱신 + 알림 재예약을 한다.
  int revision = 0;

  List<CareLog> get items =>
      _filter == null ? _all : _all.where((e) => e.type == _filter).toList();
  CareType? get filter => _filter;
  bool get loading => _loading;
  bool get isEmpty => !_loading && _all.isEmpty;

  // 물주기 이력 중 가장 최근 날짜 (없으면 null)
  DateTime? get latestWaterDate {
    DateTime? latest;
    for (final l in _all) {
      if (l.type == CareType.water) {
        if (latest == null || l.loggedAt.isAfter(latest)) latest = l.loggedAt;
      }
    }
    return latest;
  }

  Future<void> loadFor(int plantId) async {
    _plantId = plantId;
    _loading = true;
    notifyListeners();
    _all = await _repo.getByPlant(plantId);
    _loading = false;
    notifyListeners();
  }

  void setFilter(CareType? type) {
    _filter = type;
    notifyListeners(); // 필터만 바뀜 → revision 은 그대로 (재예약 불필요)
  }

  Future<void> add(CareLog log) async {
    await _repo.insert(log);
    await _reloadAfterChange();
  }

  Future<void> update(CareLog log) async {
    await _repo.update(log);
    await _reloadAfterChange();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _reloadAfterChange();
  }

  // 이력 변경 후: 목록 재로딩 + last_watered_at 동기화 + revision 증가.
  Future<void> _reloadAfterChange() async {
    if (_plantId == null) return;
    _all = await _repo.getByPlant(_plantId!);
    // 가장 최근 물주기 날짜를 화분 last_watered_at 에 반영 (없으면 null)
    await _plantRepo.setLastWatered(_plantId!, latestWaterDate);
    revision++;
    notifyListeners();
  }
}
