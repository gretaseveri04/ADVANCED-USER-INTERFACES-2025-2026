class Meeting {
  final String id;
  final String title;
  final String transcription;
  final String summary;
  final String audioUrl;
  final DateTime createdAt;
  final String category;

  Meeting({
    required this.id,
    required this.title,
    required this.transcription,
    required this.summary,
    required this.audioUrl,
    required this.createdAt,
    required this.category,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      transcription: json['transcription_text'] ?? '',
      summary: json['summary'] ?? 'Nessun riassunto disponibile.', 
      audioUrl: json['audio_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'] ?? 'WORK',
    );
  }
}