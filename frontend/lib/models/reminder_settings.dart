import 'dart:convert';
import 'package:flutter/material.dart';

class ReminderSettings {
  bool isEnabled;
  TimeOfDay reminderTime;
  List<int> selectedDays; // 1=Monday, 7=Sunday
  bool isSmartReminderEnabled;
  List<int> smartReminderDays; // Auto-detected stress days
  String reminderMessage;
  bool secondReminderEnabled;
  TimeOfDay secondReminderTime;

  ReminderSettings({
    this.isEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 20, minute: 0),
    List<int>? selectedDays,
    this.isSmartReminderEnabled = false,
    List<int>? smartReminderDays,
    this.reminderMessage = 'Hãy dành chút thời gian ghi nhận cảm xúc hôm nay nhé! 💜',
    this.secondReminderEnabled = false,
    this.secondReminderTime = const TimeOfDay(hour: 12, minute: 0),
  })  : selectedDays = selectedDays ?? [1, 2, 3, 4, 5, 6, 7],
        smartReminderDays = smartReminderDays ?? [];

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'reminderHour': reminderTime.hour,
      'reminderMinute': reminderTime.minute,
      'selectedDays': selectedDays,
      'isSmartReminderEnabled': isSmartReminderEnabled,
      'smartReminderDays': smartReminderDays,
      'reminderMessage': reminderMessage,
      'secondReminderEnabled': secondReminderEnabled,
      'secondReminderHour': secondReminderTime.hour,
      'secondReminderMinute': secondReminderTime.minute,
    };
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      isEnabled: json['isEnabled'] ?? false,
      reminderTime: TimeOfDay(
        hour: json['reminderHour'] ?? 20,
        minute: json['reminderMinute'] ?? 0,
      ),
      selectedDays: (json['selectedDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
      isSmartReminderEnabled: json['isSmartReminderEnabled'] ?? false,
      smartReminderDays: (json['smartReminderDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      reminderMessage: json['reminderMessage'] ??
          'Hãy dành chút thời gian ghi nhận cảm xúc hôm nay nhé! 💜',
      secondReminderEnabled: json['secondReminderEnabled'] ?? false,
      secondReminderTime: TimeOfDay(
        hour: json['secondReminderHour'] ?? 12,
        minute: json['secondReminderMinute'] ?? 0,
      ),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ReminderSettings.fromJsonString(String jsonString) {
    return ReminderSettings.fromJson(jsonDecode(jsonString));
  }

  ReminderSettings copyWith({
    bool? isEnabled,
    TimeOfDay? reminderTime,
    List<int>? selectedDays,
    bool? isSmartReminderEnabled,
    List<int>? smartReminderDays,
    String? reminderMessage,
    bool? secondReminderEnabled,
    TimeOfDay? secondReminderTime,
  }) {
    return ReminderSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      selectedDays: selectedDays ?? List.from(this.selectedDays),
      isSmartReminderEnabled:
          isSmartReminderEnabled ?? this.isSmartReminderEnabled,
      smartReminderDays: smartReminderDays ?? List.from(this.smartReminderDays),
      reminderMessage: reminderMessage ?? this.reminderMessage,
      secondReminderEnabled:
          secondReminderEnabled ?? this.secondReminderEnabled,
      secondReminderTime: secondReminderTime ?? this.secondReminderTime,
    );
  }

  /// Get Vietnamese day name
  static String getDayName(int day) {
    switch (day) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  /// Get full Vietnamese day name
  static String getDayFullName(int day) {
    switch (day) {
      case 1: return 'Thứ 2';
      case 2: return 'Thứ 3';
      case 3: return 'Thứ 4';
      case 4: return 'Thứ 5';
      case 5: return 'Thứ 6';
      case 6: return 'Thứ 7';
      case 7: return 'Chủ nhật';
      default: return '';
    }
  }
}
