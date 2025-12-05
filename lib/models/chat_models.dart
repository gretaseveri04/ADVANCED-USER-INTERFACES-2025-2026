class ChatRoom {
  final String id;
  final String? name;
  final bool isGroup;
  final String? avatarUrl; 
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    this.name,
    required this.isGroup,
    this.avatarUrl, 
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      isGroup: json['is_group'] ?? false,
      avatarUrl: null, 
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final bool isAi; 

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMine,
    required this.isAi, 
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String myUserId) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isMine: json['sender_id'] == myUserId,
      isAi: json['is_ai'] ?? false, 
    );
  }
}