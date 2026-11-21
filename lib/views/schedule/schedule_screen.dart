import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/calendar_controller.dart';
import '../../controllers/room_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/room.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  bool _lastPopupShownForFailure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cal = context.read<CalendarController>();
      final settings = context.read<SettingsController>();
      cal.setSimulateApiFailure(settings.simulateCalendarFailure);
      cal.loadForDate(cal.selectedDate);
    });
  }

  void _maybeShowCalendarErrorPopup(bool apiFailed) {
    if (apiFailed && !_lastPopupShownForFailure) {
      _lastPopupShownForFailure = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kalender Organisasi Gagal Dimuat'),
            content: const Text(
              'Data kalender organisasi tidak dapat dimuat. Menampilkan jadwal dari data internal saja.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    } else if (!apiFailed) {
      _lastPopupShownForFailure = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cal = context.watch<CalendarController>();
    final roomCtrl = context.watch<RoomController>();
    _maybeShowCalendarErrorPopup(cal.calendarApiFailed);

    final visible = cal.visibleEntries;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar matching P006-schedule.png
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go(AppRoutes.home),
                          icon: const Icon(Icons.chevron_left, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Expanded(
                          child: Text(
                            'Schedule',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD0D0D0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.bookmark_border,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                            tooltip: 'Saved Rooms',
                            onPressed: () => _showSavedRoomsSheet(
                              context,
                              roomCtrl,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (cal.calendarApiFailed) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Data kalender organisasi tidak dapat dimuat.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _MonthCalendarCard(
                      focusedMonth: cal.focusedMonth,
                      selectedDate: cal.selectedDate,
                      monthLabel:
                          '${_months[cal.focusedMonth.month - 1]} ${cal.focusedMonth.year}',
                      weekdays: _weekdays,
                      onPrevMonth: () => cal.changeMonth(-1),
                      onNextMonth: () => cal.changeMonth(1),
                      onSelectDate: cal.selectDate,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cal.showAllRooms ? 'All Rooms' : 'Available Room',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: cal.toggleShowAll,
                          child: Text(
                            cal.showAllRooms ? 'Available only' : 'See all',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (cal.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Tidak ada ruangan tersedia pada tanggal ini.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    return _ScheduledRoomTile(
                      entry: entry,
                      onTap: () => context
                          .push(AppRoutes.roomDetailPath(entry.room.roomId)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSavedRoomsSheet(BuildContext context, RoomController roomCtrl) {
    final saved = roomCtrl.rooms
        .where((r) => roomCtrl.isBookmarked(r.roomId))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Rooms',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (saved.isEmpty)
                const Text('Belum ada ruangan yang disimpan.')
              else
                ...saved.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.name),
                    subtitle: Text('${r.building} • Lt. ${r.floor}'),
                    trailing: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.roomDetailPath(r.roomId));
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final String monthLabel;
  final List<String> weekdays;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthCalendarCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.monthLabel,
    required this.weekdays,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final leadingDays = firstOfMonth.weekday - 1; // Mon = 0
    final gridStart = firstOfMonth.subtract(Duration(days: leadingDays));
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left, size: 22),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, size: 22),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              final isWeekend = i >= 5;
              return Expanded(
                child: Center(
                  child: Text(
                    weekdays[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isWeekend
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final day = gridStart.add(Duration(days: index));
              final inMonth = day.month == focusedMonth.month;
              final isWeekend = day.weekday == DateTime.saturday ||
                  day.weekday == DateTime.sunday;
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;

              Color textColor;
              if (isSelected) {
                textColor = Colors.white;
              } else if (!inMonth) {
                textColor = AppColors.textSecondary.withValues(alpha: 0.45);
              } else if (isWeekend) {
                textColor = AppColors.primary;
              } else {
                textColor = AppColors.textPrimary;
              }

              return InkWell(
                onTap: () => onSelectDate(day),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2B2B2B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.3)
                        : null,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScheduledRoomTile extends StatelessWidget {
  final ScheduledRoomEntry entry;
  final VoidCallback onTap;

  const _ScheduledRoomTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (entry.mergedStatus) {
      RoomStatus.available => ('Tersedia', AppColors.statusAvailable),
      RoomStatus.reserved => ('Dipesan', AppColors.statusReserved),
      RoomStatus.occupied => ('Digunakan', AppColors.statusOccupied),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                entry.room.imageUrls.first,
                width: 78,
                height: 78,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 78,
                  height: 78,
                  color: AppColors.inputBg,
                  child: const Icon(
                    Icons.meeting_room,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.room.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.room.building} • Lt. ${entry.room.floor}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (entry.reservedTimeRange != null)
                        Text(
                          entry.reservedTimeRange!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}