import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart';
import 'package:flutter/foundation.dart';

/// Servizio per interagire con Azure OpenAI
class AIService {
  /// Prompt di sistema per definire il ruolo dell'assistente
  static const Map<String, String> _systemMessage = {
    "role": "system",
    "content": "You are a highly specialized AI Transcription Analysis Assistant. Your primary function is to process raw transcription text (e.g., meeting notes, interviews, lectures). You must provide concise summaries, identify critical action items, extract key decisions, and answer user questions strictly based on the provided text content. Maintain a professional, objective, and analytical tone. All your responses must be delivered in clear, grammatically correct English."
  };

  /// Metodo per inviare un messaggio e ricevere la risposta del modello
  static Future<String> sendMessage(String userMessage) async {
    final url = Uri.parse(
      "${endpoint}openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion",
    );

    final headers = {
      'Content-Type': 'application/json',
      'api-key': AzureKey,
    };

    final body = jsonEncode({
      "messages": [
        _systemMessage,
        {"role": "user", "content": userMessage}
      ],
      "max_tokens": 500,
      "temperature": 0.7,
      "top_p": 0.9,
    });

try {
      // 4. Esecuzione della Chiamata HTTP
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // 5. Gestione del Successo
        final data = jsonDecode(response.body);
        
        // Verifica la struttura della risposta prima di accedere ai dati
        if (data['choices'] != null && data['choices'].isNotEmpty) {
           final reply = data['choices'][0]['message']['content'] as String;
           return reply;
        } else {
           // Caso in cui l'API restituisce 200 ma senza risposta valida
           throw const FormatException("API response successful but no content found in 'choices'.");
        }
      } else {
        // 6. Gestione degli Errori non-200
        // Stampa il corpo solo in modalità debug per sicurezza
        if (kDebugMode) {
          print("Azure OpenAI API Error (${response.statusCode}): ${response.body}");
        }
        
        // Tentativo di estrarre un messaggio di errore leggibile da Azure
        String errorMessage = "Unknown API Error";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error']['message'] ?? errorMessage;
        } catch (_) {
          // Ignora se la risposta non è JSON valida
        }

        // Lancia un'eccezione specifica con lo stato e il messaggio
        throw HttpException("API call failed with status ${response.statusCode}: $errorMessage");
      }
    } on http.ClientException catch (e) {
      // Gestione di errori di rete (es. timeout, nessuna connessione)
      throw Exception("Network Error during API call: ${e.message}");
    } catch (e) {
      // Gestione di altri errori (es. FormatException)
      rethrow; 
    }
  }
}
// Devi anche definire la classe HttpException se vuoi lanciarla
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
  
