import 'package:flutter/material.dart';

class TranscriptionDetailScreen extends StatelessWidget {
  const TranscriptionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transcription Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Complete text here...', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16), 
            Text('Keyword o summary here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
