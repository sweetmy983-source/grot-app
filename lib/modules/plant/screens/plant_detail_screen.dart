// modules/plant/screens/plant_detail_screen.dart
// 역할: 화분 상세. 대표사진 + 기본 정보 + "물 줬어요", 그리고 이력/사진 탭.
//       이력/사진은 각각 CareLogProvider / PhotoProvider 를 이 화면에서 provide 한다.
//       우상단 메뉴: 수정 / 보관하기 / 삭제 (알림 취소 연동).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_paths.dart';
import '../../../core/theme.dart';
import '../../history/care_log_provider.dart';
import '../../history/screens/care_history_tab.dart';
import '../../photo/photo_provider.dart';
import '../../photo/screens/photo_gallery_tab.dart';
import '../../watering/watering_provider.dart';
import '../plant_model.dart';
import '../plant_provider.dart';
import 'plant_edit_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  final int plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => CareLogProvider()..loadFor(plantId)),
        ChangeNotifierProvider(
            create: (_) => PhotoProvider()..loadFor(plantId)),
      ],
      child: _PlantDetailView(plantId: plantId),
    );
  }
}

class _PlantDetailView extends StatefulWidget {
  final int plantId;
  const _PlantDetailView({required this.plantId});

  @override
  State<_PlantDetailView> createState() => _PlantDetailViewState();
}

class _PlantDetailViewState extends State<_PlantDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Plant? _plant;
  bool _loading = true;

  CareLogProvider? _care;
  WateringProvider? _watering;
  int _careRev = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watering = context.read<WateringProvider>();
    final care = context.read<CareLogProvider>();
    if (!identical(_care, care)) {
      _care?.removeListener(_onCareChanged);
      _care = care;
      _careRev = care.revision;
      _care!.addListener(_onCareChanged);
    }
  }

  // 이력이 실제로 바뀌면(추가/수정/삭제) 헤더의 마지막/다음 물주기를 갱신하고
  // 알림을 재예약한다. (필터 변경 등은 revision 이 그대로라 무시)
  Future<void> _onCareChanged() async {
    final care = _care;
    if (care == null || care.revision == _careRev) return;
    _careRev = care.revision;
    await _reload();
    final p = _plant;
    if (p != null) await _watering?.onPlantSaved(p);
  }

  @override
  void dispose() {
    _care?.removeListener(_onCareChanged);
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
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
              children: [
                CareHistoryTab(plantId: widget.plantId),
                PhotoGalleryTab(plantId: widget.plantId),
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
          _mainPhoto(),
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

  // 대표사진: PhotoProvider 에서 main 사진을 찾아 표시 (없으면 이모지)
  Widget _mainPhoto() {
    final photoProvider = context.watch<PhotoProvider>();
    final mainId = photoProvider.mainPhotoId;
    String? path;
    for (final ph in photoProvider.photos) {
      if (ph.id == mainId) {
        path = AppPaths.abs(ph.filePath);
        break;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(kCardRadius),
      child: Container(
        height: 140,
        width: double.infinity,
        color: const Color(0xFFEAF3DE),
        child: (path != null && File(path).existsSync())
            ? Image.file(File(path), fit: BoxFit.cover)
            : const Center(child: Text('🌿', style: TextStyle(fontSize: 52))),
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
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
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
    final careProvider = context.read<CareLogProvider>();
    await context.read<PlantProvider>().water(plant);
    await _reload();
    await careProvider.loadFor(widget.plantId); // 물주기 기록 즉시 반영
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
    final watering = context.read<WateringProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    switch (v) {
      case 'edit':
        final result = await navigator.push<String>(
          MaterialPageRoute(builder: (_) => PlantEditScreen(existing: plant)),
        );
        await _reload();
        if (result == 'updated') {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('화분 정보를 수정했어요'),
              backgroundColor: AppColors.primaryDark,
              duration: Duration(seconds: 2),
            ));
        }
        break;
      case 'archive':
        await provider.archive(plant.id!);
        // 알림 취소 실패가 화면 복귀(pop + 결과 전달)를 막지 않도록 한다.
        try {
          await watering.onPlantRemoved(plant.id!);
        } catch (_) {}
        navigator.pop('archived');
        break;
      case 'delete':
        final ok = await _confirmDelete();
        if (ok == true) {
          await provider.delete(plant.id!);
          try {
            await watering.onPlantRemoved(plant.id!);
          } catch (_) {}
          navigator.pop('deleted');
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
              child: const Text('취소')),
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
