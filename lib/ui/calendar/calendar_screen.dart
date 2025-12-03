import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:limitless_app/core/services/calendar_service.dart';
import 'package:limitless_app/models/calendar_event_model.dart';

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
      setState(() => _isLoading = false);
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
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
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
              child: const Icon(Icons.bolt, color: Colors.deepPurple),
            ),
            const SizedBox(width: 10),
            const Text(
              'Calendar',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFB476FF), Color(0xFF7F7CFF)],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
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
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'CALENDAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                            const SizedBox(height: 8),
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
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EVENTS - ${DateFormat('MMMM d').format(_selectedDay).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${selectedEvents.length} ${selectedEvents.length == 1 ? 'event' : 'events'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  selectedEvents.isEmpty 
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No events for this day.", style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          return _EventCard(event: event);
                        },
                      ),
                ],
              ),
            ),
    );
  }

  Future<void> _openAddEventSheet() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController(text: 'Conference Room A');
    final suggestionController = TextEditingController(
      text: 'Let the assistant prepare a summary and key action items.',
    );
    
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int durationHours = 1;

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
                top: 16,
                bottom: bottomInset + 16,
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
                          'New event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
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
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        DateFormat.yMMMMd().format(currentSelectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
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
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start time',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(selectedTime.format(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (hours)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              durationHours = int.tryParse(val) ?? 1;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: suggestionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'AI suggestion',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: const Color(0xFF7F7CFF),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) return;
                          
                          final startTime = DateTime(
                            currentSelectedDate.year,
                            currentSelectedDate.month,
                            currentSelectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          
                          final endTime = startTime.add(Duration(hours: durationHours));

                          final fullDescription = 
                              "Location: ${locationController.text}\nAI Suggestion: ${suggestionController.text}";

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
                          'Add event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 22, color: Colors.black87),
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
    final textColor = isCurrentMonth ? Colors.black87 : Colors.grey.shade400;

    Widget dotRow = const SizedBox.shrink();
    if (hasEvents) {
      final dots = List.generate(
        eventCount.clamp(1, 3),
        (index) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            color: Color(0xFF7F7CFF),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: isSelected
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB476FF), Color(0xFF7F7CFF)],
                    ),
                    shape: BoxShape.circle,
                  )
                : isToday
                    ? BoxDecoration(
                        color: const Color(0xFFF1F1F5),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          dotRow,
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    // Estraiamo Location e AI Suggestion dalla descrizione (se le abbiamo salvate lì)
    String location = "TBD";
    String aiSuggestion = "No suggestions";
    
    // Logica semplice di parsing della descrizione che abbiamo concatenato prima
    final lines = event.description.split('\n');
    for (var line in lines) {
      if (line.startsWith("Location:")) location = line.replaceAll("Location:", "").trim();
      if (line.startsWith("AI Suggestion:")) aiSuggestion = line.replaceAll("AI Suggestion:", "").trim();
    }
    
    // Calcolo durata
    final duration = event.endTime.difference(event.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationString = "${hours}h ${minutes > 0 ? '${minutes}m' : ''}";
    
    final startTimeString = DateFormat.jm().format(event.startTime);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8AC9), Color(0xFF7F7CFF)],
                    ),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$startTimeString · $durationString',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (aiSuggestion.isNotEmpty && aiSuggestion != "No suggestions") ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFF1A600),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Suggestion: $aiSuggestion',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}