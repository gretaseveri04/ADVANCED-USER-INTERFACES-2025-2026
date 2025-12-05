import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart'; 

class AIService {
  
  static const Map<String, String> _systemMessage = {
    "role": "system",
    "content": "Sei un assistente AI specializzato per 'Limitless App'. Il tuo compito è aiutare l'utente a gestire le sue riunioni, estrarre task, riassumere trascrizioni e rispondere a domande sui meeting passati. Sii professionale, conciso e utile."
  };

  static Future<String> sendMessage(String userMessage) async {
    
    final url = "${AzureConfig.endpoint}/openai/deployments/${AzureConfig.gptDeploymentName}/chat/completions?api-version=2024-02-01";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'api-key': AzureConfig.apiKey, 
        },
        body: jsonEncode({
          "messages": [
            _systemMessage,
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 500,    
          "temperature": 0.7,   
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