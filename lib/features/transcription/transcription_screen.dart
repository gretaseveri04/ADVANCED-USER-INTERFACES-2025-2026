import 'package:flutter/material.dart';

class TranscriptionScreen extends StatelessWidget {
  const TranscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trascrizione')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Qui verranno visualizzate le trascrizioni', textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Vai al dettaglio trascrizione
                Navigator.pushNamed(context, '/transcriptionDetail');
              },
              child: Text('Mostra Dettaglio Trascrizione'),
            ),
          ],
        ),
      ),
    );
  }
}
