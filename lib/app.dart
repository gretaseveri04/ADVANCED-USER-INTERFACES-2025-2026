import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/transcription/transcription_screen.dart';
import 'features/transcription/transcription_detail_screen.dart';
import 'features/chat/chat_screen.dart';

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
