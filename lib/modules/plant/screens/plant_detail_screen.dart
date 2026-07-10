// modules/plant/screens/plant_detail_screen.dart
// 역할: 화분 상세 화면. 대표사진 자리 + 기본 정보 + "물 줬어요" 버튼,
//       그리고 이력/사진 탭(모듈3·4 연결 전까지는 준비중 안내).
//       우상단 메뉴: 수정 / 보관하기 / 삭제.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../plant_model.dart';
import '../plant_provider.dart';
import 'plant_edit_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  final int plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Plant? _plant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final p = await context.read<PlantProvider>().getById(widget.plantId);
    if (!mounted) return;
    setState(() {
      _plant = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final plant = _plant;
    if (plant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('화분을 찾을 수 없어요')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(v, plant),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'archive', child: Text('보관하기')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _header(plant),
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: '이력'), Tab(text: '사진')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _ComingSoon(label: '관리 이력은 다음 단계(모듈3)에서 열려요'),
                _ComingSoon(label: '사진 갤러리는 다음 단계(모듈4)에서 열려요'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Plant plant) {
    final df = DateFormat('yyyy년 M월 d일');
    final last = plant.lastWateredAt;
    final days = plant.daysUntilNextWatering();

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3DE),
              borderRadius: BorderRadius.circular(kCardRadius),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 52))),
          ),
          const SizedBox(height: 14),
          _infoRow('품종', plant.species),
          _infoRow('위치', plant.location),
          _infoRow('물주기', '${plant.wateringIntervalDays}일마다 · '
              '${_two(plant.notifyHour)}:${_two(plant.notifyMinute)} 알림'),
          _infoRow('마지막 물주기', last == null ? '기록 없음' : df.format(last)),
          _infoRow(
            '다음 물주기',
            days < 0 ? '${-days}일 지남' : (days == 0 ? '오늘' : '$days일 후'),
            valueColor: days < 0 ? AppColors.danger : AppColors.primary,
          ),
          if ((plant.memo ?? '').isNotEmpty) _infoRow('메모', plant.memo),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _water(plant),
              child: const Text('물 줬어요 💧'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value, {Color? valueColor}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _water(Plant plant) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<PlantProvider>().water(plant);
    await _reload();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${plant.name}에게 물을 줬어요 💧'),
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onMenu(String v, Plant plant) async {
    final provider = context.read<PlantProvider>();
    final navigator = Navigator.of(context);

    switch (v) {
      case 'edit':
        await navigator.push(
          MaterialPageRoute(builder: (_) => PlantEditScreen(existing: plant)),
        );
        await _reload();
        break;
      case 'archive':
        await provider.archive(plant.id!);
        navigator.pop();
        break;
      case 'delete':
        final ok = await _confirmDelete();
        if (ok == true) {
          await provider.delete(plant.id!);
          navigator.pop();
        }
        break;
    }
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('완전 삭제'),
        content: const Text('이 화분과 모든 이력·사진이 영구 삭제됩니다.\n삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}
