import 'package:flutter/material.dart';
import 'package:limitless_app/core/services/ai_service.dart';

class ChatMessage {
  final String content;
  final String role; 
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });
}



class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
        content: text, role: "user", timestamp: DateTime.now());

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom(); 

    try {
      final reply = await AIService.sendMessage(text);
      final aiMessage = ChatMessage(
          content: reply, role: "assistant", timestamp: DateTime.now());

      setState(() {
        _messages.add(aiMessage);
      });
    } catch (e) {
      final errorMessage = ChatMessage(
          content: "Errore: ${e.toString()}",
          role: "assistant",
          timestamp: DateTime.now());
      setState(() {
        _messages.add(errorMessage);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png', 
          height: 48,
        ),

        centerTitle: true,
        elevation: 0, 
        backgroundColor: Colors.white,


      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              
              color: Colors.deepPurple,
            ),
          _ChatInputField(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}


class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == "user";
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.white,
          borderRadius: borderRadius,
          boxShadow: [
            
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Inputbar widget
class _ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputField({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white, 
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.grey),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100], 
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Message...",
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
         
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurple),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}