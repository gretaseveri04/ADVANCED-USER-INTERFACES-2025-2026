class CalendarEvent {
  final String? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;

  CalendarEvent({
    this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
  });

  // Converte dal formato Database (JSON di Supabase) al formato App
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      // Supabase restituisce le date in UTC, le convertiamo in ora locale
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      isAllDay: json['is_all_day'] ?? false,
    );
  }

  // Converte dal formato App al formato Database per il salvataggio
  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      // Convertiamo in UTC prima di inviare al server
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'is_all_day': isAllDay,
    };
  }
  
  // Getter utile per calcolare la durata al volo
  Duration get duration => endTime.difference(startTime);
}