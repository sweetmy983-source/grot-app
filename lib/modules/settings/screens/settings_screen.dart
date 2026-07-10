// modules/settings/screens/settings_screen.dart
// 역할: 하단 탭3 "설정". 백업(모듈6), 보관된 화분 보기, 알림 기본 시각, 앱 정보.
//       지금 단계에서는 "보관된 화분 보기"와 "앱 정보"만 동작하고
//       백업/알림 기본 시각은 이후 단계에서 연결된다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../plant/plant_model.dart';
import '../../plant/plant_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _sectionTitle('데이터'),
          _tile(
            context,
            icon: Icons.inventory_2_outlined,
            title: '보관된 화분 보기',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ArchivedListScreen()),
            ),
          ),
          _tile(
            context,
            icon: Icons.backup_outlined,
            title: '백업 (내보내기 / 가져오기)',
            subtitle: '다음 단계(모듈6)에서 열려요',
            enabled: false,
          ),
          const Divider(),
          _sectionTitle('알림'),
          _tile(
            context,
            icon: Icons.notifications_outlined,
            title: '알림 기본 시각',
            subtitle: '다음 단계(모듈2)에서 열려요',
            enabled: false,
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

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: enabled ? AppColors.primary : Colors.grey),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// 보관된 화분 목록 — 복원/완전삭제 가능
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
                  child: Text(
                    '보관된 화분이 없어요',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
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
                          await context
                              .read<PlantProvider>()
                              .archive(p.id!, archived: false);
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
