import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/meeting_model.dart';

class MeetingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Carica i dati grezzi (Bytes) invece del file
  Future<String> uploadAudioBytes(Uint8List bytes) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    // Genera nome file unico
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.webm'; // Su Chrome è spesso webm o mp3
    final path = '${user.id}/$fileName';

    try {
      // Usa uploadBinary che funziona sia su Web che Mobile
      await _supabase.storage.from('meeting_recordings').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return _supabase.storage.from('meeting_recordings').getPublicUrl(path);
    } catch (e) {
      throw Exception("Errore upload Supabase: $e");
    }
  }

  // Questo rimane uguale
  Future<void> saveMeeting({
    required String title,
    required String transcript,
    required String audioUrl,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase.from('meetings').insert({
      'user_id': userId,
      'title': title,
      'transcription_text': transcript,
      'audio_url': audioUrl,
      'category': 'WORK', 
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Meeting>> fetchMeetings() async {
    final response = await _supabase
        .from('meetings')
        .select()
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Meeting.fromJson(json)).toList();
  }
}