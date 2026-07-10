// modules/history/care_log_provider.dart
// 역할: 특정 화분의 관리 이력 상태관리. 상세 화면 "이력" 탭에서 사용.
//       타입 필터, 추가/수정/삭제를 제공한다. 물주기(water) 기록은 모듈2가
//       자동으로 넣지만, 여기서도 직접 추가/조회/수정/삭제할 수 있다.

import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import 'care_log_model.dart';
import 'care_log_repository.dart';

class CareLogProvider extends ChangeNotifier {
  final CareLogRepository _repo;
  CareLogProvider({CareLogRepository? repo})
      : _repo = repo ?? CareLogRepository();

  int? _plantId;
  List<CareLog> _all = [];
  CareType? _filter; // null = 전체
  bool _loading = false;

  List<CareLog> get items => _filter == null
      ? _all
      : _all.where((e) => e.type == _filter).toList();
  CareType? get filter => _filter;
  bool get loading => _loading;
  bool get isEmpty => !_loading && _all.isEmpty;

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
    notifyListeners();
  }

  Future<void> add(CareLog log) async {
    await _repo.insert(log);
    if (_plantId != null) await loadFor(_plantId!);
  }

  Future<void> update(CareLog log) async {
    await _repo.update(log);
    if (_plantId != null) await loadFor(_plantId!);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    if (_plantId != null) await loadFor(_plantId!);
  }
}
