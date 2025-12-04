import 'package:flutter/material.dart';
import 'package:limitless_app/models/meeting_model.dart';

class TranscriptDetailScreen extends StatelessWidget {
  final Meeting meeting; 

  const TranscriptDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF), // Sfondo unificato
      
      // --- HEADER UNIFICATO ---
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE0E8FF).withOpacity(0.5),
                const Color(0xFFF8F8FF),
              ],
            ),
          ),
        ),
        title: Text(
          meeting.title.toUpperCase(), // Titolo MAIUSCOLO
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: Colors.black,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      // ------------------------

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con data (Card bianca pulita)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.calendar_today, size: 18, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Registrato il ${meeting.createdAt.toString().split('.')[0]}",
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            // Titolo sezione
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "TRANSCRIPT CONTENT",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
              ),
            ),
            
            // Box della trascrizione (Card bianca)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                meeting.transcription.isEmpty ? "Nessun testo trascritto." : meeting.transcription,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}