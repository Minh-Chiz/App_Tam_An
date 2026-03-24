class FullAnalysis {
  final int totalEntries;
  final int emotionalScore;
  final List<EmotionDistItem> emotionDistribution;
  final Map<String, IntensityData> averageIntensity;
  final String trend;
  final List<String> suggestions;
  final List<ContextItem> topContexts;
  final int notesCount;
  final List<String> themes;
  final String? firstEntry;
  final String? lastEntry;
  final Map<String, Map<String, int>> monthlyData;

  FullAnalysis({
    required this.totalEntries,
    required this.emotionalScore,
    required this.emotionDistribution,
    required this.averageIntensity,
    required this.trend,
    required this.suggestions,
    required this.topContexts,
    required this.notesCount,
    required this.themes,
    this.firstEntry,
    this.lastEntry,
    required this.monthlyData,
  });

  factory FullAnalysis.fromJson(Map<String, dynamic> json) {
    // Parse intensity map
    final rawIntensity =
        json['average_intensity'] as Map<String, dynamic>? ?? {};
    final intensityMap = rawIntensity.map((k, v) {
      if (v is Map) {
        return MapEntry(k, IntensityData.fromJson(Map<String, dynamic>.from(v)));
      } else {
        // Fallback for legacy data/endpoints or errors
        return MapEntry(k, IntensityData(average: (v as num).toDouble(), count: 0));
      }
    });

    // Parse monthly data
    final rawMonthly = json['monthly_data'] as Map<String, dynamic>? ?? {};
    final monthlyMap = <String, Map<String, int>>{};
    rawMonthly.forEach((month, emotions) {
      final emotionMap = <String, int>{};
      (emotions as Map<String, dynamic>).forEach((emotion, count) {
        emotionMap[emotion] = (count as num).toInt();
      });
      monthlyMap[month] = emotionMap;
    });

    return FullAnalysis(
      totalEntries: json['total_entries'] ?? 0,
      emotionalScore: json['emotional_score'] ?? 0,
      emotionDistribution: (json['emotion_distribution'] as List?)
              ?.map((e) => EmotionDistItem.fromJson(e))
              .toList() ??
          [],
      averageIntensity: intensityMap,
      trend: json['trend'] ?? 'stable',
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
      topContexts: (json['top_contexts'] as List?)
              ?.map((e) => ContextItem.fromJson(e))
              .toList() ??
          [],
      notesCount: json['notes_count'] ?? 0,
      themes: (json['themes'] as List?)?.cast<String>() ?? [],
      firstEntry: json['first_entry'],
      lastEntry: json['last_entry'],
      monthlyData: monthlyMap,
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

  String get scoreLabel {
    if (emotionalScore >= 80) return 'Rất tốt';
    if (emotionalScore >= 60) return 'Tốt';
    if (emotionalScore >= 40) return 'Bình thường';
    if (emotionalScore >= 20) return 'Cần cải thiện';
    return 'Cần quan tâm';
  }
}

class EmotionDistItem {
  final String emotionType;
  final int count;
  final double percentage;

  EmotionDistItem({
    required this.emotionType,
    required this.count,
    required this.percentage,
  });

  factory EmotionDistItem.fromJson(Map<String, dynamic> json) {
    return EmotionDistItem(
      emotionType: json['emotion_type'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class ContextItem {
  final String context;
  final int count;

  ContextItem({required this.context, required this.count});

  factory ContextItem.fromJson(Map<String, dynamic> json) {
    return ContextItem(
      context: json['context'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class IntensityData {
  final double average;
  final int count;

  IntensityData({required this.average, required this.count});

  factory IntensityData.fromJson(Map<String, dynamic> json) {
    return IntensityData(
      average: (json['average'] ?? 0).toDouble(),
      count: (json['count'] ?? 0).toInt(),
    );
  }
}
