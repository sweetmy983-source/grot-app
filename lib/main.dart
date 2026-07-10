// main.dart
// 역할: 앱 진입점. 테마 적용, provider 등록, 첫 화면(HomeShell) 연결.
//       완전 오프라인 앱 — 네트워크 관련 초기화는 존재하지 않는다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/home_shell.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'modules/plant/plant_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GrooApp());
}

class GrooApp extends StatelessWidget {
  const GrooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 모듈1: 화분 상태관리. 이후 모듈2~6 의 provider 도 여기에 등록한다.
        ChangeNotifierProvider(create: (_) => PlantProvider()),
      ],
      child: MaterialApp(
        title: AppConst.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeShell(),
      ),
    );
  }
}
