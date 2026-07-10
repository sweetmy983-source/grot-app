// modules/history/care_type_style.dart
// 역할: 관리 이력 타입별 아이콘/색상 매핑 (모듈3 타임라인·필터칩, 모듈5 캘린더 색점 공용).

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

class CareTypeStyle {
  final IconData icon;
  final Color color;
  final String emoji;
  const CareTypeStyle(this.icon, this.color, this.emoji);

  static CareTypeStyle of(CareType type) {
    switch (type) {
      case CareType.water:
        return const CareTypeStyle(Icons.water_drop, AppColors.water, '💧');
      case CareType.fertilizer:
        return const CareTypeStyle(
            Icons.grass, AppColors.fertilizer, '🌾');
      case CareType.repot:
        return const CareTypeStyle(Icons.yard, AppColors.repot, '🪴');
      case CareType.prune:
        return const CareTypeStyle(
            Icons.content_cut, AppColors.prune, '✂️');
      case CareType.pest:
        return const CareTypeStyle(
            Icons.bug_report, AppColors.pest, '🐛');
      case CareType.etc:
        return const CareTypeStyle(Icons.more_horiz, AppColors.etc, '📝');
    }
  }
}
