import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/calendar_event_model.dart'; 

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CalendarEvent>> getMyEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final List<dynamic> data = await _supabase
          .from('calendar_events')
          .select()
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

      final List<dynamic> data = await _supabase
          .from('calendar_events')
          .select()
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

    await _supabase.from('calendar_events').insert(event.toMap(userId));
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('calendar_events').delete().eq('id', eventId);
  }
}