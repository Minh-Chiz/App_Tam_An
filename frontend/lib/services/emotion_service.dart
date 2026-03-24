import 'package:tam_an/models/emotion.dart';
import 'package:tam_an/models/dashboard_stats.dart';
import 'package:tam_an/models/daily_emotion.dart';
import 'package:tam_an/models/monthly_insights.dart';
import 'package:tam_an/models/full_analysis.dart';
import 'package:tam_an/models/streak_data.dart';
import 'package:tam_an/models/monthly_wrapped.dart';
import 'package:tam_an/services/api_service.dart';

class EmotionService {
  final ApiService _apiService;

  EmotionService(this._apiService);

  // Get streak data, points, and achievements
  Future<StreakData> getStreakData() async {
    try {
      final response = await _apiService.dio.get('/emotions/stats/streak');
      final data = _apiService.handleResponse(response);

      if (data['success'] == true && data['data'] != null) {
        return StreakData.fromJson(data['data']);
      }

      throw Exception(data['message'] ?? 'Failed to load streak data');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Create new emotion entry
  Future<Emotion> createEmotion({
    required String emotionType,
    int intensity = 5,
    String? location,
    String? activity,
    String? company,
    String? noteText,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/emotions',
        data: {
          'emotion_type': emotionType,
          'intensity': intensity,
          if (location != null) 'location': location,
          if (activity != null) 'activity': activity,
          if (company != null) 'company': company,
          if (noteText != null) 'note_text': noteText,
        },
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return Emotion.fromJson(data['data']);
      }
      
      throw Exception(data['message'] ?? 'Failed to create emotion');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get user's emotions
  Future<List<Emotion>> getEmotions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/emotions',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final emotionsData = data['data']['emotions'] as List;
        return emotionsData.map((e) => Emotion.fromJson(e)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get emotion by ID
  Future<Emotion> getEmotionById(int id) async {
    try {
      final response = await _apiService.dio.get('/emotions/$id');
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return Emotion.fromJson(data['data']['emotion']);
      }
      
      throw Exception(data['message'] ?? 'Emotion not found');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get emotion statistics
  Future<List<EmotionStats>> getStats({int days = 7}) async {
    try {
      final response = await _apiService.dio.get(
        '/emotions/stats/summary',
        queryParameters: {'days': days},
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final statsData = data['data']['stats'] as List;
        return statsData.map((e) => EmotionStats.fromJson(e)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get dashboard statistics
  Future<DashboardStats> getDashboardStats({int days = 30}) async {
    try {
      final response = await _apiService.dio.get(
        '/emotions/stats/dashboard',
        queryParameters: {'days': days},
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return DashboardStats.fromJson(data['data']);
      }
      
      throw Exception(data['message'] ?? 'Failed to load dashboard stats');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get emotions by specific date
  Future<List<DailyEmotion>> getEmotionsByDate(String date) async {
    try {
      final response = await _apiService.dio.get('/emotions/date/$date');

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final emotionsData = data['data']['emotions'] as List;
        return emotionsData.map((e) => DailyEmotion.fromJson(e)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get calendar dates with emotions
  Future<List<String>> getCalendarDates(int year, int month) async {
    try {
      final response = await _apiService.dio.get(
        '/emotions/calendar/$year/$month',
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final dates = data['data']['dates_with_emotions'] as List;
        return dates.cast<String>();
      }
      
      return [];
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get monthly insights
  Future<MonthlyInsights> getMonthlyInsights(int year, int month) async {
    try {
      final response = await _apiService.dio.get(
        '/emotions/insights/monthly',
        queryParameters: {
          'year': year.toString(),
          'month': month.toString(),
        },
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return MonthlyInsights.fromJson(data['data']);
      }
      
      throw Exception(data['message'] ?? 'Failed to load monthly insights');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get emotions by date range
  Future<List<Emotion>> getEmotionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/emotions/range/dates',
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final emotionsData = data['data']['emotions'] as List;
        return emotionsData.map((e) => Emotion.fromJson(e)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get full analysis (all-time)
  Future<FullAnalysis> getFullAnalysis() async {
    try {
      final response = await _apiService.dio.get(
        '/emotions/stats/full-analysis',
      );

      final data = _apiService.handleResponse(response);

      if (data['success'] == true && data['data'] != null) {
        return FullAnalysis.fromJson(data['data']);
      }

      throw Exception(data['message'] ?? 'Failed to load full analysis');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Get monthly wrapped story
  Future<MonthlyWrapped> getMonthlyWrapped(int year, int month) async {
    try {
      final response = await _apiService.dio.get(
        '/emotions/stats/monthly-wrapped',
        queryParameters: {
          'year': year.toString(),
          'month': month.toString(),
        },
      );

      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return MonthlyWrapped.fromJson(data['data']);
      }
      
      throw Exception(data['message'] ?? 'Failed to load monthly wrapped data');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }
}
