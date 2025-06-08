import 'dart:typed_data';
import 'dart:ui';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isAlarmPlaying = false;

  // Alarm sounds from the Alarms class
  static const List<String> _alarmSounds = [
    "assets/audios/retro-audio-logo-94648.mp3",
    "assets/audios/art-of-samples-buzz-120-bpm-audio-logo-245396.mp3",
  ];

  // Initialize notifications
  static Future<bool> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize the plugin first
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: true, // For critical alerts
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel BEFORE requesting permissions
    await _createNotificationChannel();

    // Request permissions AFTER initialization
    final permissionGranted = await _requestAllPermissions();

    return permissionGranted;
  }

  static Future<bool> _requestAllPermissions() async {
    bool allGranted = true;

    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Additional permissions for Android
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Request basic notification permission
      final notificationPermission =
          await androidImplementation.requestNotificationsPermission();
      if (notificationPermission != true) {
        allGranted = false;
      }

      // Request exact alarm permission (Android 12+)
      final exactAlarmPermission =
          await androidImplementation.requestExactAlarmsPermission();
      if (exactAlarmPermission != true) {
        allGranted = false;
      }
    }

    // For iOS, request permissions
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosImplementation != null) {
      final iosPermission = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // For critical alerts that bypass Do Not Disturb
      );
      if (iosPermission != true) {
        allGranted = false;
      }
    }

    // Additional permission requests using permission_handler
    try {
      // Request notification permission (fallback)
      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        allGranted = false;
      }

      // Request schedule exact alarm permission for Android 12+
      if (await Permission.scheduleExactAlarm.isDenied) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        if (!exactAlarmStatus.isGranted) {
          allGranted = false;
        }
      }
    } catch (e) {
      developer.log('Permission request error: $e');
    }

    return allGranted;
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_reminders_high',
      'Medication Reminders',
      description: 'High priority notifications for medication reminders',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
      showBadge: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        'alarm',
      ), // Use system alarm sound
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}');

    // Stop any playing alarm when notification is tapped
    _stopAlarm();

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
      developer.log('Marking medication as taken: $payload');
      _stopAlarm();
      // Cancel the notification for this medication time
      final parts = payload.split(':');
      if (parts.length == 2) {
        final medicationId = int.tryParse(parts[0]);
        final reminderIndex = int.tryParse(parts[1]);
        if (medicationId != null && reminderIndex != null) {
          final notificationId = _generateNotificationId(
            medicationId,
            reminderIndex,
          );
          _notifications.cancel(notificationId);
        }
      }
    }
  }

  static void _handleSnooze(String? payload) {
    if (payload != null) {
      developer.log('Snoozing medication: $payload');
      _stopAlarm();
      final parts = payload.split(':');
      if (parts.length == 2) {
        final medicationId = int.tryParse(parts[0]);
        final reminderIndex = int.tryParse(parts[1]);
        if (medicationId != null && reminderIndex != null) {
          final notificationId = _generateNotificationId(
            medicationId,
            reminderIndex,
          );
          snoozeNotification(
            notificationId,
            'Medication Reminder (Snoozed)',
            'Time to take your medication',
            medicationId,
            reminderIndex,
          );
        }
      }
    }
  }

  // Play alarm sound when notification is received
  static Future<void> playAlarmOnNotification() async {
    await _playAlarmSound();
  }

  // Play alarm sound continuously
  static Future<void> _playAlarmSound() async {
    if (_isAlarmPlaying) return;

    _isAlarmPlaying = true;

    // Select random alarm sound
    final random = Random();
    final selectedAlarm = _alarmSounds[random.nextInt(_alarmSounds.length)];

    try {
      // Set audio player mode for alarm
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0); // Maximum volume

      // Play the alarm sound in loop
      await _audioPlayer.play(AssetSource(selectedAlarm));

      developer.log('Playing alarm: $selectedAlarm');

      // Stop alarm after 1 minute if not stopped manually
      Future.delayed(const Duration(minutes: 1), () {
        if (_isAlarmPlaying) {
          _stopAlarm();
        }
      });
    } catch (e) {
      developer.log('Error playing alarm: $e');
      _isAlarmPlaying = false;
    }
  }

  // Stop alarm sound
  static Future<void> _stopAlarm() async {
    if (!_isAlarmPlaying) return;

    try {
      await _audioPlayer.stop();
      _isAlarmPlaying = false;
      developer.log('Alarm stopped');
    } catch (e) {
      developer.log('Error stopping alarm: $e');
    }
  }

  // Schedule notifications for a medication
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

      // Schedule daily recurring notification
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
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription:
          'High priority notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,

      // Sound settings - use system alarm sound (ringtone-like)
      sound: const RawResourceAndroidNotificationSound('alarm'),
      playSound: true,

      // Vibration settings
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),

      // Visual settings
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
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
      visibility: NotificationVisibility.public,

      // Actions
      actions: const <AndroidNotificationAction>[
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
        'Tap "Mark as Taken" when you\'ve taken your medication, or "Snooze" to be reminded again in 10 minutes.',
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

      // Category for actions
      categoryIdentifier: 'MEDICATION_REMINDER',
      threadIdentifier: 'medication_reminders',
    );

    NotificationDetails notificationDetails = NotificationDetails(
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

  // Snooze notification for 10 minutes
  static Future<void> snoozeNotification(
    int notificationId,
    String title,
    String body,
    int medicationId,
    int reminderIndex,
  ) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription:
          'High priority notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_taken',
          '✅ Mark as Taken',
          showsUserInterface: true,
          allowGeneratedReplies: false,
          contextual: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    final tzSnoozeTime = tz.TZDateTime.from(snoozeTime, tz.local);

    // Schedule snoozed notification with different ID
    await _notifications.zonedSchedule(
      notificationId + 1000, // Different ID for snoozed notification
      '⏰ $title',
      body,
      tzSnoozeTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$medicationId:$reminderIndex',
    );
  }

  // Show immediate test notification
  static Future<void> showTestNotification() async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription: 'Test notification',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      fullScreenIntent: true,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_taken',
          '✅ Mark as Taken',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'snooze',
          '⏰ Snooze 10 min',
          showsUserInterface: false,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '💊 Test Medication Reminder',
      'This is how your medication reminders will appear. Tap the actions below to test them.',
      notificationDetails,
    );

    // Play test alarm sound
    _playAlarmSound();
  }

  // Cancel all notifications for a specific medication
  static Future<void> cancelMedicationReminders(int medicationId) async {
    for (int i = 0; i < 10; i++) {
      final notificationId = _generateNotificationId(medicationId, i);
      await _notifications.cancel(notificationId);
      // Also cancel potential snoozed notifications
      await _notifications.cancel(notificationId + 1000);
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _stopAlarm();
  }

  // Generate unique notification ID
  static int _generateNotificationId(int medicationId, int reminderIndex) {
    return medicationId * 100 + reminderIndex;
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    return true; // Assume enabled for iOS
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Check all permissions status
  static Future<Map<String, bool>> checkAllPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.areNotificationsEnabled();
    }

    return {
      'notification': await Permission.notification.isGranted,
      'exactAlarm': await Permission.scheduleExactAlarm.isGranted,
    };
  }

  // Stop any currently playing alarm (public method)
  static Future<void> stopCurrentAlarm() async {
    await _stopAlarm();
  }

  // Check if alarm is currently playing
  static bool get isAlarmPlaying => _isAlarmPlaying;

  // Manual method to trigger alarm sound (can be called from notification callback)
  static Future<void> triggerAlarmSound() async {
    await _playAlarmSound();
  }
}
