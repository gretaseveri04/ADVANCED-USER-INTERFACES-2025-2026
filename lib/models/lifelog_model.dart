/// classe obj Lifelog permette di trasformare i dati json in oggetti dart
class Lifelog {
  final String id;
  final String title;
  final String date;
  final String content;
  final String category;
  final int recordingCount;

  Lifelog({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    required this.category,
    required this.recordingCount,
  });

  // Factory per creare un Lifelog da JSON
  factory Lifelog.fromJson(Map<String, dynamic> json) {
    return Lifelog(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      recordingCount: json['recordingCount'] as int,
    );
  }

  // Metodo per convertire in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'content': content,
      'category': category,
      'recordingCount': recordingCount,
    };
  }
}

class LifelogResponse {
  final List<Lifelog> lifelogs;

  LifelogResponse({required this.lifelogs});

  factory LifelogResponse.fromJson(Map<String, dynamic> json) {
    var list = json['lifelogs'] as List;
    List<Lifelog> lifelogList = list.map((i) => Lifelog.fromJson(i)).toList();
    
    return LifelogResponse(lifelogs: lifelogList);
  }

  Map<String, dynamic> toJson() {
    return {
      'lifelogs': lifelogs.map((e) => e.toJson()).toList(),
    };
  }
}