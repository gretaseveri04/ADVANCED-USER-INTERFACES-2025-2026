import 'dart:async';
import 'dart:convert'; // Necessario per jsonDecode
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle; // Necessario per caricare l'asset
import '../../models/lifelog_model.dart';
// ... (altri import) ...

// Rimuovi la lista 'final List<Map<String, dynamic>> _mockData = [...]'

class MockLifelogService {
  static const Duration _latency = Duration(milliseconds: 500);
  static const String _mockDataPath = 'mock_data/mock_responses.json'; // Percorso del tuo file

  // Nuovo metodo: Carica il JSON come stringa e lo decodifica
  Future<List<Map<String, dynamic>>> _loadJsonData() async {
    try {
      // 1. Legge il file JSON dalla cartella assets
      final String jsonString = await rootBundle.loadString(_mockDataPath);
      
      // 2. Decodifica la stringa JSON in una Map Dart
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      // 3. Estrae la lista dei lifelogs
      // Assicurati che la tua chiave 'lifelogs' corrisponda alla struttura del tuo JSON!
      if (jsonMap.containsKey('lifelogs') && jsonMap['lifelogs'] is List) {
        // Conversione della lista dinamica
        return List<Map<String, dynamic>>.from(jsonMap['lifelogs']);
      }
      return [];

    } catch (e) {
      if (kDebugMode) {
        print('Errore nel caricamento del mock JSON: $e');
      }
      return []; // Restituisce lista vuota in caso di errore
    }
  }


  Future<List<Lifelog>> getLifelogs({ 
    String? search,
    bool? isStarred,
    int limit = 10,
    String? direction,}) async {
    // 1. Simula l'attesa di rete
    await Future.delayed(_latency);
    
    // 2. Carica i dati dal JSON
    List<Map<String, dynamic>> rawData = await _loadJsonData(); // <--- Nuovo metodo

    // 3. Converte i dati fittizi in oggetti Lifelog
    List<Lifelog> results = rawData.map((data) => Lifelog.fromJson(data)).toList();

    // ... (Il resto della logica di filtro e ordinamento rimane invariato) ...

    return results;
  }
}