// modules/calendar/calendar_provider.dart
// 역할: 월별 캘린더 데이터 구성.
//   - 과거: 실제 수행한 관리 이력(care_logs) → 날짜별, 타입별 색점
//   - 미래: 활성 화분의 물주기 예정일(주기 기반 계산) → 초록 점
// 날짜 키는 자정(date-only)으로 정규화한다.

import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../history/care_log_model.dart';
import '../history/care_log_repository.dart';
import '../plant/plant_model.dart';
import '../plant/plant_repository.dart';

// 선택한 날짜의 항목 표시에 쓰는 뷰 모델
class CalendarEntry {
  final bool isFuture; // true=예정, false=실제 이력
  final int plantId;
  final String plantName;
  final CareType? type; // 이력이면 타입, 예정이면 물주기(water) 가정
  const CalendarEntry({
    required this.isFuture,
    required this.plantId,
    required this.plantName,
    this.type,
  });
}

class CalendarProvider extends ChangeNotifier {
  final CareLogRepository _careRepo;
  final PlantRepository _plantRepo;

  CalendarProvider({CareLogRepository? careRepo, PlantRepository? plantRepo})
      : _careRepo = careRepo ?? CareLogRepository(),
        _plantRepo = plantRepo ?? PlantRepository();

  final Map<int, Plant> _plantsById = {};
  final Map<DateTime, List<CareLog>> _pastByDay = {};
  final Map<DateTime, List<Plant>> _futureByDay = {};
  bool _loading = false;

  bool get loading => _loading;

  static DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _plantsById.clear();
    _pastByDay.clear();
    _futureByDay.clear();

    final allPlants = await _plantRepo.getAllPlants();
    for (final p in allPlants) {
      if (p.id != null) _plantsById[p.id!] = p;
    }

    // 과거 이력
    final logs = await _careRepo.getAll();
    for (final log in logs) {
      final k = dayKey(log.loggedAt);
      _pastByDay.putIfAbsent(k, () => []).add(log);
    }

    // 미래 물주기 예정 (활성 화분만, 오늘~90일 이내 반복)
    final today = dayKey(DateTime.now());
    final horizon = today.add(const Duration(days: 90));
    for (final p in allPlants) {
      if (p.isArchived) continue;
      final interval = p.wateringIntervalDays;
      if (interval <= 0) continue;
      var d = dayKey(p.nextWateringDate);
      while (d.isBefore(today)) {
        d = d.add(Duration(days: interval));
      }
      while (!d.isAfter(horizon)) {
        _futureByDay.putIfAbsent(d, () => []).add(p);
        d = d.add(Duration(days: interval));
      }
    }

    _loading = false;
    notifyListeners();
  }

  // 그 날의 색점 색상값 리스트 (과거 타입색 + 미래 초록)
  List<int> markers(DateTime day) {
    final k = dayKey(day);
    final result = <int>[];
    final past = _pastByDay[k];
    if (past != null) {
      // 타입 종류별로 하나씩만 (중복 제거)
      final types = <CareType>{};
      for (final log in past) {
        types.add(log.type);
      }
      for (final t in types) {
        result.add(_careColor(t));
      }
    }
    if (_futureByDay[k] != null && _futureByDay[k]!.isNotEmpty) {
      result.add(0xFF03C75A); // 초록 (예정)
    }
    return result;
  }

  // 선택 날짜 상세 목록 (예정 먼저, 그다음 이력)
  List<CalendarEntry> entriesFor(DateTime day) {
    final k = dayKey(day);
    final entries = <CalendarEntry>[];

    final future = _futureByDay[k];
    if (future != null) {
      for (final p in future) {
        entries.add(CalendarEntry(
          isFuture: true,
          plantId: p.id!,
          plantName: p.name,
          type: CareType.water,
        ));
      }
    }

    final past = _pastByDay[k];
    if (past != null) {
      for (final log in past) {
        final name = _plantsById[log.plantId]?.name ?? '화분';
        entries.add(CalendarEntry(
          isFuture: false,
          plantId: log.plantId,
          plantName: name,
          type: log.type,
        ));
      }
    }
    return entries;
  }

  int _careColor(CareType t) {
    switch (t) {
      case CareType.water:
        return 0xFF378ADD;
      case CareType.fertilizer:
        return 0xFFEF9F27;
      case CareType.repot:
        return 0xFF97C459;
      case CareType.prune:
        return 0xFF7F77DD;
      case CareType.pest:
        return 0xFFD85A30;
      case CareType.etc:
        return 0xFF888780;
    }
  }
}
