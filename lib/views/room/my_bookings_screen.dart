import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/reservation_controller.dart';
import '../../controllers/room_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/reservation.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final resCtrl = context.watch<ReservationController>();
    final roomCtrl = context.watch<RoomController>();
    final active = resCtrl.activeReservations;
    final past = resCtrl.pastReservations;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings / History')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Active',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (active.isEmpty)
            const Text(
              'Tidak ada booking aktif.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...active.map((r) {
              final room = roomCtrl.getById(r.roomId);
              return Card(
                color: AppColors.cardBg,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    room?.name ?? r.roomId,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${_fmt(r.startTime)} – ${_fmt(r.endTime)}'),
                  trailing: const Icon(
                    Icons.timer_outlined,
                    color: AppColors.primary,
                  ),
                  onTap: () =>
                      context.push(AppRoutes.checkoutPath(r.reservationId)),
                ),
              );
            }),
          const SizedBox(height: 20),
          const Text(
            'Past',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (past.isEmpty)
            const Text(
              'Belum ada riwayat booking.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...past.map((r) {
              final room = roomCtrl.getById(r.roomId);
              final label = switch (r.status) {
                ReservationStatus.completed => 'Completed',
                ReservationStatus.cancelled => 'Cancelled',
                ReservationStatus.autoCheckedOut => 'Auto Check-Out',
                ReservationStatus.active => 'Active',
              };
              return Card(
                color: AppColors.cardBg,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    room?.name ?? r.roomId,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${_fmt(r.startTime)} – ${_fmt(r.endTime)}'),
                  trailing: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}