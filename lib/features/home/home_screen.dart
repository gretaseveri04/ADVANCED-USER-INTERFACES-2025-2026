import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/transcription'),
              child: Text('Trascrizione'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/chat'),
              child: Text('Chat AI'),
            ),
          ],
        ),
      ),
    );
  }
}
