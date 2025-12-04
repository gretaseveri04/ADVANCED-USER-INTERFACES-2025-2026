import 'package:flutter/material.dart'; 
import 'package:limitless_app/models/chat_models.dart';
import 'package:limitless_app/core/services/chat_service.dart';
import 'package:limitless_app/ui/messages/conversation_screen.dart';
import 'package:limitless_app/ui/messages/new_chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<ChatRoom>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _loadChats() {
    setState(() {
      _chatsFuture = _chatService.getMyChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- MODIFICA 1: Sfondo colorato uniformato ---
      backgroundColor: const Color(0xFFF8F8FF), 
      // ----------------------------------------------
      
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
              "MESSAGES",
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: IconButton(
              icon: const Icon(Icons.add_comment_rounded, color: Colors.deepPurple, size: 22),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
                _loadChats();
              }, 
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ChatRoom>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Errore: ${snapshot.error}"));
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return const Center(
              child: Text("Non hai ancora nessuna chat.\nCreane una col tasto + in alto!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }
          
          // --- MODIFICA 2: ListView.builder invece di separated ---
          // Usiamo le card, quindi non servono i divisori
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _ConversationTile(chat: conversations[index]);
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatRoom chat;
  const _ConversationTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final displayName = chat.name ?? "Chat Privata";
    final avatarColor = Colors.primaries[displayName.hashCode % Colors.primaries.length];
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    // --- MODIFICA 3: Design a Card (Riquadro Bianco) ---
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConversationScreen(
                  chatId: chat.id,
                  chatName: displayName,
                  avatarUrl: chat.avatarUrl,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarColor.withOpacity(0.2), // Colore più soft
                  backgroundImage: chat.avatarUrl != null 
                      ? NetworkImage(chat.avatarUrl!) 
                      : null,
                  child: chat.avatarUrl == null
                      ? (chat.isGroup 
                          ? Icon(Icons.groups, color: avatarColor)
                          : Text(initials, style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 18)))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName, 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tocca per leggere i messaggi", 
                        style: TextStyle(fontSize: 12, color: Colors.grey)
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}