import 'package:limitless_app/models/calendar_event_model.dart';

class CalendarMockService {
  // Nota: _events deve essere statico per mantenere i dati in memoria durante la sessione
  static final List<CalendarEvent> _events = [
    CalendarEvent(
      id: 'evt-21-1',
      title: 'Marketing Team Meeting',
      date: DateTime(2025, 12, 21),
      startTime: '10:00 AM',
      duration: '1h',
      location: 'Conference Room A',
      peopleCount: 5,
      category: 'WORK',
      aiSuggestion: 'Prepare Q4 report slides',
    ),
    CalendarEvent(
      id: 'evt-21-2',
      title: 'Client Call - ABC Corp',
      date: DateTime(2025, 12, 21),
      startTime: '2:30 PM',
      duration: '45m',
      location: 'Virtual',
      peopleCount: 3,
      category: 'WORK',
      aiSuggestion: 'Review agenda and key talking points before the call',
    ),
    CalendarEvent(
      id: 'evt-21-3',
      title: 'Product Brainstorming',
      date: DateTime(2025, 12, 21),
      startTime: '4:00 PM',
      duration: '1h 30m',
      location: 'Innovation Lab',
      peopleCount: 8,
      category: 'WORK',
      aiSuggestion: 'Review competitor analysis and user feedback',
    ),
    CalendarEvent(
      id: 'evt-22-1',
      title: 'Team Retro',
      date: DateTime(2025, 12, 22),
      startTime: '9:30 AM',
      duration: '1h',
      location: 'Conference Room B',
      peopleCount: 6,
      category: 'WORK',
      aiSuggestion: 'Collect highlights, pain points and concrete improvements',
    ),
    CalendarEvent(
      id: 'evt-23-1',
      title: 'Design Review',
      date: DateTime(2025, 12, 23),
      startTime: '11:00 AM',
      duration: '2h',
      location: 'Design Studio',
      peopleCount: 6,
      category: 'WORK',
      aiSuggestion: 'Prepare visual examples for key interaction flows',
    ),
  ];

  List<CalendarEvent> getEvents() => List.unmodifiable(_events);

  /// NUOVO METODO: Restituisce gli eventi di un giorno specifico
  List<CalendarEvent> getEventsForDay(DateTime date) {
    return _events.where((event) {
      return event.date.year == date.year &&
             event.date.month == date.month &&
             event.date.day == date.day;
    }).toList();
  }

  void addEvent(CalendarEvent event) {
    _events.add(event);
  }
}


