import 'package:flutter/material.dart';
import 'package:tam_an/models/reminder_settings.dart';
import 'package:tam_an/models/emotion.dart';
import 'package:tam_an/services/notification_service.dart';
import 'package:tam_an/services/api_service.dart';
import 'package:tam_an/services/settings_service.dart';

class ReminderProvider with ChangeNotifier {
  ReminderSettings _settings = ReminderSettings();
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService;
  late final SettingsService _settingsService;

  ReminderSettings get settings => _settings;
  bool get isEnabled => _settings.isEnabled;

  ReminderProvider(this._apiService) {
    _settingsService = SettingsService(_apiService);
  }

  /// Called to update the initial settings after fetching from server
  void setInitialSettings(Map<String, dynamic>? data) {
    if (data != null && data.isNotEmpty) {
      _settings = ReminderSettings.fromJson(data);
      _applySettings();
    }
    notifyListeners();
  }

  /// Save settings to SQL Server
  Future<void> _saveSettings() async {
    try {
      await _settingsService.updateSettings(
        reminderSettings: _settings.toJson(),
      );
      debugPrint('🔔 Saved reminder settings to server');
    } catch (e) {
      debugPrint('Error saving reminder settings to server: $e');
    }
  }

  /// Apply current settings to notification scheduling
  Future<void> _applySettings() async {
    if (_settings.isEnabled) {
      // Schedule main reminders
      await _notificationService.scheduleReminders(
        time: _settings.reminderTime,
        days: _settings.selectedDays,
        message: _settings.reminderMessage,
      );

      // Second reminders
      if (_settings.secondReminderEnabled) {
        await _notificationService.scheduleSecondReminders(
          time: _settings.secondReminderTime,
          days: _settings.selectedDays,
          message: 'Bạn đã ghi nhận cảm xúc hôm nay chưa? 📝',
        );
      } else {
        await _notificationService.cancelSecondReminders();
      }

      // Smart reminders
      if (_settings.isSmartReminderEnabled &&
          _settings.smartReminderDays.isNotEmpty) {
        await _notificationService.scheduleSmartReminders(
          stressDays: _settings.smartReminderDays,
          time: _settings.reminderTime,
        );
      } else {
        await _notificationService.cancelSmartReminders();
      }
    } else {
      await _notificationService.cancelAllReminders();
    }
  }

  /// Toggle reminders on/off
  Future<void> toggleReminder(bool enabled) async {
    _settings.isEnabled = enabled;

    if (enabled) {
      // Request permissions when enabling
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        _settings.isEnabled = false;
        notifyListeners();
        return;
      }
    }

    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Set reminder time
  Future<void> setReminderTime(TimeOfDay time) async {
    _settings.reminderTime = time;
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Toggle a specific day
  Future<void> toggleDay(int day) async {
    if (_settings.selectedDays.contains(day)) {
      if (_settings.selectedDays.length > 1) {
        _settings.selectedDays.remove(day);
      }
    } else {
      _settings.selectedDays.add(day);
      _settings.selectedDays.sort();
    }
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Select all days
  Future<void> selectAllDays() async {
    _settings.selectedDays = [1, 2, 3, 4, 5, 6, 7];
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Select weekdays only
  Future<void> selectWeekdays() async {
    _settings.selectedDays = [1, 2, 3, 4, 5];
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Toggle smart reminder
  Future<void> toggleSmartReminder(bool enabled) async {
    _settings.isSmartReminderEnabled = enabled;
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Update smart reminder days from emotion analysis
  Future<void> updateSmartPatterns(List<Emotion> emotions) async {
    final stressDays = _notificationService.analyzeStressPatterns(emotions);
    _settings.smartReminderDays = stressDays;
    await _saveSettings();
    if (_settings.isSmartReminderEnabled && _settings.isEnabled) {
      await _applySettings();
    }
    notifyListeners();
  }

  /// Set custom reminder message
  Future<void> setReminderMessage(String message) async {
    _settings.reminderMessage = message;
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Toggle second reminder
  Future<void> toggleSecondReminder(bool enabled) async {
    _settings.secondReminderEnabled = enabled;
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Set second reminder time
  Future<void> setSecondReminderTime(TimeOfDay time) async {
    _settings.secondReminderTime = time;
    await _saveSettings();
    await _applySettings();
    notifyListeners();
  }

  /// Send a test notification
  Future<void> sendTestNotification() async {
    await _notificationService.showTestNotification(
      message: _settings.reminderMessage,
    );
  }
}
