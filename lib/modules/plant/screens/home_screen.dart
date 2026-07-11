// modules/plant/screens/home_screen.dart
// 역할: 하단 탭1 "내 화분" 홈 화면. 화분 카드 목록 + 화분 추가 FAB.
//       연체 화분은 카드 상단(빨간 배지)으로 강조되고 목록 최상단에 정렬된다.
//       빈 상태(empty state) 안내 포함.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../plant_provider.dart';
import '../widgets/plant_card.dart';
import 'plant_detail_screen.dart';
import 'plant_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후 로드 (context 사용 안전)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('내 화분')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<PlantProvider>().load(),
        child: _buildBody(provider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(PlantProvider provider) {
    if (provider.loading && provider.plants.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.isEmpty) {
      return _emptyState();
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: provider.plants.length,
      itemBuilder: (context, i) {
        final plant = provider.plants[i];
        return _PlantCardTile(plantId: plant.id!);
      },
    );
  }

  Widget _emptyState() {
    // 스크롤 가능해야 당겨서 새로고침이 동작
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Center(child: Text('🪴', style: TextStyle(fontSize: 64))),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '아직 등록된 화분이 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            '오른쪽 아래 + 버튼으로 첫 화분을 추가해 보세요',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _openAdd,
            icon: const Icon(Icons.add),
            label: const Text('화분 추가'),
          ),
        ),
      ],
    );
  }

  Future<void> _openAdd() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PlantEditScreen()),
    );
    if (!mounted) return;
    context.read<PlantProvider>().load();
    if (result == 'added' || result == 'updated') {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(result == 'added' ? '새 화분을 등록했어요 🌱' : '화분 정보를 수정했어요'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ));
    }
  }
}

// 개별 카드 타일 — provider 목록에서 최신 plant 를 찾아 렌더.
class _PlantCardTile extends StatelessWidget {
  final int plantId;
  const _PlantCardTile({required this.plantId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();
    final idx = provider.plants.indexWhere((p) => p.id == plantId);
    if (idx < 0) return const SizedBox.shrink();
    final plant = provider.plants[idx];

    return PlantCard(
      plant: plant,
      mainPhotoPath: provider.mainPhotoPath(plantId),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final name = plant.name;
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => PlantDetailScreen(plantId: plant.id!),
          ),
        );
        if (!context.mounted) return;
        context.read<PlantProvider>().load();
        // 상세에서 삭제/보관하고 돌아온 경우 안내
        if (result == 'deleted') {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text("'$name' 화분을 삭제했어요"),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              duration: const Duration(seconds: 2),
            ));
        } else if (result == 'archived') {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text("'$name' 화분을 보관함으로 옮겼어요"),
              backgroundColor: AppColors.primaryDark,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              duration: const Duration(seconds: 2),
            ));
        }
      },
      onWater: () async {
        final messenger = ScaffoldMessenger.of(context);
        await context.read<PlantProvider>().water(plant);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('${plant.name}에게 물을 줬어요 💧'),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 2),
          ));
      },
    );
  }
}
