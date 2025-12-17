import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/calendar_event_model.dart'; // Mantieni il tuo modello
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- CONFIGURAZIONE ---
  // Inserisci qui il Client ID per iOS preso da Google Cloud Console
  // Sarà tipo: 123456-abcde...apps.googleusercontent.com
  static const String _iOSClientId = 'INSERISCI_QUI_IL_TUO_CLIENT_ID_IOS';

  // Configurazione del plugin nativo
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [google_calendar.CalendarApi.calendarEventsScope],
    clientId: Platform.isIOS ? _iOSClientId : null,
  );

  /// Ottiene il client autenticato (gestisce login e token automaticamente)
  Future<google_calendar.CalendarApi?> _getGoogleCalendarClient() async {
    try {
      // 1. Prova il login silenzioso (se l'utente ha già dato l'ok in passato)
      var googleUser = await _googleSignIn.signInSilently();
      
      // 2. Se non basta, apre il popup nativo (chiede: "Vuoi accedere a Google?")
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Login annullato dall'utente");
        return null;
      }

      // 3. Crea il client HTTP autenticato grazie all'estensione
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return null;

      return google_calendar.CalendarApi(httpClient);
    } catch (e) {
      print("Errore nel recupero del client Google: $e");
      return null;
    }
  }

  // --- I TUOI METODI (ADATTATI AL NUOVO SISTEMA) ---

  Future<void> addEvent(CalendarEvent event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("Utente non loggato su Supabase");

    String? newGoogleId;

    // A. TENTATIVO GOOGLE CALENDAR
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
        print("✅ Evento sincronizzato su Google Calendar!");
      }
    } catch (e) {
      print("⚠️ Impossibile sincronizzare con Google (salvo solo in locale): $e");
    }

    // B. SALVATAGGIO SU SUPABASE (Come facevi prima)
    try {
      final eventToSave = event.copyWith(googleEventId: newGoogleId);
      await _supabase
          .from('calendar_events')
          .insert(eventToSave.toMap(userId));
    } catch (e) {
      print("Errore salvataggio database Supabase: $e");
      throw e; // Rilanciamo l'errore se fallisce il DB principale
    }
  }

  Future<List<CalendarEvent>> getMyEvents() async {
    // Questo rimane identico: legge dal tuo DB Supabase
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
    // Anche questo rimane identico
    try {
      final startOfDay = DateTime.utc(day.year, day.month, day.day, 0, 0, 0).toIso8601String();
      final endOfDay = DateTime.utc(day.year, day.month, day.day, 23, 59, 59).toIso8601String();
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

  Future<void> deleteEvent(String eventId) async {
    // Qui cancelli solo da Supabase per ora.
    // Se volessi cancellare anche da Google, dovresti recuperare l'evento,
    // leggere il googleEventId e chiamare calendarApi.events.delete(...)
    await _supabase.from('calendar_events').delete().eq('id', eventId);
  }
}