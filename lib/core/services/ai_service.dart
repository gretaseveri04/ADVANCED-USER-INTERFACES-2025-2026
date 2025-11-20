import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:limitless_app/config/keys.dart' as config;
import 'package:limitless_app/models/lifelog_model.dart';

/// Service for interacting with Azure OpenAI
class AIService {
  static List<Lifelog>? _lifelogCache;

  /// Prompt
  static const Map<String, String> _systemMessage = {
    "role": "system",
    "content": "You are a highly specialized AI Transcription Analysis Assistant. Your primary function is to process raw transcription text (e.g., meeting notes, interviews, lectures). You must provide concise summaries, identify critical action items, extract key decisions, and answer user questions strictly based on the provided text content. Maintain a professional, objective, and analytical tone. All your responses must be delivered in clear, grammatically correct English."
  };

  static String? _missingConfigMessage() {
    final missing = <String>[];
    if (config.endpoint.isEmpty) {
      missing.add('AZURE_OPENAI_ENDPOINT');
    }
    if (config.deploymentName.isEmpty) {
      missing.add('AZURE_OPENAI_DEPLOYMENT_NAME');
    }
    if (config.AzureKey.isEmpty) {
      missing.add('AZURE_OPENAI_KEY');
    }

    if (missing.isEmpty) {
      return null;
    }

    return 'Missing Azure OpenAI configuration for: ${missing.join(', ')}. '
        'Provide them via --dart-define or update lib/config/keys.dart.';
  }

  /// Method to send a message and receive the model's response
  static Future<String> sendMessage(String userMessage) async {
    final configError = _missingConfigMessage();
    if (configError != null) {
      if (kDebugMode) {
        debugPrint('$configError — using offline assistant.');
      }
      return _localAssistantReply(userMessage);
    }

    final normalizedEndpoint =
        config.endpoint.endsWith('/') ? config.endpoint : "${config.endpoint}/";

    final url = Uri.parse(
      "${normalizedEndpoint}openai/deployments/${config.deploymentName}/chat/completions?api-version=${config.apiVersion}",
    );

    final headers = {
      'Content-Type': 'application/json',
      'api-key': config.AzureKey,
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
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Azure assistant unavailable, using offline assistant. $e');
      }
      final offlineReply = await _localAssistantReply(userMessage);
      return "$offlineReply\n\nNota: impossibile raggiungere l'assistente Azure (${e.runtimeType}).";
    }
  }

  static Future<String> _localAssistantReply(String userMessage) async {
    final logs = await _loadLifelogs();
    final relevantLogs = _findRelevantLogs(logs, userMessage);

    final wantsActions = _containsAny(userMessage, const [
      'action',
      'azioni',
      'next step',
      'attività'
    ]);
    final wantsDecisions =
        _containsAny(userMessage, const ['decision', 'decisioni', 'scelte']);
    final wantsSummary =
        _containsAny(userMessage, const ['summary', 'riassunto', 'overview']);

    final buffer = StringBuffer()
      ..writeln(
          'Assistant insight basato sulle ultime trascrizioni interne (modalità offline).')
      ..writeln('');

    for (final log in relevantLogs) {
      buffer.writeln('- ${log.title} (${log.date} • ${log.category})');
      if (wantsSummary || (!wantsActions && !wantsDecisions)) {
        buffer.writeln('  Sintesi: ${log.content}');
      }
      if (wantsActions) {
        buffer.writeln(
            '  Azioni suggerite: ${_suggestActions(log).join("; ")}');
      }
      if (wantsDecisions) {
        buffer.writeln('  Decisioni: ${_suggestDecisions(log).join("; ")}');
      }
      buffer.writeln('');
    }

    if (relevantLogs.isEmpty) {
      buffer.writeln(
          'Non ho trovato riferimenti diretti nella knowledge base locale. Chiedimi di un meeting, libro o categoria presenti nella sezione trascrizioni.');
    } else {
      buffer.writeln(
          'Suggerimento: specifica "azioni", "decisioni" o "riassunto" per risposte più focalizzate.');
    }

    return buffer.toString().trim();
  }

  static Future<List<Lifelog>> _loadLifelogs() async {
    if (_lifelogCache != null) {
      return _lifelogCache!;
    }
    final String raw =
        await rootBundle.loadString('mock_data/mock_responses.json');
    final Map<String, dynamic> data = jsonDecode(raw);
    _lifelogCache = LifelogResponse.fromJson(data).lifelogs;
    return _lifelogCache!;
  }

  static List<Lifelog> _findRelevantLogs(
      List<Lifelog> logs, String userMessage) {
    final query = userMessage.toLowerCase();
    final keywords = query
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 3)
        .toList();

    int scoreFor(Lifelog log) {
      int score = 0;
      for (final token in keywords) {
        if (log.title.toLowerCase().contains(token)) score += 4;
        if (log.category.toLowerCase().contains(token)) score += 2;
        if (log.content.toLowerCase().contains(token)) score += 1;
      }
      return score;
    }

    final scored = logs
        .map((log) => MapEntry(log, scoreFor(log)))
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (scored.isEmpty) {
      return logs.take(3).toList();
    }
    return scored.map((entry) => entry.key).take(3).toList();
  }

  static bool _containsAny(String text, List<String> hints) {
    final lower = text.toLowerCase();
    return hints.any(lower.contains);
  }

  static List<String> _suggestActions(Lifelog log) {
    switch (log.category.toUpperCase()) {
      case 'WORK':
        return [
          'Rivedi le registrazioni per estrarre decisioni puntuali',
          'Allinea il team sugli owner per le attività aperte'
        ];
      case 'BOOK CLUB':
        return [
          'Prepara domande critiche per il prossimo incontro',
          'Annota citazioni rilevanti durante la lettura'
        ];
      default:
        return ['Definisci prossimi passi concreti legati al contenuto discusso'];
    }
  }

  static List<String> _suggestDecisions(Lifelog log) {
    switch (log.category.toUpperCase()) {
      case 'WORK':
        return [
          'Confermare milestone e responsabilità del progetto',
          'Stabilire criteri di successo per la prossima review'
        ];
      case 'BOOK CLUB':
        return ['Scegliere il capitolo o il libro successivo da discutere'];
      default:
        return ['Identificare quali decisioni devono essere formalizzate'];
    }
  }
}