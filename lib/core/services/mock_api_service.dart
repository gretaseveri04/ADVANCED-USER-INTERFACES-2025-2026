import 'dart:convert';
import 'package:limitless_app/models/lifelog_model.dart';

class LifelogMockService {
  // JSON mockup
  static const String _mockJsonData = '''
  {
    "lifelogs": [
      {
        "id": "log1",
        "title": "PROJECT MEETING",
        "date": "2025-10-31",
        "content": "Discussione sulla fase 3 del progetto Alfa...",
        "category": "WORK",
        "recordingCount": 1,
        "transcriptions": [
          "Contenuto 1 tutto bene"
        ]
      },
      {
        "id": "log2",
        "title": "TRAINING SESSION",
        "date": "2025-10-30",
        "content": "Sessione di formazione sul nuovo sistema...",
        "category": "WORK",
        "recordingCount": 2,
        "transcriptions": []
      },
      {
        "id": "log3",
        "title": "DOC REVIEW",
        "date": "2025-10-29",
        "content": "Revisione documentazione tecnica...",
        "category": "WORK",
        "recordingCount": 1,
        "transcriptions": []
      },
      {
        "id": "log4",
        "title": "CLIENT CALL",
        "date": "2025-10-28",
        "content": "Chiamata con il cliente per requirements...",
        "category": "WORK",
        "recordingCount": 1,
        "transcriptions": []
      },
      {
        "id": "log5",
        "title": "1984",
        "date": "2025-10-31",
        "content": "Discussione del capitolo 3 del libro 1984.",
        "category": "Book Club",
        "recordingCount": 1,
        "transcriptions": []
      },
      {
        "id": "log6",
        "title": "ANIMAL FARM",
        "date": "2025-10-25",
        "content": "Analisi dei temi principali di Animal Farm.",
        "category": "Book Club",
        "recordingCount": 1,
        "transcriptions": []
      },
      {
        "id": "log7",
        "title": "THE GREAT GATSBY",
        "date": "2025-10-20",
        "content": "Discussione sul simbolismo nel romanzo.",
        "category": "Book Club",
        "recordingCount": 1,
        "transcriptions": []
      }
    ]
  }
  ''';

  // Ottiene tutti i lifelogs in modo sincrono
  LifelogResponse getLifelogs() {
    try {
      final Map<String, dynamic> jsonData = json.decode(_mockJsonData);
      return LifelogResponse.fromJson(jsonData);
    } catch (e) {
      throw Exception('Errore nella decodifica del JSON: $e');
    }
  }

  // Ottiene un singolo lifelog per ID
  Lifelog? getLifelogById(String id) {
    try {
      final response = getLifelogs();
      return response.lifelogs.firstWhere(
        (log) => log.id == id,
        orElse: () => throw Exception('Lifelog non trovato'),
      );
    } catch (e) {
      return null;
    }
  }

  // Filtra i lifelogs per categoria
  List<Lifelog> getLifelogsByCategory(String category) {
    final response = getLifelogs();
    return response.lifelogs
        .where((log) => log.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}