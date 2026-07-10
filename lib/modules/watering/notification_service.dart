// modules/watering/notification_service.dart
// 역할: 로컬 알림의 저수준 처리 (초기화·권한요청·예약·취소).
//       flutter_local_notifications + timezone 사용. 재부팅 후에도 유지되도록
//       exactAllowWhileIdle 모드로 예약하고, 매니페스트에 BOOT_COMPLETED 리시버를 둔다.
//       (매니페스트/디슈가링 설정은 GitHub Actions 워크플로에서 자동 주입)

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../plant/plant_model.dart';
import '../plant/screens/plant_detail_screen.dart';

// 알림 탭 시 화면 이동에 쓰는 전역 네비게이터 키 (MaterialApp 에 연결).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'watering_channel';
  static const String _channelName = '물주기 알림';
  static const String _channelDesc = '화분별 물주기 예정일 알림';

  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;

    // 타임존 초기화 — 로컬 타임존 기준으로 예약하기 위함
    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // 타임존 이름을 못 구하면 기본값 유지 (예약은 계속 동작)
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    _inited = true;
  }

  // Android 13+ 알림 권한 + 정확한 알람 권한 요청
  Future<void> requestPermissions() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // 알림 탭 → 해당 화분 상세로 이동
  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final id = int.tryParse(payload);
    if (id == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: id)),
    );
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  // 화분의 다음 물주기 예정일에 알림 예약. 이미 지난 화분은 다음 알림 시각으로 잡는다.
  Future<void> scheduleForPlant(Plant plant) async {
    final id = plant.id;
    if (id == null || plant.isArchived) return;

    await cancel(id);

    final scheduled = _computeSchedule(plant);
    await _plugin.zonedSchedule(
      id,
      '${plant.name} 물 줄 시간이에요 💧',
      (plant.species ?? '').isEmpty
          ? '물주기 예정일이에요'
          : '${plant.species} · 물주기 예정일이에요',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: id.toString(),
    );
  }

  tz.TZDateTime _computeSchedule(Plant plant) {
    final now = tz.TZDateTime.now(tz.local);
    final due = plant.nextWateringDate;
    var t = tz.TZDateTime(
      tz.local,
      due.year,
      due.month,
      due.day,
      plant.notifyHour,
      plant.notifyMinute,
    );
    // 예정 시각이 이미 지났으면(연체) 오늘/내일의 알림 시각으로 밀어 준다.
    if (!t.isAfter(now)) {
      t = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        plant.notifyHour,
        plant.notifyMinute,
      );
      if (!t.isAfter(now)) {
        t = t.add(const Duration(days: 1));
      }
    }
    return t;
  }

  Future<void> cancel(int plantId) => _plugin.cancel(plantId);

  Future<void> cancelAll() => _plugin.cancelAll();
}
