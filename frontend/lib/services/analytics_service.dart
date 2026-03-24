import 'package:tam_an/models/emotion.dart';
import 'package:tam_an/services/emotion_service.dart';

class EmotionStats {
  final int totalEmotions;
  final String mostCommonEmotion;
  final double averageIntensity;
  final int streakDays;
  final Map<String, int> emotionCounts;

  EmotionStats({
    required this.totalEmotions,
    required this.mostCommonEmotion,
    required this.averageIntensity,
    required this.streakDays,
    required this.emotionCounts,
  });
}

class EmotionTrend {
  final DateTime date;
  final Map<String, double> emotionIntensities;

  EmotionTrend({
    required this.date,
    required this.emotionIntensities,
  });
}

class AnalyticsService {
  final EmotionService _emotionService;

  AnalyticsService(this._emotionService);

  // Get emotions grouped by day
  Future<Map<DateTime, List<Emotion>>> getEmotionsByDay(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final emotions = await _emotionService.getEmotions();
      final grouped = <DateTime, List<Emotion>>{};

      for (var emotion in emotions) {
        final date = DateTime(
          emotion.timestamp.year,
          emotion.timestamp.month,
          emotion.timestamp.day,
        );

        if (date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)))) {
          grouped.putIfAbsent(date, () => []);
          grouped[date]!.add(emotion);
        }
      }

      return grouped;
    } catch (e) {
      print('Analytics Service Error: $e');
      return {};
    }
  }

  // Get emotion distribution
  Future<Map<String, int>> getEmotionDistribution(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final emotions = await _emotionService.getEmotions();
      final distribution = <String, int>{};

      for (var emotion in emotions) {
        if (emotion.timestamp.isAfter(start) &&
            emotion.timestamp.isBefore(end)) {
          distribution[emotion.emotionType] =
              (distribution[emotion.emotionType] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      print('Analytics Service Error: $e');
      return {};
    }
  }

  // Get average intensity by emotion
  Future<Map<String, double>> getAverageIntensity(int userId) async {
    try {
      final emotions = await _emotionService.getEmotions();
      final intensitySum = <String, double>{};
      final counts = <String, int>{};

      for (var emotion in emotions) {
        intensitySum[emotion.emotionType] =
            (intensitySum[emotion.emotionType] ?? 0) + emotion.intensity;
        counts[emotion.emotionType] = (counts[emotion.emotionType] ?? 0) + 1;
      }

      final averages = <String, double>{};
      for (var emotion in intensitySum.keys) {
        averages[emotion] = intensitySum[emotion]! / counts[emotion]!;
      }

      return averages;
    } catch (e) {
      print('Analytics Service Error: $e');
      return {};
    }
  }

  // Calculate emotion trends for chart
  Future<List<EmotionTrend>> calculateTrends(
    int userId,
    int days,
  ) async {
    try {
      final emotions = await _emotionService.getEmotions();
      final trends = <EmotionTrend>[];
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      for (var i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);

        final dayEmotions = emotions.where((e) {
          final eDate = DateTime(
            e.timestamp.year,
            e.timestamp.month,
            e.timestamp.day,
          );
          return eDate.isAtSameMomentAs(dateOnly);
        }).toList();

        final intensities = <String, double>{};
        final emotionTypes = ['Vui vẻ', 'Buồn', 'Lo âu', 'Tức giận', 'Bình thường'];

        for (var emotionType in emotionTypes) {
          final emotionData =
              dayEmotions.where((e) => e.emotionType == emotionType).toList();

          if (emotionData.isNotEmpty) {
            final avgIntensity = emotionData
                    .map((e) => e.intensity.toDouble())
                    .reduce((a, b) => a + b) /
                emotionData.length;
            intensities[emotionType] = avgIntensity;
          }
        }

        trends.add(EmotionTrend(
          date: dateOnly,
          emotionIntensities: intensities,
        ));
      }

      return trends;
    } catch (e) {
      print('Analytics Service Error: $e');
      return [];
    }
  }

  // Get statistics
  Future<EmotionStats> getStats(int userId) async {
    try {
      final emotions = await _emotionService.getEmotions();

      if (emotions.isEmpty) {
        return EmotionStats(
          totalEmotions: 0,
          mostCommonEmotion: 'Chưa có dữ liệu',
          averageIntensity: 0,
          streakDays: 0,
          emotionCounts: {},
        );
      }

      // Count emotions
      final counts = <String, int>{};
      var totalIntensity = 0.0;

      for (var emotion in emotions) {
        counts[emotion.emotionType] = (counts[emotion.emotionType] ?? 0) + 1;
        totalIntensity += emotion.intensity;
      }

      // Find most common
      var mostCommon = counts.entries.first.key;
      var maxCount = counts.entries.first.value;

      for (var entry in counts.entries) {
        if (entry.value > maxCount) {
          mostCommon = entry.key;
          maxCount = entry.value;
        }
      }

      // Calculate streak
      final sortedEmotions = emotions.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      var streak = 0;
      var currentDate = DateTime.now();

      for (var i = 0; i < 30; i++) {
        final checkDate = currentDate.subtract(Duration(days: i));
        final hasEmotion = sortedEmotions.any((e) {
          final eDate = DateTime(
            e.timestamp.year,
            e.timestamp.month,
            e.timestamp.day,
          );
          final cDate = DateTime(
            checkDate.year,
            checkDate.month,
            checkDate.day,
          );
          return eDate.isAtSameMomentAs(cDate);
        });

        if (hasEmotion) {
          streak++;
        } else {
          break;
        }
      }

      return EmotionStats(
        totalEmotions: emotions.length,
        mostCommonEmotion: mostCommon,
        averageIntensity: totalIntensity / emotions.length,
        streakDays: streak,
        emotionCounts: counts,
      );
    } catch (e) {
      print('Analytics Service Error: $e');
      return EmotionStats(
        totalEmotions: 0,
        mostCommonEmotion: 'Lỗi',
        averageIntensity: 0,
        streakDays: 0,
        emotionCounts: {},
      );
    }
  }
}
