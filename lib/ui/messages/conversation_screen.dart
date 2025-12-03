import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:limitless_app/models/chat_models.dart';
import 'package:limitless_app/core/services/chat_service.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _senderNames = {};
  final Map<String, Color> _senderColors = {};

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear(); 
    try {
      await _chatService.sendMessage(widget.chatId, text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    }
  }

  Future<String> _getSenderName(String userId) async {
    if (_senderNames.containsKey(userId)) {
      return _senderNames[userId]!;
    }
    try {
      final data = await _supabase
          .from('profiles')
          .select('first_name, last_name, avatar_url') 
          .eq('id', userId)
          .maybeSingle();
      
      String name = "Utente";
      if (data != null) {
        name = "${data['first_name']} ${data['last_name']}".trim();
        if (name.isEmpty) name = "Sconosciuto";
        
      }

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
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
              child: widget.avatarUrl == null
                  ? Text(widget.chatName.isNotEmpty ? widget.chatName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 10),
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
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                if (messages.isEmpty) return const Center(child: Text("Nessun messaggio"));

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (!msg.isMine && !_senderNames.containsKey(msg.senderId)) {
                      _getSenderName(msg.senderId);
                    }
                    return _buildBubble(msg);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.isMine;
    final senderName = _senderNames[msg.senderId] ?? "...";
    final senderColor = _senderColors[msg.senderId] ?? Colors.grey;

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
                color: isMe ? Colors.deepPurple : Colors.white,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4), bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
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
              child: TextField(controller: _controller, onSubmitted: (_) => _sendMessage(), decoration: const InputDecoration(hintText: "Scrivi un messaggio...", border: InputBorder.none)),
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