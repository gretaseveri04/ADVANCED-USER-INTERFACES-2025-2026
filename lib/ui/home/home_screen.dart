import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:limitless_app/models/calendar_event_model.dart';
import 'package:limitless_app/core/services/calendar_service.dart';
import 'package:limitless_app/core/services/audio_recording_service.dart';
import 'package:limitless_app/core/services/openai_service.dart';
import 'package:limitless_app/core/services/meeting_repository.dart';
import 'package:limitless_app/core/services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CalendarService _calendarService = CalendarService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final OpenAIService _openAIService = OpenAIService();
  final MeetingRepository _meetingRepo = MeetingRepository();

  late final StreamSubscription<AuthState> _authSubscription;
  
  List<CalendarEvent> _eventsToday = [];
  late String _todayLabel;
  String _userName = "User";
  String? _avatarUrl; 
  
  bool _isRecording = false;
  bool _isProcessing = false;
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
    _audioService.cancel();
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
      final now = DateTime.now();
      final allEvents = await _calendarService.getEventsForDay(now);
      
      final upcomingEvents = allEvents.where((event) {
        return event.startTime.isAfter(now);
      }).toList();

      if (mounted) {
        setState(() {
          _eventsToday = upcomingEvents;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<String?> _showRecordingTitleDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Name this recording", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Give your meeting a title to find it easily later.", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "e.g. Project Brainstorming",
                filled: true,
                fillColor: const Color(0xFFF1F1F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Skip", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (!_isRecording) {
      try {
        await _audioService.startRecording();
        setState(() => _isRecording = true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore avvio: $e")));
      }
    } else {
      try {
        final path = await _audioService.stopRecording();
        
        String? userTitle;
        if (path != null && mounted) {
           userTitle = await _showRecordingTitleDialog();
        }

        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });

        if (path != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Elaborazione audio & AI in corso...")),
            );
          }

          Uint8List audioBytes;
          if (path.startsWith('http') || path.startsWith('blob')) {
             final response = await http.get(Uri.parse(path));
             audioBytes = response.bodyBytes;
          } else {
             final file = File(path);
             audioBytes = await file.readAsBytes();
          }

          final transcript = await _openAIService.transcribeAudioBytes(audioBytes, 'recording.m4a'); 
          final detectedEvent = _analyzeTextForMeeting(transcript);
          
          if (detectedEvent != null) {
            await _calendarService.addEvent(detectedEvent);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.deepPurple, 
                  content: Text("📅 Event Detected: ${detectedEvent.title}"),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }

          final audioUrl = await _meetingRepo.uploadAudioBytes(audioBytes);
          final String briefingText = await AIService.generateBriefing(transcript);
          
          String finalTitle;
          if (userTitle != null && userTitle.isNotEmpty) {
            finalTitle = userTitle;
          } else {
            finalTitle = detectedEvent != null 
              ? "Meeting: ${DateFormat('MMMM d').format(detectedEvent.startTime)}" 
              : "Meeting ${DateFormat('HH:mm').format(DateTime.now())}";
          }

          await _meetingRepo.saveMeeting(
            title: finalTitle,
            transcript: transcript,
            summary: briefingText,
            audioUrl: audioUrl,
          );

          if (mounted) _loadEvents(); 
        }
      } catch (e) {
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
              "DASHBOARD", 
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
        actions: const [], 
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildUserInfo(_todayLabel),
            const SizedBox(height: 25),
            _buildCalendarCard(context),
            const SizedBox(height: 25),
            _buildTodoList(_eventsToday),
            const SizedBox(height: 25),
            _buildRecordSection(),
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String todayLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userName.toUpperCase(), 
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "today: $todayLabel",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFB476FF), Color(0xFF7F7CFF), Color(0xFFFFB4E1)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null 
                  ? Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : "U", 
                      style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 20)
                    )
                  : null,
            ),
          ),
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
          "UPCOMING TODAY", 
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
                      "No upcoming events for today.\nFree time! 🎉",
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
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/calendar');
                        _loadEvents();
                      },
                      child: _todoCard(timeString, e.title, aiSuggestion),
                    );
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

  Widget _buildRecordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("START RECORDING", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        InkWell(
          onTap: _toggleRecording,
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
                
                if (_isProcessing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      const Text("Transcribing...", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
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

  CalendarEvent? _analyzeTextForMeeting(String text) {
    final lowerText = text.toLowerCase();
    if (!lowerText.contains('meeting')) return null;

    final now = DateTime.now();
    DateTime? eventDate;

    final dayRegex = RegExp(r'(next\s+)?(on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)');
    final dayMatch = dayRegex.firstMatch(lowerText);

    if (dayMatch != null) {
      final isNext = dayMatch.group(1) != null;
      final dayName = dayMatch.group(3)!;
      eventDate = _getDateFromDayName(dayName, isNext: isNext);
    }

    if (eventDate == null) {
      final dateRegex = RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(st|nd|rd|th)?');
      final dateMatch = dateRegex.firstMatch(lowerText);
      if (dateMatch != null) {
        final monthName = dateMatch.group(1)!;
        final dayNumber = int.parse(dateMatch.group(2)!);
        eventDate = _getDateFromMonthDay(monthName, dayNumber);
      }
    }

    if (eventDate != null) {
      final startTime = DateTime(eventDate.year, eventDate.month, eventDate.day, 10, 0);
      final endTime = startTime.add(const Duration(hours: 1));
      return CalendarEvent(
        title: "Meeting (Detected)",
        description: "Auto-generated from transcript: \"$text\"",
        startTime: startTime,
        endTime: endTime,
        isAllDay: false,
      );
    }
    return null;
  }

  DateTime _getDateFromDayName(String dayName, {bool isNext = false}) {
    final days = {'monday': DateTime.monday, 'tuesday': DateTime.tuesday, 'wednesday': DateTime.wednesday, 'thursday': DateTime.thursday, 'friday': DateTime.friday, 'saturday': DateTime.saturday, 'sunday': DateTime.sunday};
    final now = DateTime.now();
    final targetWeekday = days[dayName]!;
    int daysDiff = targetWeekday - now.weekday;
    if (daysDiff <= 0) daysDiff += 7;
    if (isNext) daysDiff += 7;
    return now.add(Duration(days: daysDiff));
  }

  DateTime _getDateFromMonthDay(String monthName, int day) {
    final months = {'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12};
    final now = DateTime.now();
    final month = months[monthName]!;
    int year = now.year;
    if (month < now.month) year++;
    return DateTime(year, month, day);
  }
}