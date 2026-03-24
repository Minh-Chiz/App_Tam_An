class DailyEmotion {
  final int id;
  final int userId;
  final String emotionType;
  final int intensity;
  final String timestamp;
  final String? location;
  final String? activity;
  final String? company;
  final String? noteText;

  DailyEmotion({
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

  factory DailyEmotion.fromJson(Map<String, dynamic> json) {
    return DailyEmotion(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      emotionType: json['emotion_type'] ?? '',
      intensity: json['intensity'] ?? 5,
      timestamp: json['timestamp'] ?? '',
      location: json['location'],
      activity: json['activity'],
      company: json['company'],
      noteText: json['note_text'],
    );
  }

  DateTime get dateTime {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get timeString {
    final dt = dateTime;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  List<String> get tags {
    final List<String> result = [];
    if (location != null) result.add('#$location');
    if (activity != null) result.add('#$activity');
    if (company != null) result.add('#$company');
    return result;
  }
}
