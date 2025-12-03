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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.black),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
              _loadChats();
            }, 
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
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 82),
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

    return InkWell(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: avatarColor,
              backgroundImage: chat.avatarUrl != null 
                  ? NetworkImage(chat.avatarUrl!) 
                  : null,
              child: chat.avatarUrl == null
                  ? (chat.isGroup 
                      ? const Icon(Icons.groups, color: Colors.white)
                      : Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Tocca per leggere i messaggi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}