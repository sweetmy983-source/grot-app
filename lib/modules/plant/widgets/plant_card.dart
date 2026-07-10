// modules/plant/widgets/plant_card.dart
// 역할: 홈 목록의 화분 카드 한 장. 대표사진 자리, 애칭, "물주기 D-3" 남은 일수,
//       연체 시 빨간 배지, 원터치 "물 줬어요" 버튼을 표시한다.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../plant_model.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final String? mainPhotoPath; // 대표사진 절대경로 (없으면 이모지 플레이스홀더)
  final VoidCallback onTap;
  final VoidCallback onWater;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    required this.onWater,
    this.mainPhotoPath,
  });

  @override
  Widget build(BuildContext context) {
    final days = plant.daysUntilNextWatering();
    final overdue = days < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: overdue
            ? const BorderSide(color: AppColors.danger, width: 1.5)
            : BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kCardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _thumbnail(),
              const SizedBox(width: 12),
              Expanded(child: _info(days, overdue)),
              const SizedBox(width: 8),
              _waterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    Widget child;
    if (mainPhotoPath != null && File(mainPhotoPath!).existsSync()) {
      child = Image.file(File(mainPhotoPath!), fit: BoxFit.cover);
    } else {
      child = const Center(child: Text('🌱', style: TextStyle(fontSize: 26)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        color: const Color(0xFFEAF3DE),
        child: child,
      ),
    );
  }

  Widget _info(int days, bool overdue) {
    final subtitleParts = [
      if ((plant.species ?? '').isNotEmpty) plant.species!,
      if ((plant.location ?? '').isNotEmpty) plant.location!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                plant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (overdue) ...[
              const SizedBox(width: 6),
              _overdueBadge(days),
            ],
          ],
        ),
        if (subtitleParts.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitleParts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          _dLabel(days),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: overdue ? AppColors.danger : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _overdueBadge(int days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${-days}일 지남',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // D-day 라벨: 오늘=D-day, 미래=D-n, 과거=D+n
  String _dLabel(int days) {
    if (days == 0) return '물주기 D-day';
    if (days > 0) return '물주기 D-$days';
    return '물주기 D+${-days}';
  }

  Widget _waterButton() {
    return InkWell(
      onTap: onWater,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('💧', style: TextStyle(fontSize: 17)),
        ),
      ),
    );
  }
}
