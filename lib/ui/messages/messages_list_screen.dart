import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importa i tuoi modelli e servizi reali
import 'package:limitless_app/models/chat_models.dart';
import 'package:limitless_app/core/services/chat_service.dart';
import 'package:limitless_app/ui/messages/conversation_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final ChatService _chatService = ChatService();
  
  // Variabile per gestire il caricamento
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

  /// Funzione temporanea per creare una chat di test e vedere se funziona
  Future<void> _createTestChat() async {
    final inputController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuova Chat"),
        content: TextField(
          controller: inputController,
          decoration: const InputDecoration(hintText: "Nome del gruppo"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
          TextButton(
            onPressed: () => Navigator.pop(context, inputController.text),
            child: const Text("Crea"),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      // Nota: qui per ora non aggiungiamo altri utenti, creiamo solo la stanza
      // In futuro dovrai passare una lista di ID utenti veri
      await _chatService.createGroupChat(name, []); 
      _loadChats(); // Ricarica la lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.black),
            onPressed: _createTestChat, // Crea chat vera su Supabase
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
              child: Text("Non hai ancora nessuna chat.\nCreane una col tasto + in alto!", 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
    // Generiamo un avatar colorato basato sul nome
    final avatarColor = Colors.primaries[chat.name.hashCode % Colors.primaries.length];
    final initials = chat.name != null && chat.name!.isNotEmpty 
        ? chat.name![0].toUpperCase() 
        : "?";

    return InkWell(
      onTap: () {
        // Naviga verso la schermata della conversazione vera
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              chatId: chat.id,
              chatName: chat.name ?? "Chat",
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
              child: chat.isGroup 
                ? const Icon(Icons.groups, color: Colors.white)
                : Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name ?? "Senza nome",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Tocca per leggere i messaggi", // Qui potremmo mettere l'ultimo messaggio se facciamo una query più complessa
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}