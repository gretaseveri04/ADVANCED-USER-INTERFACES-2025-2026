import 'package:flutter/material.dart';
import 'ui/auth/login_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/transcription/transcription_screen.dart';
import 'ui/transcription/transcription_detail_screen.dart';
import 'ui/chat/chat_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Limitless AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomeScreen(),
        '/transcription': (_) => TranscriptionScreen(),
        '/transcriptionDetail': (_) => TranscriptionDetailScreen(),
        '/chat': (_) => ChatScreen(),
      },
    );
  }
}
