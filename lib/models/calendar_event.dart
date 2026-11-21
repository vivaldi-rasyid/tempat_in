class CalendarEvent {
  final String eventId;
  final String roomId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;

  const CalendarEvent({
    required this.eventId,
    required this.roomId,
    required this.title,
    required this.startTime,
    required this.endTime,
  });
}