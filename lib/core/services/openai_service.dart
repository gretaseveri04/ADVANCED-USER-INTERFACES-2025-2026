import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

class OpenAIService {
  
  Future<String> transcribeAudioBytes(Uint8List audioBytes, String filename) async {
    final url = "${AzureConfig.endpoint}/openai/deployments/${AzureConfig.whisperDeploymentName}/audio/transcriptions?api-version=2024-06-01";

    try {
      final request = http.MultipartRequest("POST", Uri.parse(url));
      
      request.headers['api-key'] = AzureConfig.apiKey;
      request.fields['language'] = 'en'; 

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
        throw Exception("Error Azure Whisper: $responseBody");
      }
    } catch (e) {
      print("Error Audio: $e");
      rethrow;
    }
  }

  Future<String> getChatResponse(String userMessage, {String? contextData}) async {
    final url = "${AzureConfig.endpoint}/openai/deployments/${AzureConfig.gptDeploymentName}/chat/completions?api-version=2024-02-01";
    
    String systemInstruction = "Sei un assistente AI utile e conciso per un team.";
    
    if (contextData != null && contextData.isNotEmpty) {
      systemInstruction += """
      
      Hai accesso alla 'MEMORIA DEI MEETING' dell'utente qui sotto. 
      Usa queste informazioni per rispondere alle domande dell'utente.
      Se la risposta non è nei meeting, usa la tua conoscenza generale ma specificalo.
      
      --- MEMORIA MEETING START ---
      $contextData
      --- MEMORIA MEETING END ---
      """;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'api-key': AzureConfig.apiKey,
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "system", 
              "content": systemInstruction 
            },
            {
              "role": "user", 
              "content": userMessage
            }
          ],
          "max_tokens": 500, 
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
      print("Errore Chat: $e");
      return "Non riesco a connettermi al servizio AI.";
    }
  }

  Future<Map<String, dynamic>?> extractEventDetails(String text) async {
    try {
      final now = DateTime.now();
      final String todayStr = DateFormat('yyyy-MM-dd (EEEE)').format(now);
      
      final systemPrompt = """
      You are a smart assistant. Today is $todayStr.
      Analyze the user's input. If they mention an event with a specific time/date, extract the details into a JSON object.
      
      Rules:
      1. If the user says "tomorrow", calculate the date based on Today ($todayStr).
      2. Convert all times to ISO 8601 format (yyyy-MM-ddTHH:mm:ss).
      3. If AM/PM is not specified, assume business hours (e.g. 8 -> 08:00, 2 -> 14:00).
      4. RETURN ONLY THE RAW JSON. Do not use Markdown blocks (no ```json).
      
      Required JSON Structure:
      {
        "title": "Short event title",
        "start_time": "ISO 8601 String",
        "end_time": "ISO 8601 String (default to 1 hour duration if not specified)",
        "description": "Original context"
      }
      
      If no event is found, return exactly: {}
      """;

      const apiKey = 'EuHU0Q57ppItyHjGPJAKQTahO1Ze3bANdmW6ietwb0vwYztiGNoJJQQJ99BKACfhMk5XJ3w3AAAAACOGfZEA'; 

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo", 
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": text}
          ],
          "temperature": 0.0 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String content = data['choices'][0]['message']['content'];
        
        final startIndex = content.indexOf('{');
        final endIndex = content.lastIndexOf('}');
        
        if (startIndex != -1 && endIndex != -1) {
          content = content.substring(startIndex, endIndex + 1);
        } else {
          return null; 
        }
        
        final decodedMap = jsonDecode(content);
        if (decodedMap is Map<String, dynamic> && decodedMap.isNotEmpty) {
           return decodedMap;
        }
        return null;
      } else {
        print("Errore GPT API: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Errore CRITICO estrazione evento: $e");
      return null;
    }
  }
}