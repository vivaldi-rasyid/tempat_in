import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/calendar_controller.dart';
import 'controllers/report_controller.dart';
import 'controllers/reservation_controller.dart';
import 'controllers/room_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'repositories/mock/mock_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = LocalNotificationService();
  await notifications.init();

  final authController = AuthController(MockAuthRepository());
  await authController.restoreSession();

  final settingsController = SettingsController();
  final roomController = RoomController(MockRoomRepository());
  final reservationController = ReservationController(
    repository: MockReservationRepository(),
    roomController: roomController,
    notifications: notifications,
  );
  if (authController.currentUser != null) {
    await reservationController.loadForUser(authController.currentUser!.userId);
  }

  final reportController = ReportController(MockReportRepository());
  final calendarController = CalendarController(
    repository: MockCalendarRepository(),
    roomController: roomController,
    reservationController: reservationController,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider.value(value: roomController),
        ChangeNotifierProvider.value(value: reservationController),
        ChangeNotifierProvider.value(value: reportController),
        ChangeNotifierProvider.value(value: calendarController),
      ],
      child: TempatInApp(authController: authController),
    ),
  );
}

class TempatInApp extends StatelessWidget {
  final AuthController authController;

  const TempatInApp({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<SettingsController>().simulateOffline;
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: createRouter(authController),
      builder: (context, child) {
        return Column(
          children: [
            if (isOffline)
              Material(
                color: AppColors.primaryDark,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: const Text(
                      'Tidak ada koneksi internet. Menampilkan data lokal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}