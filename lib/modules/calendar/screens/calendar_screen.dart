// modules/calendar/screens/calendar_screen.dart
// 역할: 하단 탭2 "캘린더". 월별 스케줄 화면. (모듈5에서 table_calendar 로 구현 예정)

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📅', style: TextStyle(fontSize: 56)),
              SizedBox(height: 12),
              Text(
                '월별 캘린더는 다음 단계(모듈5)에서 열려요',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
