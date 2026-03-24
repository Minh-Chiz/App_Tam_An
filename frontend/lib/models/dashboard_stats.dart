import 'emotion.dart';

class DashboardStats {
  final int totalEntries;
  final List<EmotionDistribution> emotionDistribution;
  final List<WeeklyEmotion> weeklyEmotions;
  final DashboardInsights insights;
  final List<Emotion> recentEntries;

  DashboardStats({
    required this.totalEntries,
    required this.emotionDistribution,
    required this.weeklyEmotions,
    required this.insights,
    required this.recentEntries,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEntries: json['total_entries'] ?? 0,
      emotionDistribution: (json['emotion_distribution'] as List?)
              ?.map((e) => EmotionDistribution.fromJson(e))
              .toList() ??
          [],
      weeklyEmotions: (json['weekly_emotions'] as List?)
              ?.map((e) => WeeklyEmotion.fromJson(e))
              .toList() ??
          [],
      insights: DashboardInsights.fromJson(json['insights'] ?? {}),
      recentEntries: (json['recent_entries'] as List?)
              ?.map((e) => Emotion.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EmotionDistribution {
  final String emotionType;
  final int count;
  final double percentage;

  EmotionDistribution({
    required this.emotionType,
    required this.count,
    required this.percentage,
  });

  factory EmotionDistribution.fromJson(Map<String, dynamic> json) {
    return EmotionDistribution(
      emotionType: json['emotion_type'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class WeeklyEmotion {
  final String date;
  final String emotionType;
  final String dayOfWeek;

  WeeklyEmotion({
    required this.date,
    required this.emotionType,
    required this.dayOfWeek,
  });

  factory WeeklyEmotion.fromJson(Map<String, dynamic> json) {
    return WeeklyEmotion(
      date: json['date'] ?? '',
      emotionType: json['emotion_type'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
    );
  }
}

class DashboardInsights {
  final String mostCommonEmotion;
  final String message;

  DashboardInsights({
    required this.mostCommonEmotion,
    required this.message,
  });

  factory DashboardInsights.fromJson(Map<String, dynamic> json) {
    return DashboardInsights(
      mostCommonEmotion: json['most_common_emotion'] ?? 'Bình thường',
      message: json['message'] ?? 'Bắt đầu ghi nhật ký để nhận phân tích!',
    );
  }
}
