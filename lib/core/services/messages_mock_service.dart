import 'package:limitless_app/models/conversation_model.dart';

class MessagesMockService {
  static final List<Conversation> _conversations = [
    Conversation(
      id: '1',
      name: 'Marketing Team',
      lastMessage: 'Laura: Great work on the campaign!',
      time: '10:42',
      unreadCount: 3,
      isGroup: true,
      participants: ['Laura', 'Marco', 'Tu'],
    ),
    Conversation(
      id: '2',
      name: 'Anna Neri',
      lastMessage: 'See you at the meeting',
      time: 'Yesterday',
      isOnline: true,
      unreadCount: 0,
    ),
    Conversation(
      id: '3',
      name: 'Dev Team',
      lastMessage: 'Mark: Deployed to production',
      time: 'Yesterday',
      isGroup: true,
      isOnline: true, 
    ),
    Conversation(
      id: '4',
      name: 'Paolo Blu',
      lastMessage: 'Thanks for the feedback!',
      time: 'Monday',
      isOnline: false,
    ),
    Conversation(
      id: '5',
      name: 'Product Team',
      lastMessage: 'Meeting rescheduled to 3pm',
      time: 'Monday',
      unreadCount: 1,
      isGroup: true,
    ),
    Conversation(
      id: '6',
      name: 'Marco Ferrari',
      lastMessage: 'Let me check and get back to you',
      time: 'Sunday',
      isOnline: true,
    ),
  ];

  List<Conversation> getConversations() => _conversations;
}