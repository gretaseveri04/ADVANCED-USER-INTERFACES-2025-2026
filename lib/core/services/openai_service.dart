import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart';
import 'package:http_parser/http_parser.dart';

class OpenAIService {
  
  // --- 1. FUNZIONE PER TRASCIVERE (Audio -> Testo) ---
  Future<String> transcribeAudioBytes(Uint8List audioBytes, String filename) async {
    final url = "${AzureConfig.endpoint}/openai/deployments/${AzureConfig.whisperDeploymentName}/audio/transcriptions?api-version=2024-06-01";
    
    print("🔹 Chiamata Azure Whisper (Audio)...");

    try {
      final request = http.MultipartRequest("POST", Uri.parse(url));
      
      request.headers['api-key'] = AzureConfig.apiKey;
      request.fields['language'] = 'en'; // Inglese per evitare il coreano

      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        audioBytes,
        filename: filename, 
        contentType: MediaType('audio', 'webm'), 
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['text'];
      } else {
        throw Exception("Errore Azure Whisper: $responseBody");
      }
    } catch (e) {
      print("❌ Errore Audio: $e");
      rethrow;
    }
  }

  // --- 2. FUNZIONE PER CHATTARE (Testo -> Risposta AI) ---
  // QUESTA È QUELLA CHE MANCAVA!
  Future<String> getChatResponse(String userMessage) async {
    final url = "${AzureConfig.endpoint}/openai/deployments/${AzureConfig.gptDeploymentName}/chat/completions?api-version=2024-02-01";
    
    print("🔹 Chiamata Azure Chat (Testo)...");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'api-key': AzureConfig.apiKey, // Header specifico Azure
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "system", 
              "content": "Sei un assistente AI utile e conciso all'interno di una chat di gruppo."
            },
            {
              "role": "user", 
              "content": userMessage
            }
          ],
          "max_tokens": 300,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception("Errore Azure Chat: ${response.body}");
      }
    } catch (e) {
      print("❌ Errore Chat: $e");
      // Ritorna un messaggio di errore gentile invece di crashare
      return "Mi dispiace, non riesco a connettermi al cervello AI in questo momento.";
    }
  }
}