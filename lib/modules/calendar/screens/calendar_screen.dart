// modules/calendar/screens/calendar_screen.dart
// 역할: 하단 탭2 "캘린더". 월 단위 달력에 과거 이력(타입색 점)/미래 물주기 예정(초록 점)을
//       표시하고, 날짜를 탭하면 그 날의 이력·예정 목록을 아래에 보여준다.
//       목록 항목을 탭하면 해당 화분 상세로 이동한다.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../history/care_type_style.dart';
import '../../plant/screens/plant_detail_screen.dart';
import '../calendar_provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarProvider()..load(),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = CalendarProvider.dayKey(DateTime.now());
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2015, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.month: '월',
              CalendarFormat.twoWeeks: '2주',
              CalendarFormat.week: '주',
            },
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = CalendarProvider.dayKey(selected);
                _focusedDay = focused;
              });
            },
            onFormatChanged: (f) => setState(() => _format = f),
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0x3303C75A),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: AppColors.primaryDark),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              formatButtonTextStyle: TextStyle(color: AppColors.textPrimary),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final colors = provider.markers(day);
                if (colors.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: colors
                        .take(4)
                        .map((c) => Container(
                              width: 6,
                              height: 6,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                              ),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _dayList(context, provider)),
        ],
      ),
    );
  }

  Widget _dayList(BuildContext context, CalendarProvider provider) {
    final entries = provider.entriesFor(_selectedDay);
    final header = DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(header,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text('이 날은 기록/예정이 없어요',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final style = CareTypeStyle.of(e.type ?? CareType.water);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            (e.isFuture ? AppColors.primary : style.color)
                                .withOpacity(0.15),
                        child: Text(
                          e.isFuture ? '💧' : style.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      title: Text(e.plantName),
                      subtitle: Text(e.isFuture
                          ? '물주기 예정'
                          : (e.type?.label ?? '기록')),
                      trailing: e.isFuture
                          ? const Text('예정',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600))
                          : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PlantDetailScreen(plantId: e.plantId),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
