import 'package:flutter_test/flutter_test.dart';
import 'package:tempat_in/controllers/reservation_controller.dart';
import 'package:tempat_in/controllers/room_controller.dart';
import 'package:tempat_in/core/notification_service.dart';
import 'package:tempat_in/models/reservation.dart';
import 'package:tempat_in/models/room.dart';
import 'package:tempat_in/repositories/mock/mock_data.dart';
import 'package:tempat_in/repositories/mock/mock_repositories.dart';

class _FakeNotificationService implements NotificationService {
  final List<String> shownBodies = [];
  final List<int> cancelledIds = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    shownBodies.add(body);
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }
}

void main() {
  test('RoomController.applySearchFilter matches all criteria & Available only', () {
    final rooms = MockData.seedRooms();
    final filtered = RoomController.applySearchFilter(
      rooms,
      const RoomSearchFilter(
        building: 'Gedung TULT',
        minCapacity: 30,
        facilities: {'Projector', 'AC'},
      ),
    );

    expect(filtered.isNotEmpty, isTrue);
    for (final r in filtered) {
      expect(r.status, RoomStatus.available);
      expect(r.building, 'Gedung TULT');
      expect(r.capacity, greaterThanOrEqualTo(30));
    }
  });

  test('check-in, early check-out, and manual status updates', () async {
    final roomRepo = MockRoomRepository(tickInterval: const Duration(hours: 1));
    addTearDown(roomRepo.dispose);
    final roomCtrl = RoomController(roomRepo);
    await Future.delayed(const Duration(milliseconds: 20));

    final notif = _FakeNotificationService();
    final resCtrl = ReservationController(
      repository: MockReservationRepository(),
      roomController: roomCtrl,
      notifications: notif,
    );
    addTearDown(resCtrl.dispose);

    final res = await resCtrl.bookAndCheckIn(
      userId: 'usr-001',
      roomId: 'rm-01',
      duration: const Duration(hours: 1),
    );
    expect(roomCtrl.getById('rm-01')?.status, RoomStatus.occupied);
    expect(res.isFlagged, isFalse);

    await resCtrl.checkOutEarly(res.reservationId);
    expect(roomCtrl.getById('rm-01')?.status, RoomStatus.available);
    expect(resCtrl.getById(res.reservationId)?.status, ReservationStatus.completed);
    expect(notif.cancelledIds, contains(res.reservationId.hashCode));
  });

  test('auto check-out frees room and sends notification', () async {
    final roomRepo = MockRoomRepository(tickInterval: const Duration(hours: 1));
    addTearDown(roomRepo.dispose);
    final roomCtrl = RoomController(roomRepo);
    await Future.delayed(const Duration(milliseconds: 20));

    final notif = _FakeNotificationService();
    final resCtrl = ReservationController(
      repository: MockReservationRepository(),
      roomController: roomCtrl,
      notifications: notif,
      warningLeadTime: const Duration(milliseconds: 30),
    );
    addTearDown(resCtrl.dispose);

    final res = await resCtrl.bookAndCheckIn(
      userId: 'usr-001',
      roomId: 'rm-01',
      duration: const Duration(milliseconds: 80),
    );

    await Future.delayed(const Duration(milliseconds: 140));
    expect(
      resCtrl.getById(res.reservationId)?.status,
      ReservationStatus.autoCheckedOut,
    );
    expect(roomCtrl.getById('rm-01')?.status, RoomStatus.available);
    expect(notif.shownBodies, contains('Anda telah di-check-out otomatis.'));
  });
}