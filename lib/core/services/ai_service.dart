import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart'; // Usa la nuova classe AzureConfig

class AIService {
  
  // Messaggio di sistema per istruire l'AI sul suo ruolo
  static const Map<String, String> _systemMessage = {
    "role": "system",
    "content": "Sei un assistente AI specializzato per 'Limitless App'. Il tuo compito è aiutare l'utente a gestire le sue riunioni, estrarre task, riassumere trascrizioni e rispondere a domande sui meeting passati. Sii professionale, conciso e utile."
  };

  // Funzione per inviare messaggi alla Chat (GPT-4o su Azure)
  static Future<String> sendMessage(String userMessage) async {
    
    // Costruiamo l'URL specifico di Azure usando la configurazione in keys.dart
    final url = "${AzureConfig.endpoint}/openai/deployments/${AzureConfig.gptDeploymentName}/chat/completions?api-version=2024-02-01";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'api-key': AzureConfig.apiKey, // Header specifico Azure
        },
        body: jsonEncode({
          "messages": [
            _systemMessage,
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 500,    // Lunghezza massima risposta
          "temperature": 0.7,   // Creatività (0.7 è bilanciato)
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
           return data['choices'][0]['message']['content']; 
        } else {
           return "Non ho ricevuto una risposta valida dall'AI.";
        }
      } else {
        throw Exception("Errore Azure AI (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      return "Mi dispiace, si è verificato un errore di connessione con l'AI: $e";
    }
  }
}