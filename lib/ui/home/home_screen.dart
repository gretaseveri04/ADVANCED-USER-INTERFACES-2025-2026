import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:limitless_app/core/services/calendar_mock_service.dart';
import 'package:limitless_app/models/calendar_event_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CalendarMockService _calendarService = CalendarMockService();
  List<CalendarEvent> _eventsToday = [];
  late String _todayLabel;

  @override
  void initState() {
    super.initState();
    _todayLabel = DateFormat.yMMMMd().format(DateTime.now());
    _loadEvents(); 
  }

  void _loadEvents() {
    setState(() {
      _eventsToday = _calendarService.getEventsForDay(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    // NESSUNA BottomNavigationBar qui, è gestita da MainLayout
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
              _buildRecordSection(),
            ],
          ),
        ),
      ),
    );
  }

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
              child: Image.asset(
                'assets/images/logo.png', 
                width: 30,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.dashboard, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 26, 
          backgroundColor: Colors.white,
          child: Text(
            '😊',
            style: TextStyle(fontSize: 28),
          ),
        )
      ],
    );
  }

  Widget _buildUserInfo(String todayLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "YOUR NAME",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
                "your calendar",
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
    final items = eventsToday;

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
          child: items.isEmpty
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
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final e = items[index];
                    return _todoCard(
                      e.startTime,
                      e.title,
                      e.aiSuggestion, 
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
          Text(
            time, 
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F7CFF)
            )
          ),
          const SizedBox(height: 8),
          Text(
            task, 
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600
            )
          ),
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                const Text("AI Tip", style: TextStyle(fontSize: 10, color: Colors.grey))
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
        const Text(
          "START RECORDING",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE0F0), Color(0xFFE0E8FF)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Record audio with automatic AI transcription",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA8C9), Color(0xFFAEC9FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA8C9).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Record Audio",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}