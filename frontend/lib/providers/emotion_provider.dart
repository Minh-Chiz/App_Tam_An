import 'package:flutter/material.dart';
import 'package:tam_an/models/emotion.dart';
import 'package:tam_an/models/dashboard_stats.dart';
import 'package:tam_an/models/full_analysis.dart';
import 'package:tam_an/models/streak_data.dart';
import 'package:tam_an/models/emotion_config.dart';
import 'package:tam_an/services/api_service.dart';
import 'package:tam_an/services/emotion_service.dart';
import 'package:tam_an/services/settings_service.dart';

class EmotionProvider with ChangeNotifier {
  final ApiService _apiService;
  late final EmotionService _emotionService;
  late final SettingsService _settingsService;

  List<Emotion> _emotions = [];
  List<EmotionStats> _stats = [];
  DashboardStats? _dashboardStats;
  FullAnalysis? _fullAnalysis;
  StreakData? _streakData;
  List<String> _customEmotions = [];
  bool _isLoading = false;
  String? _error;

  EmotionProvider(this._apiService) {
    _emotionService = EmotionService(_apiService);
    _settingsService = SettingsService(_apiService);
  }

  List<Emotion> get emotions => _emotions;
  List<EmotionStats> get stats => _stats;
  DashboardStats? get dashboardStats => _dashboardStats;
  FullAnalysis? get fullAnalysis => _fullAnalysis;
  StreakData? get streakData => _streakData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get allAvailableEmotions {
    final defaultEmotions = EmotionConfig.defaultEmotions;
    return [...defaultEmotions, ..._customEmotions];
  }

  // Called to update the initial custom emotions after fetching from server
  void setInitialCustomEmotions(List<String> emotions) {
    _customEmotions = emotions;
    notifyListeners();
  }

  // Add a new custom emotion
  Future<void> addCustomEmotion(String emotionName) async {
    if (emotionName.isEmpty) return;
    if (allAvailableEmotions.contains(emotionName)) return;

    try {
      _customEmotions.add(emotionName);
      
      // Save to SQL Server
      await _settingsService.updateSettings(
        customEmotions: _customEmotions,
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving custom emotion to server: $e');
    }
  }

  // Create emotion entry
  Future<bool> createEmotion({
    required String emotionType,
    int intensity = 5,
    String? location,
    String? activity,
    String? company,
    String? noteText,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final emotion = await _emotionService.createEmotion(
        emotionType: emotionType,
        intensity: intensity,
        location: location,
        activity: activity,
        company: company,
        noteText: noteText,
      );

      _emotions.insert(0, emotion);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load emotions
  Future<void> loadEmotions({int limit = 50, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _emotions = await _emotionService.getEmotions(
        limit: limit,
        offset: offset,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> loadStats({int days = 7}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _emotionService.getStats(days: days);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load dashboard statistics
  Future<void> loadDashboardStats({int days = 30}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardStats = await _emotionService.getDashboardStats(days: days);
      _isLoading = false;
      notifyListeners();
      // Auto-load streak data
      loadStreakData();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load streak data
  Future<void> loadStreakData() async {
    try {
      _streakData = await _emotionService.getStreakData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading streak data: $e');
    }
  }

  // Load emotions by date range
  Future<void> loadEmotionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _emotions = await _emotionService.getEmotionsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load full analysis (all-time)
  Future<void> loadFullAnalysis() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _fullAnalysis = await _emotionService.getFullAnalysis();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear data
  void clear() {
    _emotions = [];
    _stats = [];
    _dashboardStats = null;
    _fullAnalysis = null;
    _streakData = null;
    notifyListeners();
  }
}
