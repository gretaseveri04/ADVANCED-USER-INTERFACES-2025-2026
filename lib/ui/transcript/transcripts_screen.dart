import 'package:flutter/material.dart';
import 'package:limitless_app/models/lifelog_model.dart';

class TranscriptScreen extends StatelessWidget {
  final Lifelog lifelog;

  const TranscriptScreen({
    super.key,
    required this.lifelog,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          lifelog.title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: lifelog.transcripts.isEmpty
          ? const Center(
              child: Text(
                'No transcript available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              itemCount: lifelog.transcripts.length,
              itemBuilder: (context, index) {
                final transcript = lifelog.transcripts[index];
                return _buildTranscriptItem(context, transcript, index);
              },
            ),
    );
  }

  Widget _buildTranscriptItem(
      BuildContext context,
      String transcript,
      int index,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.mic, color: Colors.blue.shade400, size: 22),
          title: Text(
            'Registrazione ${index + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.grey),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/transcriptDetail',
              arguments: transcript,
            );
          },
        ),
        const Divider(height: 1, thickness: 0.5, color: Colors.grey),
      ],
    );
  }

}
