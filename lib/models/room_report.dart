class RoomReport {
  final String reportId;
  final String roomId;
  final String userId;
  final String type;
  final String description;
  final String? photoPath;
  final DateTime createdAt;
  final String status;

  const RoomReport({
    required this.reportId,
    required this.roomId,
    required this.userId,
    required this.type,
    required this.description,
    this.photoPath,
    required this.createdAt,
    this.status = 'submitted',
  });
}