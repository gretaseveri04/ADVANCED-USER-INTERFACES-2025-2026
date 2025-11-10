import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart';
import 'package:flutter/foundation.dart';

/// Service for interacting with Azure OpenAI
class AIService {
  /// Prompt
  static const Map<String, String> _systemMessage = {
    "role": "system",
    "content": "You are a highly specialized AI Transcription Analysis Assistant. Your primary function is to process raw transcription text (e.g., meeting notes, interviews, lectures). You must provide concise summaries, identify critical action items, extract key decisions, and answer user questions strictly based on the provided text content. Maintain a professional, objective, and analytical tone. All your responses must be delivered in clear, grammatically correct English."
  };

  /// Method to send a message and receive the model's response
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
      final response = await http.post(url, headers: headers, body: body);

      // Handle API Response 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if the response content is valid
        if (data['choices'] != null && data['choices'].isNotEmpty) {
           final reply = data['choices'][0]['message']['content'] as String;
           return reply; 
        } else {
           // The API responded 200, but the expected content is missing
           throw const FormatException("API response successful but no content found.");
        }
      } else {
        // The call failed (e.g., 400, 401, 500)

        if (kDebugMode) {
           print("Azure OpenAI API Error (${response.statusCode}): ${response.body}");
        }
        throw Exception("API call failed with status ${response.statusCode}.");
      }
    } 
  
    catch (e) {
      throw Exception("An error occurred during API call: $e");
    }
  }
}