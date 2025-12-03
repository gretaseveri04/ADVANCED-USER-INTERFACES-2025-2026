import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:limitless_app/core/services/meeting_repository.dart';
import 'package:limitless_app/models/meeting_model.dart';
import 'package:limitless_app/ui/transcript/transcript_detail_screen.dart';

class LifelogScreen extends StatefulWidget {
  const LifelogScreen({super.key});

  @override
  State<LifelogScreen> createState() => _LifelogScreenState();
}

class _LifelogScreenState extends State<LifelogScreen> {
  final MeetingRepository _repository = MeetingRepository();
  
  // Questa variabile conterrà il futuro caricamento dei dati
  late Future<List<Meeting>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = _repository.fetchMeetings();
  }

  // Funzione per ricaricare tirando giù la lista (Pull to refresh)
  Future<void> _refreshList() async {
    setState(() {
      _meetingsFuture = _repository.fetchMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'YOUR RECORDINGS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Meeting>>(
        future: _meetingsFuture,
        builder: (context, snapshot) {
          // 1. Caso Caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Caso Errore
          if (snapshot.hasError) {
            return Center(child: Text("Errore: ${snapshot.error}"));
          }

          // 3. Caso Lista Vuota
          final meetings = snapshot.data ?? [];
          if (meetings.isEmpty) {
            return const Center(
              child: Text("Nessuna registrazione trovata.\nTorna alla Home per registrarne una!", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // 4. Caso Dati Pronti -> Mostriamo la lista
          return RefreshIndicator(
            onRefresh: _refreshList,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                return _buildMeetingCard(context, meeting);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, Meeting meeting) {
    final dateStr = DateFormat('MMM d, y • HH:mm').format(meeting.createdAt);
    
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mic, color: Colors.deepPurple),
          ),
          title: Text(
            meeting.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(dateStr, style: TextStyle(color: Colors.grey.shade600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            // Naviga al dettaglio passando l'oggetto Meeting intero (o solo il testo)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TranscriptDetailScreen(meeting: meeting),
              ),
            );
          },
        ),
        const Divider(height: 30),
      ],
    );
  }
}