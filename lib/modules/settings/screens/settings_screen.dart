// modules/settings/screens/settings_screen.dart
// 역할: 하단 탭3 "설정". 백업(내보내기/가져오기), 보관된 화분 보기, 알림 기본 안내, 앱 정보.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../backup/backup_service.dart';
import '../../plant/plant_model.dart';
import '../../plant/plant_provider.dart';
import '../../watering/watering_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _sectionTitle('백업'),
          _tile(
            context,
            icon: Icons.upload_file_outlined,
            title: '백업 내보내기',
            subtitle: '화분·이력·사진을 zip 하나로 저장/공유',
            onTap: () => _export(context),
          ),
          _tile(
            context,
            icon: Icons.download_outlined,
            title: '백업 가져오기',
            subtitle: 'zip에서 복원 (기존 데이터 덮어씀)',
            onTap: () => _import(context),
          ),
          const Divider(),
          _sectionTitle('데이터'),
          _tile(
            context,
            icon: Icons.inventory_2_outlined,
            title: '보관된 화분 보기',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ArchivedListScreen()),
            ),
          ),
          const Divider(),
          _sectionTitle('알림'),
          _tile(
            context,
            icon: Icons.notifications_active_outlined,
            title: '알림 기본 시각',
            subtitle: '새 화분은 기본 오전 9:00로 설정돼요 (화분별로 변경 가능)',
          ),
          const Divider(),
          _sectionTitle('정보'),
          _tile(
            context,
            icon: Icons.info_outline,
            title: '앱 정보',
            subtitle: '${AppConst.appName} · v1.0.0 · 완전 오프라인',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: AppConst.appName,
              applicationVersion: '1.0.0',
              children: const [
                Text('서버 없이 100% 내 폰에서만 동작하는 반려식물 관리 앱이에요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 백업 내보내기 ----------------
  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    _showLoading(context, '백업 파일을 만드는 중...');
    final service = BackupService();
    try {
      final zip = await service.exportToZip();
      if (context.mounted) Navigator.of(context).pop(); // 로딩 닫기
      await service.shareZip(zip);
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('내보내기 실패: $e')));
    }
  }

  // ---------------- 백업 가져오기 ----------------
  Future<void> _import(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final plantProvider = context.read<PlantProvider>();
    final watering = context.read<WateringProvider>();
    final service = BackupService();

    final path = await service.pickBackupZip();
    if (path == null) return; // 취소

    final valid = await service.validate(path);
    if (!valid.ok) {
      messenger.showSnackBar(SnackBar(content: Text(valid.message)));
      return;
    }

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('기존 데이터를 덮어씁니다'),
        content: const Text(
            '지금 앱에 있는 모든 화분·이력·사진이 삭제되고,\n선택한 백업으로 교체됩니다. 계속할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('덮어쓰기'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!context.mounted) return;
    _showLoading(context, '복원하는 중...');
    final result = await service.importFromZip(path);
    if (context.mounted) Navigator.of(context).pop(); // 로딩 닫기

    if (result.ok) {
      // DB 복원 후: 목록 갱신 + 알림 전체 재예약
      await plantProvider.load();
      await watering.rescheduleAll();
    }
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _showLoading(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// 보관된 화분 목록 — 복원 가능
class _ArchivedListScreen extends StatefulWidget {
  const _ArchivedListScreen();

  @override
  State<_ArchivedListScreen> createState() => _ArchivedListScreenState();
}

class _ArchivedListScreenState extends State<_ArchivedListScreen> {
  List<Plant> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await context.read<PlantProvider>().getArchived();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보관된 화분')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? const Center(
                  child: Text('보관된 화분이 없어요',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 0.5),
                  itemBuilder: (context, i) {
                    final p = _items[i];
                    return ListTile(
                      leading: const Text('🪴', style: TextStyle(fontSize: 24)),
                      title: Text(p.name),
                      subtitle: Text(p.species ?? ''),
                      trailing: TextButton(
                        onPressed: () async {
                          final watering = context.read<WateringProvider>();
                          await context
                              .read<PlantProvider>()
                              .archive(p.id!, archived: false);
                          await watering.onPlantSaved(p); // 복원 시 알림 재예약
                          await _load();
                        },
                        child: const Text('복원'),
                      ),
                    );
                  },
                ),
    );
  }
}
