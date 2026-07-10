// main.dart
// 역할: 앱 진입점. 알림 초기화, provider 등록, 테마 적용, 첫 화면 연결.
//       앱 시작 시 알림 권한 요청 + 전체 화분 알림 재예약(재부팅 대비)을 수행한다.
//       완전 오프라인 앱 — 네트워크 초기화는 존재하지 않는다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/home_shell.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'modules/plant/plant_provider.dart';
import 'modules/watering/notification_service.dart';
import 'modules/watering/watering_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 알림 서비스 초기화 (타임존 포함)
  await NotificationService.instance.init();

  // 모듈 간 결합 최소화: 콜백으로만 연결
  final plantProvider = PlantProvider();
  final wateringProvider = WateringProvider();
  plantProvider.onWatered = wateringProvider.onWatered;

  runApp(GrooApp(
    plantProvider: plantProvider,
    wateringProvider: wateringProvider,
  ));
}

class GrooApp extends StatefulWidget {
  final PlantProvider plantProvider;
  final WateringProvider wateringProvider;

  const GrooApp({
    super.key,
    required this.plantProvider,
    required this.wateringProvider,
  });

  @override
  State<GrooApp> createState() => _GrooAppState();
}

class _GrooAppState extends State<GrooApp> {
  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후: 알림 권한 요청 → 전체 알림 재예약
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.wateringProvider.requestPermissions();
      await widget.wateringProvider.rescheduleAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.plantProvider),
        ChangeNotifierProvider.value(value: widget.wateringProvider),
      ],
      child: MaterialApp(
        title: AppConst.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey, // 알림 탭 → 화면 이동
        theme: AppTheme.light(),
        home: const HomeShell(),
      ),
    );
  }
}
