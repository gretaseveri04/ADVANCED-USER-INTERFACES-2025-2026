
class Lifelog {
  final String id;
  final String title;
  final String date;
  final String content;
  final String category;
  final int recordingCount;
  final List<String> transcripts;

  Lifelog({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    required this.category,
    required this.recordingCount,
    required this.transcripts,
  });

  factory Lifelog.fromJson(Map<String, dynamic> json) {
    return Lifelog(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      recordingCount: json['recordingCount'] as int,
      transcripts: List<String>.from(json['transcripts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'content': content,
      'category': category,
      'recordingCount': recordingCount,
      'transcripts': transcripts,
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