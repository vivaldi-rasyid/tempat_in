import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/reservation_controller.dart';
import '../../controllers/room_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/room.dart';
import '../widgets/common_widgets.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _pageCtrl = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _sourceLabel(RoomUpdateSource source) => switch (source) {
        RoomUpdateSource.manual => 'manual',
        RoomUpdateSource.checkIn => 'check-in',
        RoomUpdateSource.calendar => 'calendar',
      };

  void _showMoreSheet(BuildContext context, Room room) {
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
              Text(
                room.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(room.description, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                'Building: ${room.building} • Floor ${room.floor}\n'
                'Capacity: ${room.capacity} students\n'
                'Facilities: ${room.facilities.join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDurationPicker(BuildContext context, Room room) async {
    Duration selected = const Duration(hours: 1);
    int customMinutes = 90;
    bool useCustom = false;

    final chosen = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final presets = [
            ('30 min', const Duration(minutes: 30)),
            ('1 hour', const Duration(hours: 1)),
            ('2 hours', const Duration(hours: 2)),
          ];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Book ${room.name}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...presets.map(
                        (p) => ChoiceChip(
                          label: Text(p.$1),
                          selected: !useCustom && selected == p.$2,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: !useCustom && selected == p.$2
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          onSelected: (_) => setSheetState(() {
                            useCustom = false;
                            selected = p.$2;
                          }),
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Custom'),
                        selected: useCustom,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: useCustom
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) => setSheetState(() {
                          useCustom = true;
                        }),
                      ),
                    ],
                  ),
                  if (useCustom) ...[
                    const SizedBox(height: 12),
                    Text('Custom duration: $customMinutes minutes'),
                    Slider(
                      value: customMinutes.toDouble(),
                      min: 15,
                      max: 420,
                      divisions: 27,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setSheetState(() => customMinutes = v.round()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusAvailable,
                    ),
                    onPressed: () => Navigator.pop(
                      ctx,
                      useCustom
                          ? Duration(minutes: customMinutes)
                          : selected,
                    ),
                    child: const Text('Confirm & Check In'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (chosen == null || !context.mounted) return;
    final userId =
        context.read<AuthController>().currentUser?.userId ?? 'usr-001';
    final res = await context.read<ReservationController>().bookAndCheckIn(
          userId: userId,
          roomId: room.roomId,
          duration: chosen,
        );
    if (context.mounted) {
      context.push(AppRoutes.checkoutPath(res.reservationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomCtrl = context.watch<RoomController>();
    final resCtrl = context.watch<ReservationController>();
    final userId =
        context.watch<AuthController>().currentUser?.userId ?? 'usr-001';

    final room = roomCtrl.getById(widget.roomId);
    if (room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Room not found.')),
      );
    }

    final gallery = room.imageUrls.length >= 3
        ? room.imageUrls
        : [room.imageUrls.first, room.imageUrls.first, room.imageUrls.first];
    final isBookmarked = roomCtrl.isBookmarked(room.roomId);
    final isMine = roomCtrl.isOccupiedByCurrentUser(room.roomId, userId);
    final activeRes = resCtrl.activeReservationForRoom(room.roomId);
    final isAvailable = room.status == RoomStatus.available;
    final isReserved = room.status == RoomStatus.reserved;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Top bar matching P003-detail.png
            Row(
              children: [
                _SquareIconBtn(
                  icon: Icons.chevron_left,
                  onTap: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    room.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SquareIconBtn(
                  icon: Icons.more_horiz,
                  onTap: () => _showMoreSheet(context, room),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image carousel + bookmark flag + dot indicators
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 230,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: gallery.length,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        gallery[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.inputBg,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.meeting_room,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: InkWell(
                        onTap: () => roomCtrl.toggleBookmark(room.roomId),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBookmarked ? Icons.flag : Icons.outlined_flag,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          gallery.length,
                          (i) => Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _pageIndex
                                  ? Colors.blueAccent
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reserved time range banner (P003b-detail-reserved.png)
            if (isReserved) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Reserved: 14:00 – 16:00',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.schedule),
                    child: const Text('View Schedule'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Facility icon chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: room.facilities
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FacilityChip(label: f),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Room name + status badge + location + Report icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(status: room.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${room.building}, Lt. ${room.floor} •${room.capacity} seats',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                _SquareIconBtn(
                  icon: Icons.feedback_outlined,
                  onTap: () =>
                      context.push(AppRoutes.reportRoomPath(room.roomId)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Last updated + Predicted availability chip
            Text(
              'Last updated: ${_formatTime(room.lastUpdatedAt)} (${_sourceLabel(room.lastUpdatedSource)})',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_graph,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roomCtrl.predictedAvailability(room),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Crowdsourcing one-tap action
            if (isAvailable)
              OutlinedButton.icon(
                onPressed: () =>
                    roomCtrl.markOccupiedManual(room.roomId, userId),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Saya Masuk (Occupied Manual)'),
              )
            else if (room.status == RoomStatus.occupied && isMine)
              OutlinedButton.icon(
                onPressed: () => roomCtrl.markAvailableManual(room.roomId),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Saya Keluar (Set Available)'),
              )
            else if (room.status == RoomStatus.occupied)
              OutlinedButton.icon(
                onPressed: () => roomCtrl.confirmOccupied(room.roomId),
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Confirm Occupied'),
              ),
            if (activeRes != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.checkoutPath(activeRes.reservationId)),
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Open Active Check-Out Timer'),
              ),
            ],
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              room.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            // Gallery thumbnails
            const Text(
              'Gallery',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        gallery[i],
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 76,
                          color: AppColors.inputBg,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Book Now CTA
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable
                    ? AppColors.statusAvailable
                    : const Color(0xFFAFAFAF),
                disabledBackgroundColor: const Color(0xFFAFAFAF),
                disabledForegroundColor: Colors.white,
              ),
              onPressed:
                  isAvailable ? () => _openDurationPicker(context, room) : null,
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}