class Emotion {
  final int id;
  final int userId;
  final String emotionType;
  final int intensity;
  final DateTime timestamp;
  final String? location;
  final String? activity;
  final String? company;
  final String? noteText;

  Emotion({
    required this.id,
    required this.userId,
    required this.emotionType,
    required this.intensity,
    required this.timestamp,
    this.location,
    this.activity,
    this.company,
    this.noteText,
  });

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      id: json['emotion_id'] ?? json['id'],
      userId: json['user_id'],
      emotionType: json['emotion_type'],
      intensity: json['intensity'] ?? 5,
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      activity: json['activity'],
      company: json['company'],
      noteText: json['note_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'emotion_type': emotionType,
      'intensity': intensity,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'activity': activity,
      'company': company,
      'note_text': noteText,
    };
  }

  // Helper method to get emoji for emotion type
  String get emoji {
    switch (emotionType) {
      case 'Vui':
        return '😊';
      case 'Bình thường':
        return '😌';
      case 'Buồn':
        return '😔';
      case 'Căng thẳng':
        return '😣';
      default:
        return '😐';
    }
  }
}

class EmotionStats {
  final String emotionType;
  final int count;
  final double percentage;
  final double avgIntensity;

  EmotionStats({
    required this.emotionType,
    required this.count,
    required this.percentage,
    required this.avgIntensity,
  });

  factory EmotionStats.fromJson(Map<String, dynamic> json) {
    return EmotionStats(
      emotionType: json['emotion_type'],
      count: json['count'],
      percentage: (json['percentage'] as num).toDouble(),
      avgIntensity: (json['avg_intensity'] as num?)?.toDouble() ?? 5.0,
    );
  }
}
