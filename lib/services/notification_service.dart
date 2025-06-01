import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications with permission request
  static Future<bool> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Request permissions first
    final permissionGranted = await _requestAllPermissions();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel with high importance for Android
    await _createNotificationChannel();

    return permissionGranted;
  }

  static Future<bool> _requestAllPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();

    // Request phone permission for ringtone access
    final phoneStatus = await Permission.phone.request();

    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Additional permissions for Android
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS permissions
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
    _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // For critical alerts
      );
    }

    return notificationStatus.isGranted;
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_reminders_high',
      'Medication Reminders',
      description: 'High priority notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
      showBadge: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'), // Use system alarm sound
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    // Handle different actions
    switch (response.actionId) {
      case 'mark_taken':
        _handleMarkAsTaken(response.payload);
        break;
      case 'snooze':
        _handleSnooze(response.payload);
        break;
      default:
      // Handle default tap
        break;
    }
  }

  static void _handleMarkAsTaken(String? payload) {
    if (payload != null) {
      print('Marking medication as taken: $payload');
      // You can implement database update logic here
      // or broadcast an event that the main app can listen to
    }
  }

  static void _handleSnooze(String? payload) {
    if (payload != null) {
      print('Snoozing medication: $payload');
      final parts = payload.split(':');
      if (parts.length == 2) {
        final medicationId = int.tryParse(parts[0]);
        final reminderIndex = int.tryParse(parts[1]);
        if (medicationId != null && reminderIndex != null) {
          final notificationId = _generateNotificationId(medicationId, reminderIndex);
          snoozeNotification(
              notificationId,
              'Medication Reminder (Snoozed)',
              'Time to take your medication'
          );
        }
      }
    }
  }

  // Schedule notifications for a medication with enhanced alert features
  static Future<void> scheduleMedicationReminders(Medication medication) async {
    if (medication.id == null) return;

    // Cancel existing notifications for this medication
    await cancelMedicationReminders(medication.id!);

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final timeString = medication.reminderTimes[i];
      final dose = i < medication.doses.length ? medication.doses[i] : '1 dose';

      // Parse time string (assuming format "HH:mm")
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) continue;

      // Create unique notification ID
      final notificationId = _generateNotificationId(medication.id!, i);

      // Schedule daily recurring notification with enhanced alerts
      await _scheduleRepeatingNotification(
        id: notificationId,
        title: '💊 Medication Time!',
        body: 'Take ${medication.name} (${medication.unit}) - $dose',
        hour: hour,
        minute: minute,
        payload: '${medication.id}:$i',
      );
    }
  }

  static Future<void> _scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    // Enhanced Android notification with full alert features
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription: 'High priority notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,

      // Sound settings - use system alarm sound (ringtone-like)
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,

      // Vibration settings
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]), // Custom vibration pattern

      // Visual settings
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,

      // Behavior settings
      autoCancel: false, // Don't auto-dismiss
      ongoing: false,
      showWhen: true,
      when: null,
      usesChronometer: false,
      onlyAlertOnce: false, // Alert every time
      showProgress: false,
      indeterminate: false,

      // Full screen intent for critical alerts
      fullScreenIntent: true,

      // Category for better handling
      category: AndroidNotificationCategory.alarm,

      // Visibility
      visibility: NotificationVisibility.public,

      // Actions
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_taken',
          '✅ Mark as Taken',
          showsUserInterface: true,
          allowGeneratedReplies: false,
          contextual: true,
        ),
        AndroidNotificationAction(
          'snooze',
          '⏰ Snooze 10 min',
          showsUserInterface: false,
          allowGeneratedReplies: false,
          contextual: true,
        ),
      ],

      // Style
      styleInformation: const BigTextStyleInformation(
        '',
        htmlFormatBigText: true,
        contentTitle: '💊 Medication Reminder',
        htmlFormatContentTitle: true,
        summaryText: 'DoziYangu App',
        htmlFormatSummaryText: true,
      ),
    );

    // Enhanced iOS notification with critical alert
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm.aiff', // System alarm sound
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,

      // Critical alert for iOS (bypasses Do Not Disturb)
      criticalAlert: true,

      // Category for actions
      categoryIdentifier: 'MEDICATION_REMINDER',

      // Thread identifier for grouping
      threadIdentifier: 'medication_reminders',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calculate next occurrence
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: payload,
    );
  }

  // Enhanced snooze with full alert
  static Future<void> snoozeNotification(int notificationId, String title, String body) async {
    AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription: 'High priority notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      playSound: true,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      criticalAlert: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    final tzSnoozeTime = tz.TZDateTime.from(snoozeTime, tz.local);

    await _notifications.zonedSchedule(
      notificationId + 1000, // Different ID for snoozed notification
      '⏰ $title',
      body,
      tzSnoozeTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Show immediate test notification
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription: 'Test notification',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      playSound: true,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      criticalAlert: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '💊 Test Medication Reminder',
      'This is how your medication reminders will sound and vibrate',
      notificationDetails,
    );
  }

  // Cancel all notifications for a specific medication
  static Future<void> cancelMedicationReminders(int medicationId) async {
    for (int i = 0; i < 10; i++) {
      final notificationId = _generateNotificationId(medicationId, i);
      await _notifications.cancel(notificationId);
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Generate unique notification ID
  static int _generateNotificationId(int medicationId, int reminderIndex) {
    return medicationId * 100 + reminderIndex;
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    return true; // Assume enabled for iOS
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Check all permissions status
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'notification': await Permission.notification.isGranted,
      'phone': await Permission.phone.isGranted,
      'exactAlarm': await Permission.scheduleExactAlarm.isGranted,
    };
  }
}