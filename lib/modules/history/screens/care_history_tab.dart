// modules/history/screens/care_history_tab.dart
// 역할: 화분 상세의 "이력" 탭 내용. 타입 필터칩 + 최신순 타임라인 + 추가 버튼.
//       CareLogProvider 를 구독한다(상위에서 provide + loadFor 호출).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../care_log_model.dart';
import '../care_log_provider.dart';
import '../care_type_style.dart';
import 'care_log_edit_sheet.dart';

class CareHistoryTab extends StatelessWidget {
  final int plantId;
  const CareHistoryTab({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareLogProvider>();

    return Column(
      children: [
        _filterBar(context, provider),
        Expanded(child: _body(context, provider)),
      ],
    );
  }

  Widget _filterBar(BuildContext context, CareLogProvider provider) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(context, provider, null, '전체'),
          ...CareType.values.map((t) {
            final s = CareTypeStyle.of(t);
            return _chip(context, provider, t, '${s.emoji} ${t.label}');
          }),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, CareLogProvider provider, CareType? type,
      String label) {
    final selected = provider.filter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => provider.setFilter(type),
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryDark : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide.none,
      ),
    );
  }

  Widget _body(BuildContext context, CareLogProvider provider) {
    if (provider.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final items = provider.items;
    return Stack(
      children: [
        if (items.isEmpty)
          Center(
            child: Text(
              provider.isEmpty ? '아직 기록된 이력이 없어요' : '해당 종류의 이력이 없어요',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
            itemCount: items.length,
            itemBuilder: (context, i) =>
                _timelineTile(context, provider, items[i]),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_care_$plantId',
            onPressed: () => showCareLogEditSheet(
              context,
              provider: provider,
              plantId: plantId,
            ),
            icon: const Icon(Icons.add),
            label: const Text('이력 추가'),
          ),
        ),
      ],
    );
  }

  Widget _timelineTile(
      BuildContext context, CareLogProvider provider, CareLog log) {
    final style = CareTypeStyle.of(log.type);
    return InkWell(
      onTap: () => showCareLogEditSheet(
        context,
        provider: provider,
        plantId: plantId,
        existing: log,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, size: 18, color: style.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.type.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy.MM.dd').format(log.loggedAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if ((log.memo ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      log.memo!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
