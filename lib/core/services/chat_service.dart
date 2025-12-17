import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:limitless_app/models/chat_models.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> createGroupChat(String name, List<String> userIds) async {
    try {
      final response = await _supabase.rpc('create_chat_room', params: {
        'room_name': name,
        'member_ids': userIds,
      });
      return response as String;
    } catch (e) {
      print("Errore creazione chat RPC: $e");
      return null;
    }
  }

  Future<List<ChatRoom>> getMyChats() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return [];

    final response = await _supabase
        .from('chat_participants')
        .select('chat_id, chats(*)')
        .eq('user_id', myId);
    
    final List<ChatRoom> chats = [];
    final Map<String, String> privateChatToUser = {};
    final Set<String> userIdsToFetch = {};

    for (var item in response) {
      final chatData = item['chats'];
      if (chatData == null) continue;
      
      final bool isGroup = chatData['is_group'] ?? false;

      if (isGroup) {
        chats.add(ChatRoom.fromJson(chatData));
      } else {
        chats.add(ChatRoom(
          id: chatData['id'],
          name: null, 
          isGroup: false,
          avatarUrl: null, 
          createdAt: DateTime.parse(chatData['created_at']).toLocal(),
        ));
        privateChatToUser[chatData['id']] = ""; 
      }
    }

    if (privateChatToUser.isEmpty) {
       chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
       return chats;
    }

    final participantsResponse = await _supabase
        .from('chat_participants')
        .select('chat_id, user_id')
        .inFilter('chat_id', privateChatToUser.keys.toList())
        .neq('user_id', myId);
    
    for (var row in participantsResponse) {
      final chatId = row['chat_id'];
      final userId = row['user_id'];
      privateChatToUser[chatId] = userId;
      userIdsToFetch.add(userId);
    }

    if (userIdsToFetch.isNotEmpty) {
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, avatar_url') 
          .inFilter('id', userIdsToFetch.toList());
      
      final Map<String, Map<String, String?>> profilesMap = {};
      
      for (var p in profilesResponse) {
        final fullName = "${p['first_name']} ${p['last_name']}".trim();
        profilesMap[p['id']] = {
          'name': fullName.isNotEmpty ? fullName : "Utente",
          'avatar': p['avatar_url'], 
        };
      }

      for (var i = 0; i < chats.length; i++) {
        final chat = chats[i];
        if (!chat.isGroup && chat.name == null) {
          final otherUserId = privateChatToUser[chat.id];
          if (otherUserId != null) {
            final profile = profilesMap[otherUserId];
            final realName = profile?['name'] ?? "Sconosciuto";
            final realAvatar = profile?['avatar'];

            chats[i] = ChatRoom(
              id: chat.id,
              name: realName,
              isGroup: false,
              avatarUrl: realAvatar, 
              createdAt: chat.createdAt,
            );
          }
        }
      }
    }
    
    chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return chats;
  }
  
  Future<List<Map<String, dynamic>>> getColleagues() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final myCompany = user.userMetadata?['company'];
    if (myCompany == null) return [];
    try {
      final List<dynamic> response = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, company')
          .eq('company', myCompany)
          .neq('id', user.id);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  Future<String?> startPrivateChat(String colleagueId) async {
    try {
      final response = await _supabase.rpc('get_or_create_private_chat', params: {'target_user_id': colleagueId});
      return response as String;
    } catch (e) { return null; }
  }

  Future<void> syncCompanyChat(String companyName) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null || companyName.isEmpty) return;

    try {
      final List<dynamic> colleagues = await _supabase
          .from('profiles')
          .select('id')
          .eq('company', companyName)
          .neq('id', myId);

      if (colleagues.isEmpty) return;

      final List<String> colleagueIds = colleagues
          .map((c) => c['id'] as String)
          .toList();

      final String chatId = await _supabase.rpc('get_or_create_company_chat', params: {
        'target_company_name': companyName,
      });

      final Set<String> allParticipants = {myId, ...colleagueIds};

      final List<Map<String, dynamic>> participantsData = allParticipants
          .map((uid) => {'chat_id': chatId, 'user_id': uid})
          .toList();
  
      await _supabase.from('chat_participants').upsert(
        participantsData, 
        onConflict: 'chat_id, user_id' 
      );

    } catch (e) {
      print("Errore sync chat aziendale: $e");
    }
  }

  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    final myId = _supabase.auth.currentUser?.id ?? '';
    return _supabase.from('messages').stream(primaryKey: ['id']).eq('chat_id', chatId).order('created_at', ascending: false).map((data) => data.map((json) => ChatMessage.fromJson(json, myId)).toList());
  }

  Future<void> sendMessage(String chatId, String content) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    // CORRETTO: Non stiamo passando 'created_at', ci pensa il DB
    await _supabase.from('messages').insert({
      'chat_id': chatId, 
      'sender_id': myId, 
      'content': content
    });
  }
}