import 'package:flutter/material.dart';
import 'package:limitless_app/core/services/chat_service.dart';
import 'package:limitless_app/ui/messages/conversation_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<Map<String, dynamic>>> _colleaguesFuture;

  @override
  void initState() {
    super.initState();
    _colleaguesFuture = _chatService.getColleagues();
  }

  void _openChat(String userId, String firstName, String lastName) async {
    final chatId = await _chatService.startPrivateChat(userId);
    
    if (chatId != null && mounted) {      
      final chatName = "$firstName $lastName";
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            chatId: chatId,
            chatName: chatName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossibile avviare la chat")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nuova Chat", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _colleaguesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final colleagues = snapshot.data ?? [];
          
          if (colleagues.isEmpty) {
            return const Center(
              child: Text("Nessun collega trovato nella tua azienda."),
            );
          }

          return ListView.separated(
            itemCount: colleagues.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = colleagues[index];
              final firstName = user['first_name'] ?? '';
              final lastName = user['last_name'] ?? '';
              final fullName = "$firstName $lastName".trim();
              final initials = fullName.isNotEmpty ? fullName[0] : "?";

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(initials, style: const TextStyle(color: Colors.deepPurple)),
                ),
                title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user['company'] ?? ''),
                onTap: () => _openChat(user['id'], firstName, lastName),
              );
            },
          );
        },
      ),
    );
  }
}