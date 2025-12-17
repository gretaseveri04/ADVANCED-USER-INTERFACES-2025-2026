import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:limitless_app/models/chat_models.dart';
import 'package:limitless_app/core/services/chat_service.dart';
import 'package:limitless_app/core/services/openai_service.dart';
import 'package:limitless_app/core/services/meeting_repository.dart';
import 'package:intl/intl.dart';

class ConversationScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? avatarUrl; 

  const ConversationScreen({
    super.key, 
    required this.chatId, 
    required this.chatName,
    this.avatarUrl, 
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ChatService _chatService = ChatService();
  final OpenAIService _aiService = OpenAIService();
  final MeetingRepository _meetingRepo = MeetingRepository(); 
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _senderNames = {};
  final Map<String, Color> _senderColors = {};
  
  bool _isAiThinking = false;
  String? _meetingsContext; 

  // NUOVO: Variabile per memorizzare lo stream ed evitare riconnessioni continue
  late Stream<List<ChatMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _loadMeetingContext();
    // Inizializziamo lo stream qui, UNA VOLTA SOLA.
    // Grazie a Supabase Realtime, riceverà automaticamente i nuovi messaggi.
    _messagesStream = _chatService.getMessagesStream(widget.chatId);
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
      _meetingsContext = buffer.toString();
    } catch (e) {
      print("Errore caricamento contesto: $e");
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear(); 
    try {
      await _chatService.sendMessage(widget.chatId, text);
      
      // OPTIONAL: Se Realtime su Supabase è lento, puoi decommentare la riga sotto
      // per forzare un aggiornamento grafico immediato (anche se poco elegante).
      // setState(() {}); 

      if (text.toLowerCase().contains("@ai")) {
        _triggerAiResponse(text);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    }
  }

  Future<void> _triggerAiResponse(String userQuery) async {
    setState(() => _isAiThinking = true);
    try {
      if (_meetingsContext == null) await _loadMeetingContext();
      final aiReply = await _aiService.getChatResponse(userQuery, contextData: _meetingsContext);
      final myUserId = _supabase.auth.currentUser!.id;
      
      // Inseriamo la risposta AI. Nota: NON mettiamo 'created_at', lasciamo fare al DB.
      await _supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': myUserId, 
        'content': aiReply,
        'is_ai': true, 
      });
    } catch (e) {
      print("Errore AI: $e");
    } finally {
      if (mounted) setState(() => _isAiThinking = false);
    }
  }

  Future<String> _getSenderName(String userId) async {
    if (_senderNames.containsKey(userId)) return _senderNames[userId]!;
    try {
      final data = await _supabase.from('profiles').select('first_name, last_name').eq('id', userId).maybeSingle();
      String name = "Utente";
      if (data != null) name = "${data['first_name']} ${data['last_name']}".trim();
      if (name.isEmpty) name = "Sconosciuto";

      if (mounted) {
        setState(() {
          _senderNames[userId] = name;
          _senderColors[userId] = Colors.primaries[name.hashCode % Colors.primaries.length];
        });
      }
      return name;
    } catch (e) { return "Utente"; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
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
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
              child: widget.avatarUrl == null
                  ? Text(widget.chatName.isNotEmpty ? widget.chatName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.deepPurple, fontSize: 16, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.chatName,
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            // CORREZIONE QUI: Usiamo _messagesStream invece di chiamare la funzione ogni volta
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream, 
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  // Se non abbiamo dati, mostriamo un loader o niente
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data!;
                
                // Se la lista è vuota
                if (messages.isEmpty) {
                  return const Center(child: Text("Start the conversation!", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (!msg.isMine && !msg.isAi && !_senderNames.containsKey(msg.senderId)) {
                      _getSenderName(msg.senderId);
                    }
                    return _buildBubble(msg);
                  },
                );
              },
            ),
          ),
          
          if (_isAiThinking)
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                   const SizedBox(width: 8),
                   Text("AI is typing...", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                 ],
               ),
             ),

          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildBubble(ChatMessage msg) {
    // ... (Il resto del codice UI rimane identico) ...
    final isMe = msg.isMine && !msg.isAi;
    final isAi = msg.isAi;
    String senderName = isAi ? "AI Assistant ✨" : (_senderNames[msg.senderId] ?? "...");
    Color senderColor = isAi ? Colors.deepPurple : (_senderColors[msg.senderId] ?? Colors.grey);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(senderName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: senderColor)),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple : (isAi ? const Color(0xFFF3E5F5) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), 
                  topRight: const Radius.circular(16), 
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4), 
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16)
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                border: isAi ? Border.all(color: Colors.deepPurple.withOpacity(0.3)) : null,
              ),
              child: Text(msg.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F1F5), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _controller, 
                onSubmitted: (_) => _sendMessage(), 
                decoration: const InputDecoration(hintText: "Write a message (@ai for help)...", border: InputBorder.none)
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}