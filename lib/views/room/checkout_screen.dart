import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/reservation_controller.dart';
import '../../controllers/room_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/reservation.dart';
import '../widgets/common_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  final String reservationId;

  const CheckoutScreen({super.key, required this.reservationId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Timer? _ticker;
  bool _dialogShownForWarning = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final resCtrl = context.watch<ReservationController>();
    final roomCtrl = context.watch<RoomController>();
    final reservation = resCtrl.getById(widget.reservationId);

    if (reservation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-Out')),
        body: const Center(child: Text('Reservation not found.')),
      );
    }

    final room = roomCtrl.getById(reservation.roomId);
    final remaining = reservation.endTime.difference(DateTime.now());
    final warningMsg = resCtrl.activeWarningMessage;

    if (warningMsg != null && !_dialogShownForWarning) {
      _dialogShownForWarning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pengingat Check-Out'),
            content: Text(warningMsg),
            actions: [
              TextButton(
                onPressed: () {
                  resCtrl.dismissWarningBanner();
                  Navigator.pop(ctx);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    } else if (warningMsg == null) {
      _dialogShownForWarning = false;
    }

    final isActive = reservation.status == ReservationStatus.active;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Top bar matching P004-checkout.png
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left, size: 28),
                ),
                Expanded(
                  child: Text(
                    room?.name ?? reservation.roomId,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Simulate 10-min warning',
                  onPressed: isActive
                      ? () => resCtrl.simulateWarning(reservation.reservationId)
                      : null,
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (warningMsg != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warningMsg,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (room != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  room.imageUrls.first,
                  height: 210,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 210,
                    color: AppColors.inputBg,
                    alignment: Alignment.center,
                    child: const Icon(Icons.meeting_room, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Live countdown display matching P004-checkout.png
            Center(
              child: Column(
                children: [
                  const Text(
                    'Remaining Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? _formatCountdown(remaining) : '00:00:00',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (room != null) ...[
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
              Text(
                '${room.building} • Lt. ${room.floor}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                room.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Big red Check Out button
            ElevatedButton(
              onPressed: isActive
                  ? () async {
                      await resCtrl.checkOutEarly(reservation.reservationId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Check-out berhasil. Ruangan tersedia.'),
                          ),
                        );
                        context.go(AppRoutes.home);
                      }
                    }
                  : null,
              child: Text(isActive ? 'Check Out' : 'Session Ended'),
            ),
          ],
        ),
      ),
    );
  }
}