import '../models/calendar_event.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import '../models/room_report.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<User?> restoreSession();
  Future<User> login(String email, String password);
  Future<User> loginWithSso();
  Future<User> signUp(String email, String password);
  Future<void> logout();
}

abstract class RoomRepository {
  Future<List<Room>> getRooms();
  Future<Room?> getRoomById(String roomId);
  Future<Room> updateRoomStatus(
    String roomId,
    RoomStatus status,
    RoomUpdateSource source,
  );
  Stream<List<Room>> watchRooms();
  void dispose();
}

abstract class ReservationRepository {
  Future<List<Reservation>> getReservationsForUser(String userId);
  Future<Reservation> createReservation(Reservation reservation);
  Future<Reservation> updateStatus(
    String reservationId,
    ReservationStatus status,
  );
}

abstract class ReportRepository {
  Future<List<RoomReport>> getReportsForRoom(String roomId);
  Future<RoomReport> submitReport(RoomReport report);
}

abstract class CalendarRepository {
  Future<List<CalendarEvent>> getEventsForRoom(String roomId, DateTime day);
  Future<List<CalendarEvent>> getEventsForDay(DateTime day);
}