class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final String startTime; // es. "10:00 AM"
  final String duration;  // es. "1h"
  final String location;  // es. "Conference Room A" o "Virtual"
  final int peopleCount;
  final String category;
  final String aiSuggestion;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.location,
    required this.peopleCount,
    required this.category,
    required this.aiSuggestion,
  });
}


