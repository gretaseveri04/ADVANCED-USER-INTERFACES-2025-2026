import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'; 

import 'package:limitless_app/core/services/calendar_service.dart';
import 'package:limitless_app/models/calendar_event_model.dart';
import 'package:limitless_app/models/meeting_model.dart';
import 'package:limitless_app/ui/transcript/transcript_detail_screen.dart';

import 'package:limitless_app/core/services/audio_recording_service.dart';
import 'package:limitless_app/core/services/meeting_repository.dart';
import 'package:limitless_app/core/services/openai_service.dart'; 

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _service = CalendarService();

  Map<DateTime, List<CalendarEvent>> _eventsByDay = {};
  late DateTime _focusedMonth;
  late DateTime _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(DateTime.now());
    _focusedMonth = DateTime(_selectedDay.year, _selectedDay.month);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _service.getMyEvents();
      setState(() {
        _eventsByDay = _groupByDay(events);
      });
    } catch (e) {
      debugPrint("Errore caricamento eventi: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<DateTime, List<CalendarEvent>> _groupByDay(List<CalendarEvent> events) {
    final map = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final normalized = _normalizeDate(event.startTime);
      map.putIfAbsent(normalized, () => []).add(event);
    }
    return map;
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysBefore = (first.weekday % 7); 
    final firstToShow = first.subtract(Duration(days: daysBefore));

    final last = DateTime(month.year, month.month + 1, 0);
    final daysAfter = 6 - (last.weekday % 7);
    final lastToShow = last.add(Duration(days: daysAfter));

    final days = <DateTime>[];
    for (var day = firstToShow;
        !day.isAfter(lastToShow);
        day = day.add(const Duration(days: 1))) {
      days.add(day);
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _handleEventTap(CalendarEvent event) async {
    final now = DateTime.now();

    if (event.endTime.isBefore(now)) {
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final realMeeting = await _fetchMeetingForEvent(event);
        
        if (mounted) Navigator.pop(context);

        if (realMeeting != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TranscriptDetailScreen(meeting: realMeeting),
            ),
          );
        } else {
          final placeholderMeeting = Meeting(
            id: 'placeholder',
            title: event.title,
            transcription: "Nessuna registrazione trovata per questo evento.\n"
                           "Probabilmente non hai registrato l'audio durante questo meeting.",
            createdAt: event.startTime,
            audioUrl: "",
            category: "General",
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TranscriptDetailScreen(meeting: placeholderMeeting),
            ),
          );
        }

      } catch (e) {
        if (mounted) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore nel recupero della trascrizione: $e")),
        );
      }
    } 
    else {
      _openRecordingSheet(event);
    }
  }

  Future<Meeting?> _fetchMeetingForEvent(CalendarEvent event) async {
    final supabase = Supabase.instance.client;
    
    final cleanTitle = event.title.trim();

    final localStartOfDay = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
    final localEndOfDay = localStartOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    final startQuery = localStartOfDay.toUtc().toIso8601String();
    final endQuery = localEndOfDay.toUtc().toIso8601String();

    debugPrint("🔍 CERCO MEETING: '$cleanTitle' tra $startQuery e $endQuery");

    try {
      final response = await supabase
          .from('meetings')
          .select()
          .ilike('title', cleanTitle)     
          .gte('created_at', startQuery)  
          .lte('created_at', endQuery)    
          .order('created_at', ascending: false) 
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint("Nessun meeting trovato. Controlla che i titoli coincidano.");
        return null; 
      }

      debugPrint("Meeting trovato! ID: ${response['id']}");

      return Meeting(
        id: response['id'].toString(),
        title: response['title'] ?? event.title,
        transcription: response['transcription_text'] ?? response['transcript'] ?? "Testo non trovato",
        createdAt: DateTime.parse(response['created_at']), 
        audioUrl: response['audio_url'] ?? "",
        category: response['category'] ?? "General",
      );

    } catch (e) {
      debugPrint("Errore ricerca DB: $e");
      return null;
    }
  }

  void _openRecordingSheet(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => RecordingSheet(eventTitle: event.title),
    ).then((_) {
      _loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthFormatter = DateFormat.yMMMM();
    final weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final days = _daysInMonth(_focusedMonth);
    final selectedEvents = _eventsByDay[_selectedDay] ?? [];

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
        title: const Text(
          "CALENDAR",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
              ]
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.deepPurple),
              onPressed: () {
                _openAddEventSheet();
              },
            ),
          ),
        ],
      ),

      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03), 
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                monthFormatter.format(_focusedMonth),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  _circleIconButton(
                                    Icons.chevron_left,
                                    onTap: () {
                                      setState(() {
                                        _focusedMonth = DateTime(
                                          _focusedMonth.year,
                                          _focusedMonth.month - 1,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _circleIconButton(
                                    Icons.chevron_right,
                                    onTap: () {
                                      setState(() {
                                        _focusedMonth = DateTime(
                                          _focusedMonth.year,
                                          _focusedMonth.month + 1,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final label in weekdayLabels)
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: days.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 4,
                            ),
                            itemBuilder: (context, index) {
                              final day = days[index];
                              final isCurrentMonth =
                                  day.month == _focusedMonth.month;
                              final isSelected = _isSameDay(day, _selectedDay);
                              final events = _eventsByDay[_normalizeDate(day)] ?? [];
                              return _buildDayCell(
                                day: day,
                                isCurrentMonth: isCurrentMonth,
                                isSelected: isSelected,
                                hasEvents: events.isNotEmpty,
                                eventCount: events.length,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM d').format(_selectedDay).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${selectedEvents.length} Events',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  selectedEvents.isEmpty 
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                        ),
                        child: const Center(child: Text("No events for this day.", style: TextStyle(color: Colors.grey))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          return GestureDetector(
                            onTap: () => _handleEventTap(event),
                            child: _EventCard(event: event),
                          );
                        },
                      ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Future<void> _openAddEventSheet() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController(text: 'Conference Room A');
    
    final durationController = TextEditingController(text: '15'); 
    
    TimeOfDay selectedTime = TimeOfDay.now(); 
    DateTime currentSelectedDate = _selectedDay;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: bottomInset + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Event',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: currentSelectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            currentSelectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat.yMMMMd().format(currentSelectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Event Title',
                        filled: true,
                        fillColor: const Color(0xFFF1F1F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setSheetState(() => selectedTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F1F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "At ${selectedTime.format(context)}", 
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Min',
                              filled: true,
                              fillColor: const Color(0xFFF1F1F5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              suffixText: 'min', 
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        hintText: 'Location',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF1F1F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.black, 
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) return;
                          
                          int minutes = int.tryParse(durationController.text) ?? 15;

                          final startTime = DateTime(
                            currentSelectedDate.year,
                            currentSelectedDate.month,
                            currentSelectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          
                          final endTime = startTime.add(Duration(minutes: minutes));

                          final fullDescription = "Location: ${locationController.text}";

                          final event = CalendarEvent(
                            title: titleController.text.trim(),
                            description: fullDescription,
                            startTime: startTime,
                            endTime: endTime,
                            isAllDay: false,
                          );

                          await _service.addEvent(event);

                          if (mounted) {
                             Navigator.of(context).pop();
                             _loadEvents(); 
                          }
                        },
                        child: const Text(
                          'Create Event',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _circleIconButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required bool isCurrentMonth,
    required bool isSelected,
    required bool hasEvents,
    required int eventCount,
  }) {
    final isToday = _isSameDay(day, DateTime.now());
    final textColor = isCurrentMonth ? Colors.black87 : Colors.grey.shade300;

    Widget dotRow = const SizedBox.shrink();
    if (hasEvents) {
      final dots = List.generate(
        eventCount.clamp(1, 3),
        (index) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFF7F7CFF),
            shape: BoxShape.circle,
          ),
        ),
      );
      dotRow = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: dots,
      );
    }

    return GestureDetector(
      onTap: () {
        if (!isCurrentMonth) return;
        setState(() {
          _selectedDay = _normalizeDate(day);
        });
      },
      child: Container(
        decoration: isSelected
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB476FF), Color(0xFF7F7CFF)],
                ),
                shape: BoxShape.circle,
              )
            : isToday
                ? BoxDecoration(
                    border: Border.all(color: const Color(0xFF7F7CFF), width: 1),
                    shape: BoxShape.circle,
                  )
                : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
            if (hasEvents) ...[
              const SizedBox(height: 2),
              dotRow,
            ]
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    String location = "TBD";
    
    final lines = event.description.split('\n');
    for (var line in lines) {
      if (line.startsWith("Location:")) {
        location = line.replaceAll("Location:", "").trim();
      }
    }
    
    final duration = event.endTime.difference(event.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationString = "${hours}h ${minutes > 0 ? '${minutes}m' : ''}";
    final startTimeString = DateFormat.jm().format(event.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8AC9), Color(0xFF7F7CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.event, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$startTimeString · $durationString',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  if (location.isNotEmpty && location != 'TBD') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class RecordingSheet extends StatefulWidget {
  final String eventTitle;
  const RecordingSheet({super.key, required this.eventTitle});

  @override
  State<RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends State<RecordingSheet> {
  final AudioRecordingService _audioService = AudioRecordingService();
  final OpenAIService _openAIService = OpenAIService();
  final MeetingRepository _meetingRepo = MeetingRepository();
  final CalendarService _calendarService = CalendarService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusMessage = "Ready to record";

  Timer? _timer;
  int _recordDuration = 0;

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      _audioService.stopRecording();
    }
    super.dispose();
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _recordDuration = 0;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (!_isRecording) {
      try {
        await _audioService.startRecording();
        _startTimer();
        if (mounted) {
          setState(() {
            _isRecording = true;
            _statusMessage = "Recording...";
          });
        }
      } catch (e) {
        if (mounted) setState(() => _statusMessage = "Error starting: $e");
      }
    } else {
      try {
        _stopTimer();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _isProcessing = true;
            _statusMessage = "Processing AI analysis...";
          });
        }

        final path = await _audioService.stopRecording();

        if (path != null) {
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
                  SnackBar(content: Text("📅 New event detected: ${detectedEvent.title}"))
              );
            }
          }

          final audioUrl = await _meetingRepo.uploadAudioBytes(audioBytes);

          await _meetingRepo.saveMeeting(
            title: widget.eventTitle,
            transcript: transcript,
            audioUrl: audioUrl,
          );

          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusMessage = "Saved!";
            });
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) Navigator.pop(context);
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = "Error: $e";
          });
        }
      }
    }
  }

  CalendarEvent? _analyzeTextForMeeting(String text) {
    final lowerText = text.toLowerCase();
    if (!lowerText.contains('meeting')) return null;

    final dayRegex = RegExp(r'(next\s+)?(on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)');
    final dayMatch = dayRegex.firstMatch(lowerText);
    DateTime? eventDate;

    if (dayMatch != null) {
      final isNext = dayMatch.group(1) != null;
      final dayName = dayMatch.group(3)!;
      eventDate = _getDateFromDayName(dayName, isNext: isNext);
    }

    if (eventDate != null) {
      final startTime = DateTime(eventDate.year, eventDate.month, eventDate.day, 10, 0);
      return CalendarEvent(
        title: "Meeting from Recording",
        description: "Source: ${widget.eventTitle}\nContent: $text",
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        isAllDay: false,
      );
    }
    return null;
  }

  DateTime _getDateFromDayName(String dayName, {bool isNext = false}) {
    final days = {
      'monday': DateTime.monday, 'tuesday': DateTime.tuesday, 'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday, 'friday': DateTime.friday, 'saturday': DateTime.saturday, 'sunday': DateTime.sunday
    };
    final now = DateTime.now();
    final targetWeekday = days[dayName] ?? DateTime.monday;
    int daysDiff = targetWeekday - now.weekday;
    if (daysDiff <= 0) daysDiff += 7;
    if (isNext) daysDiff += 7;
    return now.add(Duration(days: daysDiff));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          
          Text(
            widget.eventTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _isRecording ? _formatDuration(_recordDuration) : _statusMessage,
            style: TextStyle(
              color: _isRecording ? Colors.redAccent : (_isProcessing ? Colors.deepPurple : Colors.grey),
              fontWeight: FontWeight.w600,
              fontSize: 16
            ),
          ),
          
          const SizedBox(height: 40),
          
          if (_isProcessing)
             const CircularProgressIndicator()
          else
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 80, width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isRecording 
                      ? [const Color(0xFFFF4B4B), const Color(0xFFFF9068)] 
                      : [const Color(0xFFB476FF), const Color(0xFF7F7CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : const Color(0xFF7F7CFF)).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white, 
                  size: 38,
                ),
              ),
            ),
          const SizedBox(height: 40), 
        ],
      ),
    );
  }
}