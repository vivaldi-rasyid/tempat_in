import 'package:flutter/foundation.dart';

import '../models/calendar_event.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import '../repositories/repositories.dart';
import 'reservation_controller.dart';
import 'room_controller.dart';

class ScheduledRoomEntry {
  final Room room;
  final RoomStatus mergedStatus;
  final String? reservedTimeRange;

  const ScheduledRoomEntry({
    required this.room,
    required this.mergedStatus,
    this.reservedTimeRange,
  });
}

class CalendarController extends ChangeNotifier {
  final CalendarRepository _repo;
  final RoomController _roomController;
  final ReservationController _reservationController;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<ScheduledRoomEntry> _entries = [];
  bool _isLoading = false;
  bool _calendarApiFailed = false;
  bool _simulateApiFailure = false;
  bool _showAllRooms = false;

  CalendarController({
    required CalendarRepository repository,
    required RoomController roomController,
    required ReservationController reservationController,
  })  : _repo = repository,
        _roomController = roomController,
        _reservationController = reservationController {
    loadForDate(_selectedDate);
  }

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedMonth => _focusedMonth;
  List<ScheduledRoomEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get calendarApiFailed => _calendarApiFailed;
  bool get simulateApiFailure => _simulateApiFailure;
  bool get showAllRooms => _showAllRooms;

  List<ScheduledRoomEntry> get visibleEntries {
    if (_showAllRooms) return _entries;
    return _entries
        .where((e) => e.mergedStatus == RoomStatus.available)
        .toList(growable: false);
  }

  void toggleShowAll() {
    _showAllRooms = !_showAllRooms;
    notifyListeners();
  }

  void setSimulateApiFailure(bool value) {
    if (_simulateApiFailure == value) return;
    _simulateApiFailure = value;
    loadForDate(_selectedDate);
  }

  void changeMonth(int delta) {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _focusedMonth = DateTime(date.year, date.month);
    await loadForDate(_selectedDate);
  }

  Future<void> loadForDate(DateTime date) async {
    _isLoading = true;
    _calendarApiFailed = false;
    notifyListeners();

    List<CalendarEvent> orgEvents = const [];
    try {
      if (_simulateApiFailure) {
        throw StateError('Simulated organization calendar API failure');
      }
      orgEvents = await _repo.getEventsForDay(date);
    } catch (_) {
      _calendarApiFailed = true;
      orgEvents = const [];
    }

    _entries = mergeRoomAvailability(
      rooms: _roomController.rooms,
      orgEvents: orgEvents,
      reservations: _reservationController.reservations,
      day: date,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Pure status-merging logic: combines internal reservations + org calendar.
  /// Priority: active internal reservation -> Occupied; org calendar event -> Reserved;
  /// otherwise Available (or current live status if checking today).
  static List<ScheduledRoomEntry> mergeRoomAvailability({
    required List<Room> rooms,
    required List<CalendarEvent> orgEvents,
    required List<Reservation> reservations,
    required DateTime day,
  }) {
    final now = DateTime.now();
    final isToday = _sameDay(day, now);

    return rooms.map((room) {
      final activeInternal = reservations.where(
        (r) =>
            r.roomId == room.roomId &&
            r.status == ReservationStatus.active &&
            _sameDay(r.startTime, day),
      );
      if (activeInternal.isNotEmpty) {
        final res = activeInternal.first;
        return ScheduledRoomEntry(
          room: room,
          mergedStatus: RoomStatus.occupied,
          reservedTimeRange: _formatRange(res.startTime, res.endTime),
        );
      }

      final dayEvents = orgEvents.where(
        (e) => e.roomId == room.roomId && _sameDay(e.startTime, day),
      );
      if (dayEvents.isNotEmpty) {
        final evt = dayEvents.first;
        return ScheduledRoomEntry(
          room: room,
          mergedStatus: RoomStatus.reserved,
          reservedTimeRange: _formatRange(evt.startTime, evt.endTime),
        );
      }

      return ScheduledRoomEntry(
        room: room,
        mergedStatus: isToday ? room.status : RoomStatus.available,
      );
    }).toList(growable: false);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formatRange(DateTime start, DateTime end) {
    String hhmm(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${hhmm(start)}–${hhmm(end)}';
  }
}