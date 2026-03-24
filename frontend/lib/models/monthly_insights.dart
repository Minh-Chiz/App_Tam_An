class MonthlyInsights {
  final int month;
  final int year;
  final int totalEntries;
  final String mostCommonEmotion;
  final String trend;
  final List<String> suggestions;
  final Map<String, int> emotionBreakdown;
  final Map<String, double> averageIntensity;
  final int notesCount;
  final List<TopContext> topContexts;

  MonthlyInsights({
    required this.month,
    required this.year,
    required this.totalEntries,
    required this.mostCommonEmotion,
    required this.trend,
    required this.suggestions,
    required this.emotionBreakdown,
    this.averageIntensity = const {},
    this.notesCount = 0,
    this.topContexts = const [],
  });

  factory MonthlyInsights.fromJson(Map<String, dynamic> json) {
    // Parse averageIntensity (values may come as int or double)
    final rawIntensity = json['average_intensity'] as Map<String, dynamic>? ?? {};
    final intensityMap = rawIntensity.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    // Parse topContexts
    final rawContexts = json['top_contexts'] as List? ?? [];
    final contexts = rawContexts
        .map((c) => TopContext.fromJson(c as Map<String, dynamic>))
        .toList();

    return MonthlyInsights(
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      totalEntries: json['total_entries'] ?? 0,
      mostCommonEmotion: json['most_common_emotion'] ?? 'Bình thường',
      trend: json['trend'] ?? 'stable',
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
      emotionBreakdown: Map<String, int>.from(json['emotion_breakdown'] ?? {}),
      averageIntensity: intensityMap,
      notesCount: json['notes_count'] ?? 0,
      topContexts: contexts,
    );
  }

  String get trendIcon {
    switch (trend) {
      case 'improving':
        return '📈';
      case 'declining':
        return '📉';
      default:
        return '➡️';
    }
  }

  String get trendText {
    switch (trend) {
      case 'improving':
        return 'Xu hướng tích cực';
      case 'declining':
        return 'Cần cải thiện';
      default:
        return 'Ổn định';
    }
  }

  /// Overall emotional "score" for the month (0-100)
  int get emotionalScore {
    if (totalEntries == 0) return 0;
    final positiveEmotions = ['Vui', 'Vui vẻ'];
    final neutralEmotions = ['Bình thường'];

    int positiveCount = 0;
    int neutralCount = 0;
    for (var entry in emotionBreakdown.entries) {
      if (positiveEmotions.contains(entry.key)) {
        positiveCount += entry.value;
      } else if (neutralEmotions.contains(entry.key)) {
        neutralCount += entry.value;
      }
    }
    // Positive = 100, Neutral = 60, Negative = 20
    final score = ((positiveCount * 100 + neutralCount * 60 +
            (totalEntries - positiveCount - neutralCount) * 20) /
        totalEntries)
        .round();
    return score.clamp(0, 100);
  }
}

class TopContext {
  final String context;
  final int count;

  TopContext({required this.context, required this.count});

  factory TopContext.fromJson(Map<String, dynamic> json) {
    return TopContext(
      context: json['context'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
