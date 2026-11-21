import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signin_screen.dart';
import '../views/home/home_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/room/checkout_screen.dart';
import '../views/room/my_bookings_screen.dart';
import '../views/room/qr_scan_screen.dart';
import '../views/room/report_room_screen.dart';
import '../views/room/room_detail_screen.dart';
import '../views/schedule/schedule_screen.dart';
import '../views/search/search_screen.dart';
import '../views/shell/main_shell.dart';
import 'constants.dart';

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final onAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signIn;
      if (!loggedIn && !onAuthPage) return AppRoutes.login;
      if (loggedIn && onAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navShell) => MainShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, __) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedule,
                builder: (_, __) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.roomDetail,
        builder: (_, state) =>
            RoomDetailScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, state) => CheckoutScreen(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reportRoom,
        builder: (_, state) =>
            ReportRoomScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.myBookings,
        builder: (_, __) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrScan,
        builder: (_, __) => const QrScanScreen(),
      ),
    ],
  );
}