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
  late Future<List<Meeting>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = _repository.fetchMeetings();
  }

  Future<void> _refreshList() async {
    setState(() {
      _meetingsFuture = _repository.fetchMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      // --- HEADER UNIFICATO ---
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 10),
            const Text(
              "YOUR RECORDINGS",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      // ------------------------
      body: FutureBuilder<List<Meeting>>(
        future: _meetingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Errore: ${snapshot.error}"));
          }

          final meetings = snapshot.data ?? [];
          if (meetings.isEmpty) {
            return const Center(
              child: Text("Nessuna registrazione trovata.\nTorna alla Home per registrarne una!", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

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
    final dateStr = DateFormat('MMM d, y • HH:mm').format(meeting.createdAt.toLocal()); 
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Spazio tra le card
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF), // Viola chiarissimo
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.mic, color: Colors.deepPurple),
        ),
        title: Text(
          meeting.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TranscriptDetailScreen(meeting: meeting),
            ),
          );
        },
      ),
    );
  }
}