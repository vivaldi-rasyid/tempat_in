import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/calendar_controller.dart';
import '../../controllers/reservation_controller.dart';
import '../../controllers/room_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final roomCtrl = context.watch<RoomController>();
    final resCtrl = context.watch<ReservationController>();
    final settings = context.watch<SettingsController>();
    final calCtrl = context.read<CalendarController>();

    final savedRooms = roomCtrl.rooms
        .where((r) => roomCtrl.isBookmarked(r.roomId))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Gradient student profile header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.name ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Telkom Student',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIM: ${user?.nim ?? '-'} • Fakultas Informatika',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // My Bookings / History shortcut
            _SectionCard(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'My Bookings / History',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${resCtrl.activeReservations.length} aktif • ${resCtrl.pastReservations.length} selesai',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.myBookings),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Saved Rooms
            const Text(
              'Saved Rooms',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _SectionCard(
              children: savedRooms.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Belum ada ruangan yang disimpan.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ]
                  : savedRooms
                      .map(
                        (r) => ListTile(
                          leading: const Icon(
                            Icons.flag,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            r.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${r.building} • Lt. ${r.floor}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push(AppRoutes.roomDetailPath(r.roomId)),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),

            // Settings & Debug toggles
            const Text(
              'Settings',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _SectionCard(
              children: [
                SwitchListTile(
                  title: const Text('Notifikasi Pengingat'),
                  subtitle: const Text('Peringatan sebelum waktu check-out'),
                  value: settings.notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: settings.setNotificationsEnabled,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Waktu Peringatan Check-Out'),
                  subtitle: Text(
                    '${settings.warningLeadTime.inMinutes} menit sebelum selesai',
                  ),
                  trailing: DropdownButton<int>(
                    value: settings.warningLeadTime.inMinutes,
                    underline: const SizedBox.shrink(),
                    items: const [5, 10, 15, 20]
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m mnt'),
                          ),
                        )
                        .toList(),
                    onChanged: (m) {
                      if (m != null) {
                        settings.setWarningLeadTime(Duration(minutes: m));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Debug: Calendar API Failed'),
                  subtitle: const Text(
                    'Simulasikan gagal memuat kalender organisasi',
                  ),
                  value: settings.simulateCalendarFailure,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    settings.setSimulateCalendarFailure(v);
                    calCtrl.setSimulateApiFailure(v);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Debug: No Internet Banner'),
                  subtitle: const Text('Tampilkan banner mode offline'),
                  value: settings.simulateOffline,
                  activeColor: AppColors.primary,
                  onChanged: settings.setSimulateOffline,
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}