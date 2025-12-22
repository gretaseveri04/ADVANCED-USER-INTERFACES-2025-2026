import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/calendar_event_model.dart'; 
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _iOSClientId = 'INSERISCI_QUI_IL_TUO_CLIENT_ID_IOS';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [google_calendar.CalendarApi.calendarEventsScope],
    clientId: Platform.isIOS ? _iOSClientId : null,
  );

  Future<google_calendar.CalendarApi?> _getGoogleCalendarClient() async {
    try {
      var googleUser = await _googleSignIn.signInSilently();
      
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Login annullato dall'utente");
        return null;
      }

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return null;

      return google_calendar.CalendarApi(httpClient);
    } catch (e) {
      print("Errore nel recupero del client Google: $e");
      return null;
    }
  }

  Future<void> addEvent(CalendarEvent event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("Utente non loggato su Supabase");

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
      }
    } catch (e) {
    }

    try {
      final eventToSave = event.copyWith(googleEventId: newGoogleId);
      await _supabase
          .from('calendar_events')
          .insert(eventToSave.toMap(userId));
    } catch (e) {
      throw e; 
    }
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
      return [];
    }
  }

  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
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
      return [];
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('calendar_events').delete().eq('id', eventId);
  }
}