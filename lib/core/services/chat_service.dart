import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/chat_models.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Crea una nuova chat di gruppo e aggiunge i partecipanti
  
  /// Crea una chat usando la funzione sicura SQL (RPC)
  Future<String?> createGroupChat(String name, List<String> userIds) async {
    try {
      // Chiamiamo la funzione SQL 'create_chat_room' che abbiamo appena creato
      final response = await _supabase.rpc('create_chat_room', params: {
        'room_name': name,
        'member_ids': userIds,
      });
      
      return response as String; // Ritorna l'ID della chat creata
    } catch (e) {
      print("Errore creazione chat RPC: $e");
      return null;
    }
  }

  /// Ottiene la lista delle chat dell'utente
  Future<List<ChatRoom>> getMyChats() async {
    // Nota: Supabase fa fatica con le join complesse sulle policy.
    // Per semplicità qui prendiamo le chat dove l'utente è partecipante.
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return [];

    final response = await _supabase
        .from('chat_participants')
        .select('chat_id, chats(*)')
        .eq('user_id', myId);
    
    final List<ChatRoom> chats = [];
    for (var item in response) {
      if (item['chats'] != null) {
        chats.add(ChatRoom.fromJson(item['chats']));
      }
    }
    return chats;
  }

  /// STREAM DEI MESSAGGI: Ascolta in tempo reale i nuovi messaggi di una chat
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    final myId = _supabase.auth.currentUser?.id ?? '';
    
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false) // Più recenti in basso (o in alto a seconda della UI)
        .map((data) => data
            .map((json) => ChatMessage.fromJson(json, myId))
            .toList());
  }

  /// Invia un messaggio
  Future<void> sendMessage(String chatId, String content) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'content': content,
    });
  }

  /// Cerca colleghi e crea/aggiorna la chat aziendale
  Future<void> syncCompanyChat(String companyName) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null || companyName.isEmpty) return;

    try {
      // 1. Cerca altri utenti con la stessa azienda nella tabella 'profiles'
      final List<dynamic> colleagues = await _supabase
          .from('profiles')
          .select('id')
          .eq('company', companyName) // Cerca azienda uguale
          .neq('id', myId);           // Escludi me stesso

      // Se non c'è nessuno, non fare nulla
      if (colleagues.isEmpty) return;

      final List<String> colleagueIds = colleagues
          .map((c) => c['id'] as String)
          .toList();

      // 2. Controlla se ho già una chat chiamata "Company: [Nome]"
      final myChats = await getMyChats();
      final chatName = "Company: $companyName";
      
      String? existingChatId;
      for (var chat in myChats) {
        if (chat.name == chatName) {
          existingChatId = chat.id;
          break;
        }
      }

      if (existingChatId != null) {
        // SCENARIO A: La chat esiste già -> Aggiungiamo i colleghi mancanti
        // (Per semplicità proviamo ad inserirli tutti, Supabase ignorerà i duplicati grazie alla Primary Key)
        final List<Map<String, dynamic>> participantsData = colleagueIds
            .map((uid) => {'chat_id': existingChatId, 'user_id': uid})
            .toList();
            
        await _supabase.from('chat_participants').upsert(participantsData);
        
      } else {
        // SCENARIO B: La chat non esiste -> Creiamo un nuovo gruppo con TUTTI
        await createGroupChat(chatName, colleagueIds);
      }

    } catch (e) {
      print("Errore sync chat aziendale: $e");
    }
  }
}