import 'package:flutter/material.dart';
import 'package:limitless_app/core/services/mock_api_service.dart';
import 'package:limitless_app/models/lifelog_model.dart';

class LifelogScreen extends StatelessWidget {
  const LifelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Carica i dati in modo sincrono
    //
    final service = LifelogMockService();
    final lifelogs = service.getLifelogs().lifelogs;
    //
    //

    // Raggruppa i lifelogs per categoria
    final Map<String, List<Lifelog>> groupedLogs = {};
    for (var log in lifelogs) {
      if (!groupedLogs.containsKey(log.category)) {
        groupedLogs[log.category] = [];
      }
      groupedLogs[log.category]!.add(log);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'RECORDINGS AND TRANSCRIPTIONS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Genera dinamicamente le categorie e i loro item
            ...groupedLogs.entries.map((entry) {
              final category = entry.key;
              final logs = entry.value;

              return Column(
                children: [
                  _CategoryHeader(
                    title: category,
                    subtitle: category == 'WORK' ? 'User\'s company' : null,
                    leadingWidget: _getCategoryIcon(category),
                  ),
                  const SizedBox(height: 10),
                  ...logs.map((log) => _buildRecordingItem(context, log)),
                  const SizedBox(height: 30),
                ],
              );
            }).toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Genera l'icona appropriata per ogni categoria
  Widget _getCategoryIcon(String category) {
    if (category == 'WORK') {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          image: const DecorationImage(
            image: AssetImage('assets/images/polimi_logo.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (category == 'Book Club') {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.purple.shade50,
        ),
        child: Icon(Icons.book_outlined, size: 35, color: Colors.purple.shade300),
      );
    } else {
      // Icona di default per altre categorie
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.blue.shade50,
        ),
        child: Icon(Icons.folder_outlined, size: 35, color: Colors.blue.shade300),
      );
    }
  }

  Widget _buildRecordingItem(BuildContext context, Lifelog log) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            log.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${log.recordingCount} Recordings',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/transcription',
              arguments: log,
            );
          },
        ),
        const Divider(height: 1, thickness: 0.5, color: Colors.grey),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leadingWidget;

  const _CategoryHeader({
    required this.title,
    this.subtitle,
    required this.leadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leadingWidget,
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}