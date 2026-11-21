enum RoomStatus { available, occupied, reserved }

enum RoomUpdateSource { manual, checkIn, calendar }

enum RoomCategory { classroom, meetingRoom, studySpace }

extension RoomCategoryX on RoomCategory {
  String get label => switch (this) {
        RoomCategory.classroom => 'Classroom',
        RoomCategory.meetingRoom => 'Meeting Room',
        RoomCategory.studySpace => 'Study Space',
      };
}

extension RoomStatusX on RoomStatus {
  String get label => switch (this) {
        RoomStatus.available => 'Available',
        RoomStatus.occupied => 'Occupied',
        RoomStatus.reserved => 'Reserved',
      };
}

class Room {
  final String roomId;
  final String name;
  final String building;
  final int floor;
  final int capacity;
  final List<String> facilities;
  final RoomStatus status;
  final RoomCategory category;
  final String description;
  final List<String> imageUrls;
  final DateTime lastUpdatedAt;
  final RoomUpdateSource lastUpdatedSource;

  const Room({
    required this.roomId,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.facilities,
    required this.status,
    required this.category,
    required this.description,
    required this.imageUrls,
    required this.lastUpdatedAt,
    required this.lastUpdatedSource,
  });

  Room copyWith({
    RoomStatus? status,
    DateTime? lastUpdatedAt,
    RoomUpdateSource? lastUpdatedSource,
  }) {
    return Room(
      roomId: roomId,
      name: name,
      building: building,
      floor: floor,
      capacity: capacity,
      facilities: facilities,
      status: status ?? this.status,
      category: category,
      description: description,
      imageUrls: imageUrls,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastUpdatedSource: lastUpdatedSource ?? this.lastUpdatedSource,
    );
  }
}