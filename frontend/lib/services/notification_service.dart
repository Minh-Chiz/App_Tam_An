import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tam_an/models/emotion.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channel
  static const String _channelId = 'tam_an_reminders';
  static const String _channelName = 'Nhắc nhở cảm xúc';
  static const String _channelDescription =
      'Nhắc nhở ghi nhận cảm xúc hàng ngày';

  // Notification IDs
  static const int _baseReminderId = 100; // IDs 100-106 for 7 days
  static const int _baseSecondReminderId = 200; // IDs 200-206
  static const int _baseSmartReminderId = 300; // IDs 300-306
  static const int _testNotificationId = 999;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('🔔 NotificationService initialized (timezone: $timeZoneName)');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // The app will open automatically; further navigation can be added later
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      debugPrint('🔔 Notification permission: $granted');
      return granted ?? false;
    }

    return true;
  }

  /// Schedule daily reminders for specific weekdays
  Future<void> scheduleReminders({
    required TimeOfDay time,
    required List<int> days,
    required String message,
    int baseId = _baseReminderId,
  }) async {
    // Cancel existing reminders in this range first
    await cancelReminders(baseId: baseId);

    for (final day in days) {
      final id = baseId + (day - 1);
      final scheduledDate = _nextInstanceOfWeekdayAndTime(day, time);

      await _plugin.zonedSchedule(
        id,
        'Tâm An 💜',
        message,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: const BigTextStyleInformation(''),
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'emotion_checkin',
      );

      debugPrint(
          '🔔 Scheduled reminder #$id: day=$day time=${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    }
  }

  /// Cancel reminders in a base ID range (7 days)
  Future<void> cancelReminders({int baseId = _baseReminderId}) async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(baseId + i);
    }
    debugPrint('🔔 Cancelled reminders for baseId=$baseId');
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
    debugPrint('🔔 All reminders cancelled');
  }

  /// Show an instant test notification
  Future<void> showTestNotification({String? message}) async {
    await _plugin.show(
      _testNotificationId,
      'Tâm An 💜',
      message ?? 'Hãy dành chút thời gian ghi nhận cảm xúc hôm nay nhé!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      payload: 'test',
    );
    debugPrint('🔔 Test notification sent');
  }

  /// Schedule second round of reminders (e.g., midday)
  Future<void> scheduleSecondReminders({
    required TimeOfDay time,
    required List<int> days,
    required String message,
  }) async {
    await scheduleReminders(
      time: time,
      days: days,
      message: message,
      baseId: _baseSecondReminderId,
    );
  }

  /// Cancel second reminders
  Future<void> cancelSecondReminders() async {
    await cancelReminders(baseId: _baseSecondReminderId);
  }

  /// Schedule smart reminders on stress-prone days
  Future<void> scheduleSmartReminders({
    required List<int> stressDays,
    required TimeOfDay time,
  }) async {
    const smartMessages = [
      'Hôm nay có thể sẽ căng thẳng — hãy chăm sóc bản thân nhé! 🌿',
      'Nhớ hít thở sâu và ghi nhận cảm xúc khi cần nhé! 🧘',
      'Bạn xứng đáng được nghỉ ngơi — hãy check-in cảm xúc nhé! 💪',
      'Hãy nhẹ nhàng với bản thân hôm nay nhé! ☀️',
    ];

    await cancelReminders(baseId: _baseSmartReminderId);

    for (final day in stressDays) {
      final id = _baseSmartReminderId + (day - 1);
      // Smart reminder: 1 hour before the main reminder
      final smartTime = TimeOfDay(
        hour: (time.hour - 1).clamp(0, 23),
        minute: time.minute,
      );
      final scheduledDate = _nextInstanceOfWeekdayAndTime(day, smartTime);
      final message = smartMessages[(day - 1) % smartMessages.length];

      await _plugin.zonedSchedule(
        id,
        '🧠 Nhắc nhở thông minh',
        message,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: const BigTextStyleInformation(''),
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'smart_reminder',
      );

      debugPrint('🧠 Scheduled smart reminder #$id for day=$day');
    }
  }

  /// Cancel smart reminders
  Future<void> cancelSmartReminders() async {
    await cancelReminders(baseId: _baseSmartReminderId);
  }

  /// Analyze a list of emotions to find stress-prone weekdays.
  /// Returns a list of weekday integers (1=Mon, 7=Sun) that are often stressful.
  List<int> analyzeStressPatterns(List<Emotion> emotions) {
    if (emotions.isEmpty) return [];

    // Count negative emotions per weekday
    final Map<int, int> negativeCount = {};
    final Map<int, int> totalCount = {};
    const negativeTypes = {'Buồn', 'Căng thẳng', 'Lo âu', 'Giận dữ'};

    for (final emotion in emotions) {
      final weekday = emotion.timestamp.weekday; // 1=Mon, 7=Sun
      totalCount[weekday] = (totalCount[weekday] ?? 0) + 1;
      if (negativeTypes.contains(emotion.emotionType)) {
        negativeCount[weekday] = (negativeCount[weekday] ?? 0) + 1;
      }
    }

    // Find days where negative emotion ratio > 40%
    final stressDays = <int>[];
    for (final entry in totalCount.entries) {
      final day = entry.key;
      final total = entry.value;
      final negative = negativeCount[day] ?? 0;
      if (total >= 2 && negative / total > 0.4) {
        stressDays.add(day);
      }
    }

    stressDays.sort();
    debugPrint('🧠 Stress pattern analysis: stressDays=$stressDays');
    return stressDays;
  }

  /// Calculate next occurrence of a specific weekday + time
  tz.TZDateTime _nextInstanceOfWeekdayAndTime(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Move to correct weekday
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // If this day+time has already passed this week, go to next week
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}
