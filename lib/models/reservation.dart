enum ReservationStatus { active, completed, cancelled, autoCheckedOut }

class Reservation {
  final String reservationId;
  final String userId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final ReservationStatus status;

  /// Internal anomaly flag: true if duration exceeds 6 hours or if the room's
  /// status was flipped rapidly multiple times right before/during booking.
  final bool isFlagged;

  const Reservation({
    required this.reservationId,
    required this.userId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.isFlagged = false,
  });

  Reservation copyWith({
    ReservationStatus? status,
    bool? isFlagged,
  }) {
    return Reservation(
      reservationId: reservationId,
      userId: userId,
      roomId: roomId,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }
}