import 'package:flutter/material.dart';
import 'package:limitless_app/models/meeting_model.dart';
import 'package:limitless_app/widgets/briefing_avatar.dart'; // Importa l'avatar robotico
import 'package:limitless_app/core/services/briefing_service.dart'; // Servizio ElevenLabs
import 'package:audioplayers/audioplayers.dart'; // Player audio

class TranscriptDetailScreen extends StatefulWidget {
  final Meeting meeting; 

  const TranscriptDetailScreen({super.key, required this.meeting});

  @override
  State<TranscriptDetailScreen> createState() => _TranscriptDetailScreenState();
}

class _TranscriptDetailScreenState extends State<TranscriptDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BriefingService _briefingService = BriefingService();
  bool _isBillTalking = false; // Stato per animare il robottino

  @override
  void dispose() {
    _audioPlayer.dispose(); // Pulizia risorse audio
    super.dispose();
  }

  // Funzione per avviare il briefing vocale di Bill Oxley
  void _playAIBriefing() async {
    if (widget.meeting.summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nessun riassunto disponibile per questo meeting.")),
      );
      return;
    }

    setState(() => _isBillTalking = true); // Attiva l'animazione

    try {
      // 1. Ottieni l'audio sintetizzato dal riassunto
      final path = await _briefingService.getBriefingAudio(widget.meeting.summary);
      
      // 2. Riproduci il file
      await _audioPlayer.play(DeviceFileSource(path));
      
      // 3. Quando l'audio finisce, ferma l'animazione
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isBillTalking = false);
      });
    } catch (e) {
      if (mounted) setState(() => _isBillTalking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore nella generazione audio: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF), 
      
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
          widget.meeting.title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: Colors.black,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SEZIONE ASSISTENTE AI (Wow Factor) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  // L'avatar Rive sincronizzato con lo stato _isBillTalking
                  BriefingAvatar(isTalking: _isBillTalking),
                  const SizedBox(height: 10),
                  Text(
                    _isBillTalking ? "Your FocusMate is talking..." : "Do you need a summary?",
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _isBillTalking ? null : _playAIBriefing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: Icon(_isBillTalking ? Icons.graphic_eq : Icons.play_arrow_rounded),
                    label: const Text("LISTEN TO BRIEFING"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            
            // --- INFO DATA RECORDING ---
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
                    "Recorded on ${widget.meeting.createdAt.toString().split('.')[0]}",
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "TRANSCRIPT CONTENT",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
              ),
            ),
            
            // --- CONTENUTO DELLA TRASCRIZIONE ---
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
                widget.meeting.transcription.isEmpty ? "Nessun testo trascritto." : widget.meeting.transcription,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}