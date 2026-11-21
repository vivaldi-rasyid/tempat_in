import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../models/calendar_event.dart';
import '../../models/reservation.dart';
import '../../models/room.dart';
import '../../models/room_report.dart';
import '../../models/user.dart';
import '../repositories.dart';
import 'mock_data.dart';

class MockAuthRepository implements AuthRepository {
  User? _currentUser;

  @override
  Future<User?> restoreSession() async {
    if (_currentUser != null) return _currentUser;
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(AppConstants.prefLoggedInEmail);
    if (savedEmail == null || savedEmail.isEmpty) return null;
    _currentUser = _userFromEmail(savedEmail);
    return _currentUser;
  }

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final normalized = email.trim().toLowerCase();
    _validateCredentials(normalized, password);
    _currentUser = _userFromEmail(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLoggedInEmail, normalized);
    return _currentUser!;
  }

  @override
  Future<User> loginWithSso() async {
    await Future.delayed(const Duration(milliseconds: 550));
    _currentUser = MockData.demoUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefLoggedInEmail,
      MockData.demoUser.email,
    );
    return _currentUser!;
  }

  @override
  Future<User> signUp(String email, String password) async {
    // shortcut: mock sign-up uses the same in-memory student account flow; upgrade when real SSO/registration API exists.
    return login(email, password);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefLoggedInEmail);
  }

  void _validateCredentials(String email, String password) {
    if (!email.endsWith(AppConstants.studentEmailDomain) ||
        email.length <= AppConstants.studentEmailDomain.length ||
        email.contains(' ')) {
      throw const FormatException(
        'Use a valid @student.telkomuniversity.ac.id email.',
      );
    }
    if (password.trim().isEmpty) {
      throw const FormatException('Password cannot be empty.');
    }
    if (email == AppConstants.demoEmail &&
        password != AppConstants.demoPassword) {
      throw const FormatException('Incorrect password for demo account.');
    }
  }

  User _userFromEmail(String email) {
    if (email == AppConstants.demoEmail) return MockData.demoUser;
    final local = email.split('@').first;
    final displayName = local
        .split(RegExp(r'[._-]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
    return User(
      userId: 'usr-${local.hashCode.abs()}',
      name: displayName.isEmpty ? 'Telkom Student' : displayName,
      nim: '130122${(local.hashCode.abs() % 9000) + 1000}',
      email: email,
    );
  }
}

class MockRoomRepository implements RoomRepository {
  final List<Room> _rooms = MockData.seedRooms();
  final _controller = StreamController<List<Room>>.broadcast();
  final _rng = Random(42);
  Timer? _timer;

  MockRoomRepository({Duration? tickInterval}) {
    final interval = tickInterval ?? AppConstants.liveUpdateInterval;
    _timer = Timer.periodic(interval, (_) => _simulateStatusFlip());
  }

  @override
  Future<List<Room>> getRooms() async => List.unmodifiable(_rooms);

  @override
  Future<Room?> getRoomById(String roomId) async {
    for (final room in _rooms) {
      if (room.roomId == roomId) return room;
    }
    return null;
  }

  @override
  Future<Room> updateRoomStatus(
    String roomId,
    RoomStatus status,
    RoomUpdateSource source,
  ) async {
    final idx = _rooms.indexWhere((r) => r.roomId == roomId);
    if (idx == -1) throw StateError('Room $roomId not found');
    _rooms[idx] = _rooms[idx].copyWith(
      status: status,
      lastUpdatedAt: DateTime.now(),
      lastUpdatedSource: source,
    );
    _controller.add(List.unmodifiable(_rooms));
    return _rooms[idx];
  }

  @override
  Stream<List<Room>> watchRooms() => _controller.stream;

  void _simulateStatusFlip() {
    if (_rooms.isEmpty || _controller.isClosed) return;
    final idx = _rng.nextInt(_rooms.length);
    final current = _rooms[idx];
    final nextStatuses =
        RoomStatus.values.where((s) => s != current.status).toList();
    final next = nextStatuses[_rng.nextInt(nextStatuses.length)];
    final sources = RoomUpdateSource.values;
    _rooms[idx] = current.copyWith(
      status: next,
      lastUpdatedAt: DateTime.now(),
      lastUpdatedSource: sources[_rng.nextInt(sources.length)],
    );
    _controller.add(List.unmodifiable(_rooms));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

class MockReservationRepository implements ReservationRepository {
  final List<Reservation> _items = MockData.seedReservations();

  @override
  Future<List<Reservation>> getReservationsForUser(String userId) async {
    return _items.where((r) => r.userId == userId).toList(growable: false);
  }

  @override
  Future<Reservation> createReservation(Reservation reservation) async {
    _items.insert(0, reservation);
    return reservation;
  }

  @override
  Future<Reservation> updateStatus(
    String reservationId,
    ReservationStatus status,
  ) async {
    final idx = _items.indexWhere((r) => r.reservationId == reservationId);
    if (idx == -1) throw StateError('Reservation $reservationId not found');
    _items[idx] = _items[idx].copyWith(status: status);
    return _items[idx];
  }
}

class MockReportRepository implements ReportRepository {
  final List<RoomReport> _items = MockData.seedReports();

  @override
  Future<List<RoomReport>> getReportsForRoom(String roomId) async {
    return _items.where((r) => r.roomId == roomId).toList(growable: false);
  }

  @override
  Future<RoomReport> submitReport(RoomReport report) async {
    _items.insert(0, report);
    return report;
  }
}

class MockCalendarRepository implements CalendarRepository {
  final List<CalendarEvent> _items = MockData.seedCalendarEvents();

  @override
  Future<List<CalendarEvent>> getEventsForRoom(
    String roomId,
    DateTime day,
  ) async {
    return _items
        .where((e) => e.roomId == roomId && _sameDay(e.startTime, day))
        .toList(growable: false);
  }

  @override
  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    return _items
        .where((e) => _sameDay(e.startTime, day))
        .toList(growable: false);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}