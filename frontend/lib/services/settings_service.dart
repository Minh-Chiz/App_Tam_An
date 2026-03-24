import 'package:tam_an/services/api_service.dart';

class SettingsService {
  final ApiService _apiService;

  SettingsService(this._apiService);

  // Get user settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiService.dio.get('/settings');
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        return data['data'];
      }
      
      throw Exception(data['message'] ?? 'Failed to get settings');
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }

  // Update user settings
  Future<bool> updateSettings({
    String? themeMode,
    List<String>? customEmotions,
    Map<String, dynamic>? reminderSettings,
  }) async {
    try {
      final response = await _apiService.dio.put(
        '/settings',
        data: {
          if (themeMode != null) 'theme_mode': themeMode,
          if (customEmotions != null) 'custom_emotions': customEmotions,
          if (reminderSettings != null) 'reminder_settings': reminderSettings,
        },
      );

      final data = _apiService.handleResponse(response);
      return data['success'] == true;
    } catch (e) {
      throw Exception(_apiService.handleError(e));
    }
  }
}
