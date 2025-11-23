import 'package:flutter/material.dart';
import 'package:limitless_app/models/lifelog_model.dart';

class TranscriptionScreen extends StatelessWidget {
  const TranscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recupera il log passato come argomento
    final Lifelog log = ModalRoute.of(context)!.settings.arguments as Lifelog;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          log.title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: log.transcriptions.isEmpty
          ? const Center(
              child: Text(
                'Nessuna trascrizione disponibile',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              itemCount: log.transcriptions.length,
              itemBuilder: (context, index) {
                final transcription = log.transcriptions[index];
                return _buildTranscriptionItem(context, transcription, index);
              },
            ),
    );
  }

  Widget _buildTranscriptionItem(BuildContext context, String transcription, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: Colors.blue.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Registrazione ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              transcription,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}