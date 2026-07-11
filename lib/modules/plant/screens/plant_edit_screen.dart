// modules/plant/screens/plant_edit_screen.dart
// 역할: 화분 등록/수정 폼. 애칭(필수)·품종·위치·물주기 주기(필수)·알림 시각·메모 입력.
//       대표사진 지정은 모듈4(photo) 연결 시 확장한다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../watering/watering_provider.dart';
import '../plant_model.dart';
import '../plant_provider.dart';

class PlantEditScreen extends StatefulWidget {
  final Plant? existing; // null 이면 신규 등록
  const PlantEditScreen({super.key, this.existing});

  @override
  State<PlantEditScreen> createState() => _PlantEditScreenState();
}

class _PlantEditScreenState extends State<PlantEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _location;
  late final TextEditingController _interval;
  late final TextEditingController _memo;
  late TimeOfDay _notifyTime;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _species = TextEditingController(text: p?.species ?? '');
    _location = TextEditingController(text: p?.location ?? '');
    _interval = TextEditingController(
      text: p != null ? p.wateringIntervalDays.toString() : '',
    );
    _memo = TextEditingController(text: p?.memo ?? '');
    _notifyTime = TimeOfDay(
      hour: p?.notifyHour ?? 9,
      minute: p?.notifyMinute ?? 0,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _location.dispose();
    _interval.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '화분 수정' : '화분 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('애칭 *'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: '예: 몬순이'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '애칭을 입력해 주세요' : null,
            ),
            _label('품종'),
            TextFormField(
              controller: _species,
              decoration: const InputDecoration(hintText: '예: 몬스테라'),
              textInputAction: TextInputAction.next,
            ),
            _label('위치'),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(hintText: '예: 거실 창가'),
              textInputAction: TextInputAction.next,
            ),
            _label('물주기 주기 (일) *'),
            TextFormField(
              controller: _interval,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '예: 7'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return '1 이상의 숫자를 입력해 주세요';
                return null;
              },
            ),
            _label('알림 시각'),
            _timePickerTile(),
            _label('메모'),
            TextFormField(
              controller: _memo,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '특이사항, 관리 팁 등'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? '저장' : '등록'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6, left: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _timePickerTile() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _notifyTime,
        );
        if (picked != null) setState(() => _notifyTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              _notifyTime.format(context),
              style: const TextStyle(fontSize: 15),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<PlantProvider>();
    final watering = context.read<WateringProvider>();
    final navigator = Navigator.of(context);

    final base = widget.existing;
    final plant = Plant(
      id: base?.id,
      name: _name.text.trim(),
      species: _species.text.trim().isEmpty ? null : _species.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      wateringIntervalDays: int.parse(_interval.text),
      lastWateredAt: base?.lastWateredAt,
      notifyHour: _notifyTime.hour,
      notifyMinute: _notifyTime.minute,
      mainPhotoId: base?.mainPhotoId,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      createdAt: base?.createdAt ?? DateTime.now(),
      isArchived: base?.isArchived ?? false,
    );

    if (_isEdit) {
      await provider.update(plant);
      await watering.onPlantSaved(plant);
      navigator.pop('updated');
    } else {
      final id = await provider.add(plant);
      await watering.onPlantSaved(plant.copyWith(id: id));
      navigator.pop('added');
    }
  }
}
