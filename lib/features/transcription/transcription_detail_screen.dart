import 'package:flutter/material.dart';

class TranscriptionDetailScreen extends StatelessWidget {
  const TranscriptionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dettaglio Trascrizione')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Testo completo della trascrizione qui...', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Text('Segmenti, keyword o summary da mock API qui', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
