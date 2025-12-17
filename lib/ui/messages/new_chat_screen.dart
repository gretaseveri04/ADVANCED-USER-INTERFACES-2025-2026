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
      backgroundColor: const Color(0xFFF8F8FF), 
      
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
        title: const Text(
          "NEW CHAT",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
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
              child: Text("Nessun collega trovato nella tua azienda.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: colleagues.length,
            itemBuilder: (context, index) {
              final user = colleagues[index];
              final firstName = user['first_name'] ?? '';
              final lastName = user['last_name'] ?? '';
              final fullName = "$firstName $lastName".trim();
              final initials = fullName.isNotEmpty ? fullName[0] : "?";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.deepPurple.shade50,
                    child: Text(initials, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['company'] ?? 'Unknown Company'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () => _openChat(user['id'], firstName, lastName),
                ),
              );
            },
          );
        },
      ),
    );
  }
}