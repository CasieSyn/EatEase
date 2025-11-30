import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _mealReminderTimeKey = 'meal_reminder_time';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to meal plans screen
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> scheduleMealReminder({
    required int id,
    required String recipeName,
    required String mealType,
    required DateTime scheduledTime,
    int reminderMinutesBefore = 30,
  }) async {
    if (kIsWeb) return;

    final reminderTime = scheduledTime.subtract(Duration(minutes: reminderMinutesBefore));

    // Don't schedule if the reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'meal_reminders',
      'Meal Reminders',
      channelDescription: 'Notifications for upcoming meals',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE85D04),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final mealTypeFormatted = mealType[0].toUpperCase() + mealType.substring(1);

    await _notifications.zonedSchedule(
      id,
      '$mealTypeFormatted Time!',
      'Time to prepare $recipeName',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: 'meal_plan_$id',
    );
  }

  Future<void> cancelMealReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Settings management
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<int> getMealReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mealReminderTimeKey) ?? 30;
  }

  Future<void> setMealReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mealReminderTimeKey, minutes);
  }

  // Schedule notifications for meal plans
  Future<void> scheduleMealPlanNotifications(List<Map<String, dynamic>> mealPlans) async {
    if (kIsWeb) return;

    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final reminderMinutes = await getMealReminderMinutes();

    // Cancel existing meal reminders
    await cancelAllNotifications();

    for (final plan in mealPlans) {
      final plannedDate = DateTime.tryParse(plan['planned_date'] ?? '');
      if (plannedDate == null) continue;

      final mealType = plan['meal_type'] as String? ?? 'lunch';
      final recipeName = plan['recipe_name'] as String? ?? 'your meal';
      final id = plan['id'] as int? ?? DateTime.now().millisecondsSinceEpoch;

      // Set meal times based on meal type
      DateTime scheduledTime;
      switch (mealType.toLowerCase()) {
        case 'breakfast':
          scheduledTime = DateTime(plannedDate.year, plannedDate.month, plannedDate.day, 8, 0);
          break;
        case 'lunch':
          scheduledTime = DateTime(plannedDate.year, plannedDate.month, plannedDate.day, 12, 0);
          break;
        case 'dinner':
          scheduledTime = DateTime(plannedDate.year, plannedDate.month, plannedDate.day, 18, 0);
          break;
        case 'snack':
          scheduledTime = DateTime(plannedDate.year, plannedDate.month, plannedDate.day, 15, 0);
          break;
        default:
          scheduledTime = DateTime(plannedDate.year, plannedDate.month, plannedDate.day, 12, 0);
      }

      await scheduleMealReminder(
        id: id,
        recipeName: recipeName,
        mealType: mealType,
        scheduledTime: scheduledTime,
        reminderMinutesBefore: reminderMinutes,
      );
    }
  }
}
