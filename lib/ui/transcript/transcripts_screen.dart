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
      backgroundColor: const Color(0xFFF8F8FF), 
      
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE0E8FF).withOpacity(0.5),
                const Color(0xFFF8F8FF),
              ],
            ),
          ),
        ),
        title: Text(
          lifelog.title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: Colors.deepPurple),
        ),
        title: Text(
          'Segmento ${index + 1}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          transcript.length > 40 
              ? "${transcript.substring(0, 40)}..." 
              : transcript,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/transcriptDetail',
            arguments: transcript,
          );
        },
      ),
    );
  }
}