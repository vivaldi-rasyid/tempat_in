import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/room_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/room.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pusat Bantuan Tempat-In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                'Butuh bantuan terkait status ruangan atau peminjaman di Telkom University?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.support_agent, color: AppColors.primary),
                title: Text('Helpdesk Logistik Tel-U'),
                subtitle: Text('helpdesk@telkomuniversity.ac.id'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final roomCtrl = context.watch<RoomController>();
    final recommended = roomCtrl.recommendedRooms;
    final availableNow = roomCtrl.availableNow;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Header matching P002-home.png
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.inputBg,
                  child: Text(
                    (user?.name ?? 'V')[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Telkom Student',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: () => _showHelpSheet(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: RoomCategory.values.map((cat) {
                  final active = roomCtrl.selectedCategory == cat;
                  final icon = switch (cat) {
                    RoomCategory.classroom => Icons.cast_for_education,
                    RoomCategory.meetingRoom => Icons.meeting_room_outlined,
                    RoomCategory.studySpace => Icons.desk_outlined,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => roomCtrl.selectCategory(cat),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: active ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // Recommended section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.search),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 266,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final room = recommended[index];
                  return RoomCard(
                    room: room,
                    isBookmarked: roomCtrl.isBookmarked(room.roomId),
                    onToggleBookmark: () =>
                        roomCtrl.toggleBookmark(room.roomId),
                    onTap: () =>
                        context.push(AppRoutes.roomDetailPath(room.roomId)),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // Available now / Nearby
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Now / Nearby',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${availableNow.length} rooms',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (availableNow.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada ruangan kosong saat ini.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...availableNow.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoomCard(
                    room: room,
                    compact: true,
                    onTap: () =>
                        context.push(AppRoutes.roomDetailPath(room.roomId)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}