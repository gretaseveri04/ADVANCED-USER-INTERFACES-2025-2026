import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:limitless_app/models/chat_models.dart';
import 'package:limitless_app/core/services/chat_service.dart';
// Assicurati di importare il servizio che abbiamo fatto prima per Azure!
import 'package:limitless_app/core/services/openai_service.dart'; 

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
  final OpenAIService _aiService = OpenAIService(); // <--- Servizio Azure
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _senderNames = {};
  final Map<String, Color> _senderColors = {};
  
  bool _isAiThinking = false; // Per mostrare un indicatore di caricamento

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear(); 

    try {
      // 1. Invia il messaggio dell'utente (come faceva prima)
      await _chatService.sendMessage(widget.chatId, text);

      // 2. CONTROLLO TRIGGER AI: Se il messaggio contiene "@ai"
      if (text.toLowerCase().contains("@ai")) {
        _triggerAiResponse(text);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    }
  }

  // Nuova funzione che gestisce la risposta dell'AI
  Future<void> _triggerAiResponse(String userQuery) async {
    setState(() => _isAiThinking = true);

    try {
      // Recuperiamo gli ultimi 5 messaggi per dare contesto all'AI (opzionale)
      // Per ora mandiamo solo la domanda diretta per semplicità
      
      // Chiamata ad Azure (usa la funzione che abbiamo creato prima in openai_service.dart)
      final aiReply = await _aiService.getChatResponse(userQuery);

      // Inseriamo la risposta nel database manualmente
      final myUserId = _supabase.auth.currentUser!.id;
      
      await _supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': myUserId, // Tecnicamente il mittente è l'utente corrente...
        'content': aiReply,
        'is_ai': true, // ...ma segniamo che è l'AI
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      print("Errore AI: $e");
    } finally {
      if (mounted) setState(() => _isAiThinking = false);
    }
  }

  Future<String> _getSenderName(String userId) async {
    if (_senderNames.containsKey(userId)) {
      return _senderNames[userId]!;
    }
    // Se è l'AI, non cerchiamo nel DB
    // (Nota: questo controllo lo facciamo meglio nel buildBubble, ma per sicurezza)
    
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
                  reverse: true, // Importante: i messaggi nuovi sono in basso
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    
                    // Se non è mio e non è AI, cerco il nome
                    if (!msg.isMine && !msg.isAi && !_senderNames.containsKey(msg.senderId)) {
                      _getSenderName(msg.senderId);
                    }
                    return _buildBubble(msg);
                  },
                );
              },
            ),
          ),
          
          // Indicatore AI sta pensando...
          if (_isAiThinking)
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                   const SizedBox(width: 8),
                   Text("L'assistente sta scrivendo...", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                 ],
               ),
             ),

          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.isMine && !msg.isAi; // È mio solo se NON è AI
    final isAi = msg.isAi;

    String senderName = "...";
    Color senderColor = Colors.grey;

    if (isAi) {
      senderName = "AI Assistant ✨";
      senderColor = Colors.deepPurple;
    } else {
      senderName = _senderNames[msg.senderId] ?? "...";
      senderColor = _senderColors[msg.senderId] ?? Colors.grey;
    }

    return Align(
      // Se sono io -> Destra. Se è AI o Collega -> Sinistra
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Mostra il nome se NON sono io (quindi AI o Colleghi)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderName, 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: senderColor)
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // COLORE SFONDO:
                // Io -> Viola scuro
                // AI -> Viola chiarissimo (o un colore distintivo)
                // Colleghi -> Bianco
                color: isMe 
                    ? Colors.deepPurple 
                    : isAi 
                        ? const Color(0xFFF3E5F5) // Viola chiarissimo per AI
                        : Colors.white,
                
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), 
                  topRight: const Radius.circular(16), 
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4), 
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16)
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                border: isAi ? Border.all(color: Colors.deepPurple.withOpacity(0.3)) : null,
              ),
              child: Text(
                msg.content, 
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87, 
                  fontSize: 16
                )
              ),
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
                decoration: const InputDecoration(
                  hintText: "Scrivi (@ai per chiedere aiuto)...", // Suggerimento
                  border: InputBorder.none
                )
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