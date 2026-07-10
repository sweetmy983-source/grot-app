// modules/history/screens/care_log_edit_sheet.dart
// 역할: 관리 이력 추가/수정용 모달 바텀시트. 타입 선택 + 날짜(기본 오늘, 과거 가능) + 메모.
//       showCareLogEditSheet() 로 띄운다. 저장/삭제는 전달받은 CareLogProvider로 처리.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../care_log_model.dart';
import '../care_log_provider.dart';
import '../care_type_style.dart';

Future<void> showCareLogEditSheet(
  BuildContext context, {
  required CareLogProvider provider,
  required int plantId,
  CareLog? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CareLogEditSheet(
      provider: provider,
      plantId: plantId,
      existing: existing,
    ),
  );
}

class _CareLogEditSheet extends StatefulWidget {
  final CareLogProvider provider;
  final int plantId;
  final CareLog? existing;
  const _CareLogEditSheet({
    required this.provider,
    required this.plantId,
    this.existing,
  });

  @override
  State<_CareLogEditSheet> createState() => _CareLogEditSheetState();
}

class _CareLogEditSheetState extends State<_CareLogEditSheet> {
  late CareType _type;
  late DateTime _date;
  late final TextEditingController _memo;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? CareType.water;
    _date = widget.existing?.loggedAt ?? DateTime.now();
    _memo = TextEditingController(text: widget.existing?.memo ?? '');
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isEdit ? '이력 수정' : '이력 추가',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_isEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
                  onPressed: _delete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('종류', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CareType.values.map((t) {
              final style = CareTypeStyle.of(t);
              final selected = t == _type;
              return ChoiceChip(
                label: Text('${style.emoji} ${t.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: style.color.withOpacity(0.18),
                labelStyle: TextStyle(
                  color: selected ? style.color : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected ? style.color : Colors.transparent,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('날짜', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(DateFormat('yyyy년 M월 d일').format(_date)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('메모', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _memo,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '선택 입력'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? '저장' : '추가'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _date.hour,
            _date.minute,
          ));
    }
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final log = CareLog(
      id: widget.existing?.id,
      plantId: widget.plantId,
      type: _type,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      loggedAt: _date,
    );
    if (_isEdit) {
      await widget.provider.update(log);
    } else {
      await widget.provider.add(log);
    }
    navigator.pop();
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    if (widget.existing?.id != null) {
      await widget.provider.delete(widget.existing!.id!);
    }
    navigator.pop();
  }
}
