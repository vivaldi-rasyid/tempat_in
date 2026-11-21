class AppConstants {
  static const String appName = 'Tempat-In';
  static const String studentEmailDomain = '@student.telkomuniversity.ac.id';

  static const String demoEmail =
      'muhammad.vivaldi@student.telkomuniversity.ac.id';
  static const String demoPassword = 'password123';

  static const String prefLoggedInEmail = 'logged_in_email';
  static const Duration liveUpdateInterval = Duration(seconds: 6);
  static const Duration defaultCheckoutWarningLead = Duration(minutes: 10);
  static const Duration anomalyMaxDuration = Duration(hours: 6);
}

class AppRoutes {
  static const String login = '/login';
  static const String signIn = '/signin';
  static const String home = '/home';
  static const String search = '/search';
  static const String schedule = '/schedule';
  static const String profile = '/profile';
  static const String roomDetail = '/room/:id';
  static const String checkout = '/checkout/:reservationId';
  static const String reportRoom = '/room/:id/report';
  static const String myBookings = '/my-bookings';
  static const String qrScan = '/qr-scan';

  static String roomDetailPath(String id) => '/room/$id';
  static String checkoutPath(String reservationId) =>
      '/checkout/$reservationId';
  static String reportRoomPath(String id) => '/room/$id/report';
}