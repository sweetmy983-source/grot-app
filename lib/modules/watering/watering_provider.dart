// modules/watering/watering_provider.dart
// 역할: 물주기 & 알림의 조정자(coordinator). 화분 모듈과 알림 서비스를 이어 준다.
//   - 물 줬어요: care_logs 에 물주기 기록 + 알림 재예약
//   - 화분 등록/수정: 알림 재예약
//   - 화분 보관/삭제: 알림 취소
//   - 앱 시작: 모든 활성 화분 알림 검증/재예약 (재부팅 대비)
// 다른 모듈과의 결합을 줄이기 위해 PlantProvider 는 콜백(onWatered)으로만 연결한다.

import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../history/care_log_model.dart';
import '../history/care_log_repository.dart';
import '../plant/plant_model.dart';
import '../plant/plant_repository.dart';
import 'notification_service.dart';

class WateringProvider extends ChangeNotifier {
  final NotificationService _notif;
  final CareLogRepository _careRepo;
  final PlantRepository _plantRepo;

  WateringProvider({
    NotificationService? notif,
    CareLogRepository? careRepo,
    PlantRepository? plantRepo,
  })  : _notif = notif ?? NotificationService.instance,
        _careRepo = careRepo ?? CareLogRepository(),
        _plantRepo = plantRepo ?? PlantRepository();

  // PlantProvider.water() 에서 호출되는 콜백.
  Future<void> onWatered(Plant plant, DateTime wateredAt) async {
    if (plant.id != null) {
      await _careRepo.insert(CareLog(
        plantId: plant.id!,
        type: CareType.water,
        loggedAt: wateredAt,
      ));
    }
    await _notif.scheduleForPlant(plant);
  }

  // 화분 등록/수정 후 알림 재예약
  Future<void> onPlantSaved(Plant plant) async {
    await _notif.scheduleForPlant(plant);
  }

  // 화분 보관/삭제 시 알림 취소
  Future<void> onPlantRemoved(int plantId) async {
    await _notif.cancel(plantId);
  }

  // 앱 시작 시 전체 재예약 (재부팅/권한변경 대비)
  Future<void> rescheduleAll() async {
    await _notif.cancelAll();
    final plants = await _plantRepo.getPlants(archived: false);
    for (final p in plants) {
      await _notif.scheduleForPlant(p);
    }
  }

  Future<void> requestPermissions() => _notif.requestPermissions();
}
