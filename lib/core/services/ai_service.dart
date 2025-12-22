import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart'; 

class AIService {
  
  static const Map<String, String> _systemMessage = {
    "role": "system",
    "content": "You are an AI assistant specialized for 'Limitless App'. Your task is to help the user manage meetings, extract tasks, summarize transcripts, and answer questions about past meetings. Be professional, concise, and helpful. Always respond in English."
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
        }
      }
      throw Exception("Error Azure AI");
    } catch (e) {
      return "I'm sorry, I encountered an error: $e";
    }
  }

  static Future<String> generateBriefing(String transcript) async {
    final String prompt = """
    Analyze the following meeting transcript and write a spoken briefing in English.
    RULES:
    1. Use a professional announcer tone (Bill Oxley style).
    2. Be fluid and conversational, do not use bullet points or lists.
    3. Start with a welcoming phrase like 'Good morning, here are the highlights of your meeting.'
    4. Be very concise (maximum 50-60 words).
    
    Transcript: $transcript
    """;

    return await sendMessage(prompt);
  }
}