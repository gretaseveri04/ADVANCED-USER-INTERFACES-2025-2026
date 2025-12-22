import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class BriefingService {
  final String apiKey = "sk_a1c6644b6df032ce6384a8ae2335a719cc92902209aa29b7";
  final String voiceId = "iiidtqDt9FBdT1vfBluA";

  Future<String> getBriefingAudio(String text) async {
    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
    
    final response = await http.post(
      url,
      headers: {
        'Accept': 'audio/mpeg',
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: '{"text": "$text", "model_id": "eleven_multilingual_v2"}',
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final file = File('${(await getTemporaryDirectory()).path}/briefing.mp3');
      await file.writeAsBytes(bytes);
      return file.path;
    } else {
      throw Exception('Errore ElevenLabs: ${response.body}');
    }
  }
}