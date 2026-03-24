import 'package:flutter/material.dart';
import 'package:tam_an/services/api_service.dart';
import 'package:tam_an/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  late final SettingsService _settingsService;
  final ApiService _apiService;

  ThemeProvider(this._apiService) {
    _settingsService = SettingsService(_apiService);
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Called to update the initial theme after fetching from server
  void setInitialTheme(String? mode) {
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    
    // Save to SQL Server via SettingsService
    try {
      await _settingsService.updateSettings(
        themeMode: isDarkMode ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Error saving theme to server: $e');
    }
    
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    
    try {
      await _settingsService.updateSettings(
        themeMode: mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Error saving theme to server: $e');
    }
    
    notifyListeners();
  }
}
