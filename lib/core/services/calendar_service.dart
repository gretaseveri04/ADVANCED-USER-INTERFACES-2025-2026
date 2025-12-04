import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/calendar_event_model.dart'; // Assicurati che il percorso sia giusto
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- LOGICA GOOGLE CALENDAR ---
  
  // Ottiene il client autenticato usando il token di Supabase
  Future<google_calendar.CalendarApi?> _getGoogleCalendarClient() async {
    final session = _supabase.auth.currentSession;
    final providerToken = session?.providerToken;

    // Se l'utente non ha fatto login con Google o il token manca
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
        null, // Refresh token gestito da Supabase
        ['https://www.googleapis.com/auth/calendar'],
      ),
    );

    return google_calendar.CalendarApi(authClient);
  }

  // --- METODI GESTIONE EVENTI ---

  Future<List<CalendarEvent>> getMyEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final List<dynamic> data = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId) // Filtra sempre per utente!
          .order('start_time', ascending: true);

      return data.map((e) => CalendarEvent.fromJson(e)).toList();
    } catch (e) {
      print('Errore recupero eventi: $e');
      return [];
    }
  }

  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    try {
      // Calcolo inizio e fine giornata in UTC per la query
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

  // Funzione principale modificata per integrare Google
  Future<void> addEvent(CalendarEvent event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("Utente non loggato");

    String? newGoogleId;

    // 1. Prova ad aggiungere a Google Calendar
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
      // Non blocchiamo l'app se Google fallisce, salviamo almeno su Supabase
    }

    // 2. Prepara l'evento aggiornato con l'ID di Google (se presente)
    final eventToSave = event.copyWith(googleEventId: newGoogleId);

    // 3. Salva su Supabase
    await _supabase
        .from('calendar_events')
        .insert(eventToSave.toMap(userId));
  }

  Future<void> deleteEvent(String eventId) async {
    // Nota: Per ora cancelliamo solo da Supabase. 
    // In futuro potrai usare il googleEventId salvato per cancellare anche da Google.
    await _supabase.from('calendar_events').delete().eq('id', eventId);
  }
}