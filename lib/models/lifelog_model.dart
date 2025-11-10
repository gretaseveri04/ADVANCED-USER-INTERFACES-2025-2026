class Lifelog {
  final String id;
  final String title;
  final String date; // YYYY-MM-DD
  final String content; // Simula il contenuto dettagliato
  final String category; // Utile per raggruppare (es. 'WORK', 'Book Club')
  final int recordingCount;

  Lifelog({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    required this.category,
    required this.recordingCount,
  });

  factory Lifelog.fromJson(Map<String, dynamic> json) {
    return Lifelog(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      content: json['content'],
      category: json['category'],
      recordingCount: json['recordingCount'],
    );
  }
}