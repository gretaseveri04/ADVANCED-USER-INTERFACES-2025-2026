import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:limitless_app/core/services/openai_service.dart'; // Usa OpenAI Service
import 'package:limitless_app/core/services/meeting_repository.dart'; // Per scaricare i meeting

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
  
  // Servizi
  final OpenAIService _aiService = OpenAIService();
  final MeetingRepository _meetingRepo = MeetingRepository();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Questa stringa conterrà tutta la conoscenza dei meeting
  String _meetingsContext = "";
  bool _isContextLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMeetingContext(); // Carichiamo la memoria all'avvio
    
    // Messaggio di benvenuto
    _messages.add(ChatMessage(
      content: "Hello! How can I help you today?",
      role: "assistant",
      timestamp: DateTime.now(),
    ));
  }

  /// Scarica tutti i meeting e crea una stringa unica di testo
  Future<void> _loadMeetingContext() async {
    try {
      final meetings = await _meetingRepo.fetchMeetings();
      
      final buffer = StringBuffer();
      for (final m in meetings) {
        final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(m.createdAt);
        buffer.writeln("--- MEETING: ${m.title} ($dateStr) ---");
        buffer.writeln("Trascrizione: ${m.transcription}"); // Usa 'transcription' o 'transcription_text' in base al tuo modello
        buffer.writeln("\n");
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
        content: text, role: "user", timestamp: DateTime.now());

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom(); 

    try {
      // ORA PASSIAMO IL CONTESTO DEI MEETING ALL'AI
      final reply = await _aiService.getChatResponse(
        text, 
        contextData: _meetingsContext // <--- IL SEGRETO È QUI
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF), // Sfondo leggermente colorato come il resto dell'app
      appBar: AppBar(
        // Rimosso l'immagine logo per coerenza con le altre schermate, puoi rimetterla se vuoi
        title: const Text("AI Assistant", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0, 
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Banner opzionale per mostrare se sta caricando la memoria
          if (!_isContextLoaded)
             Container(
               width: double.infinity,
               color: Colors.yellow.shade100,
               padding: const EdgeInsets.all(4),
               child: const Text("Sto leggendo i tuoi meeting...", textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
             ),

          Expanded(
            child: ListView.builder(
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
            onSend: _sendMessage,
            isEnabled: !_isLoading, // Disabilita input mentre l'AI pensa
          ),
        ],
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
    // Colori presi dal tema dell'app (Home)
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24), // Extra bottom padding per iPhone moderni
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