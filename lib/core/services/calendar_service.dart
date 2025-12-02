import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/calendar_event_model.dart'; // Assicurati che il percorso sia giusto

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Recupera tutti gli eventi dell'utente loggato
  Future<List<CalendarEvent>> getMyEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Select * from calendar_events (la policy filtra già per utente)
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

  /// Recupera solo gli eventi di una specifica giornata (utile per la Home)
  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    try {
      // Definiamo inizio e fine della giornata
      final startOfDay = DateTime(day.year, day.month, day.day, 0, 0, 0).toUtc().toIso8601String();
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59).toUtc().toIso8601String();

      final List<dynamic> data = await _supabase
          .from('calendar_events')
          .select()
          // Filtra eventi che iniziano o finiscono in questo range, o che lo inglobano
          .or('and(start_time.lte.$endOfDay, end_time.gte.$startOfDay)') 
          .order('start_time', ascending: true);

      return data.map((e) => CalendarEvent.fromJson(e)).toList();
    } catch (e) {
      print('Errore eventi giornalieri: $e');
      return [];
    }
  }

  /// Aggiunge un nuovo evento
  Future<void> addEvent(CalendarEvent event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("Utente non loggato");

    await _supabase.from('calendar_events').insert(event.toMap(userId));
  }

  /// Cancella un evento
  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('calendar_events').delete().eq('id', eventId);
  }
}