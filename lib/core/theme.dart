// core/theme.dart
// 역할: 네이버 그린 스타일의 앱 전역 테마와 색상 팔레트 정의.
//       밝은 화이트 배경 + 초록 포인트, 담백하고 여백 넉넉한 느낌.

import 'package:flutter/material.dart';

// 색상 팔레트 (명세 5번)
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF03C75A); // 네이버 그린 (핵심)
  static const Color primaryDark = Color(0xFF02A94D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F7F5); // 카드 배경 살짝 회녹색
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF767678);
  static const Color danger = Color(0xFFFF4E4E); // 물주기 지연 배지

  // 관리 이력 타입별 색 (모듈3·5 아이콘/점 색상)
  static const Color water = Color(0xFF378ADD);
  static const Color fertilizer = Color(0xFFEF9F27);
  static const Color repot = Color(0xFF97C459);
  static const Color prune = Color(0xFF7F77DD);
  static const Color pest = Color(0xFFD85A30);
  static const Color etc = Color(0xFF888780);
}

// 카드 공통 모서리 반경
const double kCardRadius = 16.0;

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.background,
        error: AppColors.danger,
      ),
      // AppBar: 흰 배경 + 초록 타이틀
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      // FAB: 초록
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        color: AppColors.background,
        elevation: 0.5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0.5,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        // Pretendard 있으면 우선 사용 (없으면 시스템 기본으로 폴백)
        fontFamily: 'Pretendard',
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 0.5,
      ),
    );
  }
}
