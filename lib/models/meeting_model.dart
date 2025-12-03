class Meeting {
  final String id;
  final String title;
  final String transcription;
  final String audioUrl;
  final DateTime createdAt;
  final String category;

  Meeting({
    required this.id,
    required this.title,
    required this.transcription,
    required this.audioUrl,
    required this.createdAt,
    required this.category,
  });

  // Questo serve per trasformare i dati di Supabase (JSON) in oggetto Dart
  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      transcription: json['transcription_text'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'] ?? 'WORK',
    );
  }
}