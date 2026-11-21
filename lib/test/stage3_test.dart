import 'package:flutter_test/flutter_test.dart';
import 'package:tempat_in/controllers/calendar_controller.dart';
import 'package:tempat_in/controllers/report_controller.dart';
import 'package:tempat_in/models/calendar_event.dart';
import 'package:tempat_in/models/reservation.dart';
import 'package:tempat_in/models/room.dart';
import 'package:tempat_in/repositories/mock/mock_data.dart';
import 'package:tempat_in/repositories/mock/mock_repositories.dart';

void main() {
  group('CalendarController.mergeRoomAvailability', () {
    final rooms = MockData.seedRooms().take(3).toList(); // rm-01, rm-02, rm-03
    final targetDay = DateTime(2026, 11, 25);

    test('merges active internal reservation as Occupied and org event as Reserved', () {
      final orgEvents = [
        CalendarEvent(
          eventId: 'e1',
          roomId: 'rm-02',
          title: 'Seminar HIMIF',
          startTime: DateTime(2026, 11, 25, 14, 0),
          endTime: DateTime(2026, 11, 25, 16, 0),
        ),
      ];
      final reservations = [
        Reservation(
          reservationId: 'r1',
          userId: 'usr-001',
          roomId: 'rm-01',
          startTime: DateTime(2026, 11, 25, 9, 0),
          endTime: DateTime(2026, 11, 25, 11, 0),
          status: ReservationStatus.active,
        ),
      ];

      final merged = CalendarController.mergeRoomAvailability(
        rooms: rooms,
        orgEvents: orgEvents,
        reservations: reservations,
        day: targetDay,
      );

      expect(merged[0].mergedStatus, RoomStatus.occupied);
      expect(merged[0].reservedTimeRange, '09:00–11:00');

      expect(merged[1].mergedStatus, RoomStatus.reserved);
      expect(merged[1].reservedTimeRange, '14:00–16:00');

      expect(merged[2].mergedStatus, RoomStatus.available);
      expect(merged[2].reservedTimeRange, isNull);
    });

    test('falls back to internal data only when orgEvents is empty', () {
      final merged = CalendarController.mergeRoomAvailability(
        rooms: rooms,
        orgEvents: const [],
        reservations: const [],
        day: targetDay,
      );

      expect(merged.every((e) => e.mergedStatus == RoomStatus.available), isTrue);
    });
  });

  group('ReportController validation & submission', () {
    test('rejects missing problem type', () async {
      expect(ReportController.validateProblemType(null), isNotNull);
      expect(ReportController.validateProblemType('   '), isNotNull);
      expect(
        ReportController.validateProblemType('Kerusakan AC'),
        isNull,
      );

      final ctrl = ReportController(MockReportRepository());
      expect(
        () => ctrl.submitReport(
          roomId: 'rm-01',
          userId: 'usr-001',
          type: '',
          description: 'AC bocor',
        ),
        throwsFormatException,
      );
    });

    test('saves valid report to repository', () async {
      final repo = MockReportRepository();
      final ctrl = ReportController(repo);

      await ctrl.submitReport(
        roomId: 'rm-03',
        userId: 'usr-001',
        type: 'Kerusakan AC',
        description: 'AC tidak dingin',
      );

      final saved = await repo.getReportsForRoom('rm-03');
      expect(saved.length, 1);
      expect(saved.first.type, 'Kerusakan AC');
    });
  });
}