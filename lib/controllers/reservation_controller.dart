import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/notification_service.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import '../repositories/repositories.dart';
import 'room_controller.dart';

class ReservationController extends ChangeNotifier {
  final ReservationRepository _repo;
  final RoomController _roomController;
  final NotificationService _notifications;
  final Duration warningLeadTime;

  List<Reservation> _reservations = [];
  Timer? _warningTimer;
  Timer? _autoCheckoutTimer;
  String? _activeWarningMessage;
  String? _lastAutoCheckoutMessage;

  ReservationController({
    required ReservationRepository repository,
    required RoomController roomController,
    required NotificationService notifications,
    this.warningLeadTime = AppConstants.defaultCheckoutWarningLead,
  })  : _repo = repository,
        _roomController = roomController,
        _notifications = notifications;

  List<Reservation> get reservations => List.unmodifiable(_reservations);
  List<Reservation> get activeReservations => _reservations
      .where((r) => r.status == ReservationStatus.active)
      .toList(growable: false);
  List<Reservation> get pastReservations => _reservations
      .where((r) => r.status != ReservationStatus.active)
      .toList(growable: false);

  String? get activeWarningMessage => _activeWarningMessage;
  String? get lastAutoCheckoutMessage => _lastAutoCheckoutMessage;

  Future<void> loadForUser(String userId) async {
    _reservations = await _repo.getReservationsForUser(userId);
    notifyListeners();
  }

  Reservation? getById(String reservationId) {
    for (final r in _reservations) {
      if (r.reservationId == reservationId) return r;
    }
    return null;
  }

  Reservation? activeReservationForRoom(String roomId) {
    for (final r in _reservations) {
      if (r.roomId == roomId && r.status == ReservationStatus.active) return r;
    }
    return null;
  }

  Future<Reservation> bookAndCheckIn({
    required String userId,
    required String roomId,
    required Duration duration,
    DateTime? nowOverride,
  }) async {
    final start = nowOverride ?? DateTime.now();
    final end = start.add(duration);
    final flagged = duration > AppConstants.anomalyMaxDuration ||
        _roomController.hasRapidStatusFlips(roomId);

    final created = Reservation(
      reservationId: 'res-${start.millisecondsSinceEpoch}',
      userId: userId,
      roomId: roomId,
      startTime: start,
      endTime: end,
      status: ReservationStatus.active,
      isFlagged: flagged,
    );

    await _repo.createReservation(created);
    await _roomController.setStatusFromCheckIn(
      roomId,
      RoomStatus.occupied,
      occupantUserId: userId,
    );

    _reservations = [created, ..._reservations];
    _activeWarningMessage = null;
    _lastAutoCheckoutMessage = null;
    _scheduleTimers(created, duration);
    notifyListeners();
    return created;
  }

  void _scheduleTimers(Reservation reservation, Duration duration) {
    _cancelTimers();
    final warnDelay = duration - warningLeadTime;
    if (warnDelay > Duration.zero) {
      _warningTimer = Timer(warnDelay, () => _triggerWarning(reservation));
    }
    _autoCheckoutTimer = Timer(duration, () => _autoCheckOut(reservation));
  }

  Future<void> simulateWarning(String reservationId) async {
    final res = getById(reservationId);
    if (res == null || res.status != ReservationStatus.active) return;
    await _triggerWarning(res);
  }

  Future<void> _triggerWarning(Reservation reservation) async {
    final room = _roomController.getById(reservation.roomId);
    final mins = warningLeadTime.inMinutes;
    final msg =
        'Sesi di ${room?.name ?? reservation.roomId} berakhir dalam $mins menit. Segera bersiap untuk check-out.';
    _activeWarningMessage = msg;
    await _notifications.show(
      id: reservation.reservationId.hashCode,
      title: 'Pengingat Check-Out',
      body: msg,
    );
    notifyListeners();
  }

  void dismissWarningBanner() {
    _activeWarningMessage = null;
    notifyListeners();
  }

  Future<void> checkOutEarly(String reservationId) async {
    final res = getById(reservationId);
    if (res == null || res.status != ReservationStatus.active) return;

    _cancelTimers();
    await _notifications.cancel(res.reservationId.hashCode);
    final updated = await _repo.updateStatus(
      reservationId,
      ReservationStatus.completed,
    );
    await _roomController.setStatusFromCheckIn(
      res.roomId,
      RoomStatus.available,
    );
    _replaceLocal(updated);
    _activeWarningMessage = null;
    notifyListeners();
  }

  Future<void> _autoCheckOut(Reservation reservation) async {
    final current = getById(reservation.reservationId);
    if (current == null || current.status != ReservationStatus.active) return;

    _cancelTimers();
    final updated = await _repo.updateStatus(
      reservation.reservationId,
      ReservationStatus.autoCheckedOut,
    );
    await _roomController.setStatusFromCheckIn(
      reservation.roomId,
      RoomStatus.available,
    );
    _replaceLocal(updated);
    _activeWarningMessage = null;
    _lastAutoCheckoutMessage = 'Anda telah di-check-out otomatis.';
    await _notifications.show(
      id: reservation.reservationId.hashCode + 1,
      title: 'Auto Check-Out',
      body: _lastAutoCheckoutMessage!,
    );
    notifyListeners();
  }

  void _replaceLocal(Reservation updated) {
    final idx = _reservations
        .indexWhere((r) => r.reservationId == updated.reservationId);
    if (idx != -1) {
      _reservations = List.of(_reservations)..[idx] = updated;
    }
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _warningTimer = null;
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}