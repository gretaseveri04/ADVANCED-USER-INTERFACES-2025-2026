import 'package:flutter/material.dart';
import '../../models/lifelog_model.dart';

class TranscriptionScreen extends StatelessWidget {
  const TranscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        centerTitle: false, // Per allineare il titolo a sinistra
        backgroundColor: Colors.transparent, // Sfondo trasparente
        elevation: 0, // Nessuna ombra
        foregroundColor: Colors.black, // Colore delle icone/testo dell'AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // --- Sezione WORK ---
            _CategoryHeader(
              title: 'WORK',
              subtitle: 'User\'s company',
              // Per l'immagine del Politecnico, avresti bisogno di un asset
              // Per semplicità, userò un CircleAvatar con un'icona
              leadingWidget: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/polimi_logo.png'), // <--- Assicurati di aggiungere questo asset!
                    fit: BoxFit.cover,
                  ),
                ),
                // Se non hai il logo, puoi usare un'icona di fallback:
                // child: const Icon(Icons.business_center, size: 30, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            _buildRecordingItem(context, 'PROJECT MEETING', 7),
            _buildRecordingItem(context, 'TRANING SESSION', 10),
            _buildRecordingItem(context, 'DOC REVIEW', 7),
            _buildRecordingItem(context, 'CLIENT CALL', 15),

            const SizedBox(height: 30), // Spazio tra le categorie

            // --- Sezione Book Club ---
            _CategoryHeader(
              title: 'Book Club',
              leadingWidget: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), // Bordi arrotondati
                  color: Colors.purple.shade50, // Sfondo leggermente colorato
                ),
                child: Icon(Icons.book_outlined, size: 35, color: Colors.purple.shade300),
              ),
            ),
            const SizedBox(height: 10),
            _buildRecordingItem(context, '1984', 1),
            _buildRecordingItem(context, 'ANIMAL FARM', 1),
            _buildRecordingItem(context, 'THE GREAT GATSBY', 1),

            const SizedBox(height: 50), // Spazio extra in fondo
          ],
        ),
      ),
    );
  }

  // Widget helper per costruire ogni riga di registrazione
  Widget _buildRecordingItem(BuildContext context, String title, int count) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero, // Rimuove il padding di default di ListTile
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count Recordings',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
          onTap: () {
            // Logica per navigare al dettaglio della registrazione
            Navigator.pushNamed(context, '/transcriptionDetail', arguments: title);
          },
        ),
        const Divider(height: 1, thickness: 0.5, color: Colors.grey), // Separatore sottile
      ],
    );
  }
}

// Widget per l'intestazione di ogni categoria (es. WORK, Book Club)
class _CategoryHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leadingWidget; // Può essere un'immagine o un'icona

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
          leadingWidget, // L'immagine o l'icona
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