class MonthlyWrapped {
  final int month;
  final int year;
  final int totalEntries;
  final int totalDays;
  final String mostCommonEmotion;
  final int positivePercentage;
  final int totalNotes;
  final List<dynamic> emotionDistribution;

  MonthlyWrapped({
    required this.month,
    required this.year,
    required this.totalEntries,
    required this.totalDays,
    required this.mostCommonEmotion,
    required this.positivePercentage,
    required this.totalNotes,
    required this.emotionDistribution,
  });

  factory MonthlyWrapped.fromJson(Map<String, dynamic> json) {
    return MonthlyWrapped(
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      totalEntries: json['total_entries'] ?? 0,
      totalDays: json['total_days'] ?? 0,
      mostCommonEmotion: json['most_common_emotion'] ?? 'Không có',
      positivePercentage: json['positive_percentage'] ?? 0,
      totalNotes: json['total_notes'] ?? 0,
      emotionDistribution: json['emotion_distribution'] ?? [],
    );
  }
}
