import 'package:flutter/material.dart';
import 'package:limitless_app/models/meeting_model.dart';

class TranscriptDetailScreen extends StatelessWidget {
  final Meeting meeting; // Ora accetta l'oggetto vero

  const TranscriptDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          meeting.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con data
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Registrato il ${meeting.createdAt.toString().split('.')[0]}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Box della trascrizione
            const Text(
              "TRANSCRIPT",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            Text(
              meeting.transcription.isEmpty ? "Nessun testo trascritto." : meeting.transcription,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}