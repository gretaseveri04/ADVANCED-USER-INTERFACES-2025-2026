import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/calendar_event_model.dart'; 
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  
  Future<google_calendar.CalendarApi?> _getGoogleCalendarClient() async {
    final session = _supabase.auth.currentSession;
    final providerToken = session?.providerToken;

    if (providerToken == null) {
      print("Nessun provider token trovato (Login Google richiesto per sync).");
      return null;
    }

    final authClient = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          providerToken,
          DateTime.now().add(const Duration(hours: 1)).toUtc(),
        ),
        null, 
        ['https://www.googleapis.com/auth/calendar'],
      ),
    );

    return google_calendar.CalendarApi(authClient);
  }

  Future<List<CalendarEvent>> getMyEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final List<dynamic> data = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId) 
          .order('start_time', ascending: true);

      return data.map((e) => CalendarEvent.fromJson(e)).toList();
    } catch (e) {
      print('Errore recupero eventi: $e');
      return [];
    }
  }

  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    try {
      final startOfDay = DateTime(day.year, day.month, day.day, 0, 0, 0).toUtc().toIso8601String();
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59).toUtc().toIso8601String();
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) return [];

      final List<dynamic> data = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .or('and(start_time.lte.$endOfDay, end_time.gte.$startOfDay)') 
          .order('start_time', ascending: true);

      return data.map((e) => CalendarEvent.fromJson(e)).toList();
    } catch (e) {
      print('Errore eventi giornalieri: $e');
      return [];
    }
  }

  Future<void> addEvent(CalendarEvent event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("Utente non loggato");

    String? newGoogleId;

    try {
      final calendarApi = await _getGoogleCalendarClient();
      if (calendarApi != null) {
        final googleEvent = google_calendar.Event(
          summary: event.title,
          description: event.description,
          start: google_calendar.EventDateTime(
            dateTime: event.startTime.toUtc(),
            timeZone: "UTC",
          ),
          end: google_calendar.EventDateTime(
            dateTime: event.endTime.toUtc(),
            timeZone: "UTC",
          ),
        );

        final insertedEvent = await calendarApi.events.insert(googleEvent, "primary");
        newGoogleId = insertedEvent.id;
        print("Evento aggiunto a Google Calendar: ${insertedEvent.htmlLink}");
      }
    } catch (e) {
      print("Errore Google Calendar (procedo comunque con salvataggio locale): $e");
    }

    final eventToSave = event.copyWith(googleEventId: newGoogleId);

    await _supabase
        .from('calendar_events')
        .insert(eventToSave.toMap(userId));
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('calendar_events').delete().eq('id', eventId);
  }
}