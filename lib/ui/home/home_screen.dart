import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import dei modelli
import 'package:limitless_app/models/calendar_event_model.dart';

// Import dei servizi (ASSICURATI CHE QUESTI FILE ESISTANO)
import 'package:limitless_app/core/services/calendar_service.dart';
import 'package:limitless_app/core/services/audio_recording_service.dart';
import 'package:limitless_app/core/services/openai_service.dart';
import 'package:limitless_app/core/services/meeting_repository.dart';
// Aggiungi queste due righe in cima al file:
import 'dart:typed_data'; // <--- Risolve l'errore "Undefined class Uint8List"
import 'package:http/http.dart' as http; // <--- Serve per scaricare il file audio su Web

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- 1. INIZIALIZZAZIONE DEI SERVIZI ---
  final CalendarService _calendarService = CalendarService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final OpenAIService _openAIService = OpenAIService();
  final MeetingRepository _meetingRepo = MeetingRepository();

  late final StreamSubscription<AuthState> _authSubscription;
  
  List<CalendarEvent> _eventsToday = [];
  late String _todayLabel;
  String _userName = "User";
  String? _avatarUrl; 
  
  // Stati per la UI
  bool _isRecording = false;
  bool _isProcessing = false; // Nuovo stato: caricamento/trascrizione in corso
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _todayLabel = DateFormat.yMMMMd().format(DateTime.now());
    
    _loadUserData(); 
    _loadEvents(); 

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.userUpdated || event == AuthChangeEvent.initialSession) {
        _loadUserData();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _audioService.cancel(); // Importante: rilascia il microfono se chiudi l'app
    super.dispose();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      if (mounted) {
        setState(() {
          _userName = metadata?['name'] ?? 'User';
          _avatarUrl = metadata?['avatar_url']; 
        });
      }
    }
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _calendarService.getEventsForDay(DateTime.now());
      if (mounted) {
        setState(() {
          _eventsToday = events;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      debugPrint("Errore home events: $e");
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  // --- 2. LA LOGICA DI REGISTRAZIONE ---
  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (!_isRecording) {
      // START
      try {
        print("🎙️ Avvio registrazione...");
        // Su web non passiamo path, lasciamo che il browser gestisca
        await _audioService.startRecording(); 
        setState(() => _isRecording = true);
      } catch (e) {
        print("❌ Errore avvio: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
      }
    } else {
      // STOP
      setState(() {
        _isRecording = false;
        _isProcessing = true; 
      });

      try {
        print("🛑 Stop registrazione...");
        
        // 1. Ottieni il percorso (su Web è un blob URL)
        final path = await _audioService.stopRecording();
        
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Elaborazione dati...")),
          );

          // --- MAGIA PER IL WEB: Convertiamo tutto in Bytes ---
          Uint8List audioBytes;
          
          // Se è un URL di rete (Blob su web), lo scarichiamo
          if (path.startsWith('http') || path.startsWith('blob')) {
             final response = await http.get(Uri.parse(path));
             audioBytes = response.bodyBytes;
          } else {
             // Fallback per mobile (se usassi dart:io File(path).readAsBytesSync())
             // Ma per ora testiamo su web
             throw Exception("Su web ci aspettiamo un blob url");
          }

          // 2. Trascrivi (passando i bytes)
          print("🧠 Invio a OpenAI...");
          // Usiamo un nome file finto .webm perché Chrome registra in quel formato solitamente
          final transcript = await _openAIService.transcribeAudioBytes(audioBytes, 'recording.webm'); 
          print("✅ Trascrizione: $transcript");

          // 3. Carica su Supabase (passando i bytes)
          print("☁️ Upload...");
          final audioUrl = await _meetingRepo.uploadAudioBytes(audioBytes);

          // 4. Salva DB
          final defaultTitle = "Web Meeting ${DateFormat('HH:mm').format(DateTime.now())}";
          await _meetingRepo.saveMeeting(
            title: defaultTitle,
            transcript: transcript,
            audioUrl: audioUrl,
          );

          print("🎉 Fatto!");
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(backgroundColor: Colors.green, content: Text("Salvato!")),
            );
             _loadEvents(); // Ricarica eventuali eventi
          }
        }
      } catch (e) {
        print("❌ ERRORE: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Errore: $e")));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildUserInfo(_todayLabel),
              const SizedBox(height: 25),
              _buildCalendarCard(context),
              const SizedBox(height: 25),
              _buildTodoList(_eventsToday),
              const SizedBox(height: 25),
              _buildRecordSection(), // Qui c'è il tasto magico
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS UI ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.dashboard, color: Colors.deepPurple, size: 30),
            ),
            const SizedBox(width: 10),
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        
        CircleAvatar(
          radius: 26, 
          backgroundColor: Colors.white,
          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
          child: _avatarUrl == null 
              ? const Text('😊', style: TextStyle(fontSize: 28))
              : null,
        )
      ],
    );
  }

  Widget _buildUserInfo(String todayLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _userName.toUpperCase(), 
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "today: $todayLabel",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/calendar');
        _loadEvents();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.calendar_month, size: 30),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "Your Calendar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18)
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList(List<CalendarEvent> eventsToday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TODAY'S TODO LIST",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110, 
          child: _isLoadingEvents 
            ? const Center(child: CircularProgressIndicator())
            : eventsToday.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      "No events scheduled for today.\nEnjoy your free time! 🎉",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: eventsToday.length,
                  itemBuilder: (context, index) {
                    final e = eventsToday[index];
                    final timeString = DateFormat.jm().format(e.startTime);
                    String aiSuggestion = "";
                    if (e.description.contains("AI Suggestion:")) {
                       aiSuggestion = e.description.split("AI Suggestion:").last.trim();
                    }
                    return _todoCard(timeString, e.title, aiSuggestion);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _todoCard(String time, String task, String suggestion) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7F7CFF))),
          const SizedBox(height: 8),
          Text(
            task, 
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)
          ),
          if (suggestion.isNotEmpty && suggestion != "No suggestions") ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                const Expanded(child: Text("AI Tip", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey)))
              ],
            )
          ]
        ],
      ),
    );
  }

  // --- 3. SEZIONE BOTTONE REGISTRAZIONE ---
  Widget _buildRecordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("START RECORDING", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        InkWell(
          onTap: _toggleRecording, // Chiama la nuova funzione
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isRecording ? const Color(0xFFF3F0FF) : null,
              gradient: _isRecording ? null : const LinearGradient(colors: [Color(0xFFFFE0F0), Color(0xFFE0E8FF)]),
              borderRadius: BorderRadius.circular(24),
              border: _isRecording ? Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Record audio with automatic AI transcription", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 24),
                
                // GESTIONE STATI: CARICAMENTO, REGISTRAZIONE, RIPOSO
                if (_isProcessing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      const Text("Transcribing & Saving...", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  )
                else if (_isRecording)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      const Text("Recording in progress...", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFA8C9), Color(0xFFAEC9FF)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFA8C9).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mic, color: Colors.white), SizedBox(width: 10), Text("Record Audio", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}