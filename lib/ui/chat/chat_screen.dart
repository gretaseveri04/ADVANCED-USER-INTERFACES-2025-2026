import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:limitless_app/core/services/openai_service.dart';
import 'package:limitless_app/core/services/meeting_repository.dart';

class ChatMessage {
  final String content;
  final String role; 
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final OpenAIService _aiService = OpenAIService();
  final MeetingRepository _meetingRepo = MeetingRepository();

  // Lista messaggi
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  String _meetingsContext = "";
  bool _isContextLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMeetingContext();
    
    // Messaggio di benvenuto iniziale
    _messages.add(ChatMessage(
      content: "Hi there! 👋 I'm your personal AI assistant. I can help with summaries, emails and more.",
      role: "assistant",
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _loadMeetingContext() async {
    try {
      final meetings = await _meetingRepo.fetchMeetings();
      final buffer = StringBuffer();
      
      for (final m in meetings) {
        final localTime = m.createdAt.toLocal();
        final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(localTime);

        if (m.transcription.isNotEmpty) {
           buffer.writeln("--- MEETING: ${m.title} ($dateStr) ---");
           buffer.writeln("Contenuto: ${m.transcription}");
           buffer.writeln("\n");
        }
      }
      
      setState(() {
        _meetingsContext = buffer.toString();
        _isContextLoaded = true;
      });
      print("🧠 Memoria AI caricata: ${meetings.length} meeting indicizzati.");
      
    } catch (e) {
      print("Errore caricamento contesto meeting: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? specificText}) async {
    final text = specificText ?? _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
        content: text, role: "user", timestamp: DateTime.now());

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _controller.clear();
    if (specificText != null) FocusScope.of(context).unfocus(); 
    
    _scrollToBottom(); 

    try {
      final reply = await _aiService.getChatResponse(
        text, 
        contextData: _meetingsContext
      );
      
      final aiMessage = ChatMessage(
          content: reply, role: "assistant", timestamp: DateTime.now());

      setState(() {
        _messages.add(aiMessage);
      });
    } catch (e) {
      final errorMessage = ChatMessage(
          content: "Errore: ${e.toString()}",
          role: "assistant",
          timestamp: DateTime.now());
      setState(() {
        _messages.add(errorMessage);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showSuggestions = _messages.length <= 1;

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
              "AI ASSISTANT",
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
      body: Column(
        children: [
          if (!_isContextLoaded)
             Container(
               width: double.infinity,
               color: Colors.yellow.shade100,
               padding: const EdgeInsets.all(4),
               child: const Text("Sto leggendo i tuoi meeting...", textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
             ),

          Expanded(
            child: showSuggestions 
                ? _buildEmptyStateWithSuggestions() 
                : ListView.builder(               
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),
          
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              minHeight: 2,
            ),
            
          _ChatInputField(
            controller: _controller,
            onSend: () => _sendMessage(),
            isEnabled: !_isLoading, 
          ),
        ],
      ),
    );
  }

  // --- WIDGET SUGGESTIONS ---
  Widget _buildEmptyStateWithSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30), // Spazio dall'alto aumentato un po'
          
          // --- RIMOSSO IL PALLINO QUI ---
          
          const Text(
            "How can I help you today?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "I have access to all your recordings, transcripts,\nmeetings and calendar.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // GRIGLIA SUGGESTIONS
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4, 
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _suggestionCard(
                Icons.description, 
                Colors.orange, 
                "Summarize meetings", 
                "Please give me a summary of my recent meetings."
              ),
              _suggestionCard(
                Icons.email, 
                Colors.orange, 
                "Write email", 
                "Draft a follow-up email based on the last meeting."
              ),
              _suggestionCard(
                Icons.list, 
                Colors.orange, 
                "Create task list", 
                "Extract action items from my last recording and make a list."
              ),
              _suggestionCard(
                Icons.lightbulb, 
                Colors.orange, 
                "Brainstorm", 
                "Help me brainstorm ideas based on the project discussed."
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          // Messaggio di benvenuto
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("👋", style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Hi there! I'm your personal AI assistant. I can help you with summaries, emails, tasks, suggestions and more. How can I help you today?",
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _suggestionCard(IconData icon, Color iconColor, String title, String prompt) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: () => _sendMessage(specificText: prompt), 
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor, 
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == "user";
    final userColor = const Color(0xFF7F7CFF); 
    final aiColor = Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? userColor : aiColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;

  const _ChatInputField({required this.controller, required this.onSend, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ), 
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5), 
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                enabled: isEnabled,
                decoration: const InputDecoration(
                  hintText: "Ask about your meetings...",
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => isEnabled ? onSend() : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isEnabled ? onSend : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isEnabled 
                    ? const LinearGradient(colors: [Color(0xFFB476FF), Color(0xFF7F7CFF)])
                    : const LinearGradient(colors: [Colors.grey, Colors.grey]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}