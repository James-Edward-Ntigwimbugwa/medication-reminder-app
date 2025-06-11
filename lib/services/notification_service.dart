// notification_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../database/medication_db.dart';
import '../models/medication.dart';

@pragma('vm:entry-point')
void alarmCallback() {
  print('Alarm callback triggered!');
  NotificationService.handleAlarmTrigger();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  static bool _isAlarmPlaying = false;
  static int? _currentAlarmId;
  static Function(String?)? _onAlarmTriggered;

  static Future<bool> initialize() async {
    try {
      tz.initializeTimeZones();
      final alarmInitialized = await AndroidAlarmManager.initialize();
      print('AndroidAlarmManager initialized: $alarmInitialized');

      final permissionGranted = await _requestAllPermissions();
      print('Permissions granted: $permissionGranted');

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

      final notificationInitialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      print('Notifications initialized: $notificationInitialized');

      await _createNotificationChannel();
      return permissionGranted && alarmInitialized;
    } catch (e) {
      print('Error initializing NotificationService: $e');
      return false;
    }
  }

  static Future<bool> _requestAllPermissions() async {
    try {
      final notificationStatus = await Permission.notification.request();
      print('Notification permission: ${notificationStatus.isGranted}');

      final phoneStatus = await Permission.phone.request();
      print('Phone permission: ${phoneStatus.isGranted}');

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      print('Exact alarm permission: ${exactAlarmStatus.isGranted}');

      final systemAlertWindowStatus = await Permission.systemAlertWindow.request();
      print('System alert window permission: ${systemAlertWindowStatus.isGranted}');

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final exactAlarmPermission = await androidImplementation.requestExactAlarmsPermission();
        final notificationPermission = await androidImplementation.requestNotificationsPermission();
        print('Android exact alarm permission: $exactAlarmPermission');
        print('Android notification permission: $notificationPermission');
      }

      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
      }

      return notificationStatus.isGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
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
      playSound: false,
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
    _handleAlarmFromNotification(response.payload);
    switch (response.actionId) {
      case 'mark_taken':
        _handleMarkAsTaken(response.payload);
        break;
      case 'snooze':
        _handleSnooze(response.payload);
        break;
      default:
        break;
    }
  }

  static void _handleAlarmFromNotification(String? payload) {
    playAlarmSound();
    if (_onAlarmTriggered != null) {
      _onAlarmTriggered!(payload);
    }
  }

  static void handleAlarmTrigger() {
    print('Alarm triggered from AndroidAlarmManager!');
    playAlarmSound();
    if (_onAlarmTriggered != null) {
      _onAlarmTriggered!(null);
    }
  }

  static void setAlarmTriggerCallback(Function(String?)? callback) {
    _onAlarmTriggered = callback;
  }

  // Fixed: Removed static access error
  static void _handleMarkAsTaken(String? payload) {
    if (payload != null) {
      print('Marking medication as taken: $payload');
      _stopAlarm();
      final parts = payload.split(':');
      if (parts.length == 2) {
        final medicationId = int.tryParse(parts[0]);
        final reminderIndex = int.tryParse(parts[1]);
        if (medicationId != null && reminderIndex != null) {
          final alarmId = _generateAlarmId(medicationId, reminderIndex);
          AndroidAlarmManager.cancel(alarmId);
        }
      }
    }
  }

  // Fixed: Removed static access error
  static void _handleSnooze(String? payload) {
    if (payload != null) {
      print('Snoozing medication: $payload');
      _stopAlarm();
      final parts = payload.split(':');
      if (parts.length == 2) {
        final medicationId = int.tryParse(parts[0]);
        final reminderIndex = int.tryParse(parts[1]);
        if (medicationId != null && reminderIndex != null) {
          final notificationId = generateNotificationId(medicationId, reminderIndex);
          snoozeNotification(
              notificationId,
              'Medication Reminder (Snoozed)',
              'Time to take your medication',
              medicationId,
              reminderIndex);
        }
      }
    }
  }

  // Fixed: Using instance method instead of static access
  static Future<void> playAlarmSound() async {
    debugPrint('playAlarmSound called');
    if (_isAlarmPlaying) {
      print('Alarm already playing, skipping...');
      return;
    }

    print('Starting alarm sound...');
    _isAlarmPlaying = true;

    try {
      await _ringtonePlayer.playAlarm(asAlarm: true);
      print('Alarm playing');

      Future.delayed(const Duration(minutes: 2), () {
        if (_isAlarmPlaying) {
          print('Auto-stopping alarm after 2 minutes');
          _stopAlarm();
        }
      });
    } catch (e) {
      print('Error playing alarm: $e');
      _isAlarmPlaying = false;
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
    try {
      AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'medication_reminders_high',
        'Medication Reminders',
        channelDescription: 'High priority notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        autoCancel: false,
        ongoing: true,
        showWhen: true,
        onlyAlertOnce: false,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'mark_taken',
            'Mark as Taken',
            icon: const DrawableResourceAndroidBitmap('ic_check'),
            showsUserInterface: true,
            allowGeneratedReplies: false,
            contextual: true,
          ),
          AndroidNotificationAction(
            'snooze',
            'Snooze 10 min',
            icon: const DrawableResourceAndroidBitmap('ic_snooze'),
            showsUserInterface: false,
            allowGeneratedReplies: false,
            contextual: true,
          ),
        ],
        styleInformation: const BigTextStyleInformation(
          'Tap "Mark as Taken" when you\'ve taken your medication, or "Snooze" to be reminded again in 10 minutes.',
          htmlFormatBigText: true,
          contentTitle: '💊 Medication Reminder',
          htmlFormatContentTitle: true,
          summaryText: 'DoziYangu App',
          htmlFormatSummaryText: true,
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        badgeNumber: 1,
        categoryIdentifier: 'MEDICATION_REMINDER',
        threadIdentifier: 'medication_reminders',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Add delay for notification (30 seconds after alarm)
      scheduledDate = scheduledDate.add(const Duration(seconds: 30));

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      print('Scheduling notification for: ${tzScheduledDate.toString()}');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Fixed: Using instance method instead of static access
  static Future<void> _stopAlarm() async {
    if (!_isAlarmPlaying) return;

    try {
      await _ringtonePlayer.stop();
      _isAlarmPlaying = false;
      print('Alarm stopped successfully');
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  static Future<void> scheduleMedicationReminders(Medication medication) async {
    if (medication.id == null) {
      print('Cannot schedule reminders: medication ID is null');
      return;
    }

    print('Scheduling reminders for medication: ${medication.name}');
    await cancelMedicationReminders(medication.id!);

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final timeString = medication.reminderTimes[i];
      final dose = i < medication.doses.length ? medication.doses[i] : '1 dose';

      final timeParts = timeString.split(':');
      if (timeParts.length != 2) {
        print('Invalid time format: $timeString');
        continue;
      }

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) {
        print('Cannot parse time: $timeString');
        continue;
      }

      final notificationId = generateNotificationId(medication.id!, i);
      final alarmId = _generateAlarmId(medication.id!, i);

      print('Scheduling notification $notificationId and alarm $alarmId for ${hour}:${minute}');

      await _scheduleRepeatingNotification(
        id: notificationId,
        title: '💊 Medication Time!',
        body: 'Take ${medication.name} (${medication.unit}) - $dose',
        hour: hour,
        minute: minute,
        payload: '${medication.id}:$i',
      );

      await _scheduleRepeatingAlarm(alarmId, hour, minute);
    }
  }

  static Future<void> _scheduleRepeatingAlarm(int alarmId, int hour, int minute) async {
    try {
      final now = DateTime.now();
      var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      print('Scheduling alarm $alarmId for ${alarmTime.toString()}');

      final success = await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        alarmCallback,
        startAt: alarmTime,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
      );

      print('Alarm scheduled successfully: $success');
    } catch (e) {
      print('Error scheduling alarm: $e');
    }
  }

  static Future<void> snoozeNotification(
      int notificationId, String title, String body, int medicationId, int reminderIndex) async {
    AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription: 'High priority notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    final tzSnoozeTime = tz.TZDateTime.from(snoozeTime, tz.local);

    await _notifications.zonedSchedule(
      notificationId + 1000,
      '⏰ $title',
      body,
      tzSnoozeTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    final snoozeAlarmId = _generateAlarmId(medicationId, reminderIndex) + 1000;
    await AndroidAlarmManager.oneShot(
      const Duration(minutes: 10),
      snoozeAlarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  static Future<void> cancelSpecificNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      print('Notification $notificationId cancelled successfully');
    } catch (e) {
      print('Error cancelling notification $notificationId: $e');
    }
  }

  static Future<void> showTestNotification() async {
    AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'medication_reminders_high',
      'Medication Reminders',
      channelDescription: 'Test notification',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '💊 Test Medication Reminder',
      'This is how your medication reminders will appear. The alarm will play for 2 minutes.',
      notificationDetails,
    );

    playAlarmSound();
  }

  static Future<void> cancelMedicationReminders(int medicationId) async {
    final medications = await MedicationDB.instance.readAllMedications();
    final medication = medications.firstWhere((m) => m.id == medicationId, orElse: () => Medication(name: '', unit: '', frequency: '', reminderTimes: [], doses: [], takenStatus: []));

    if (medication.name.isEmpty) {
      print('Medication with ID $medicationId not found, cannot cancel reminders.');
      return;
    }

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final notificationId = generateNotificationId(medicationId, i);
      final alarmId = _generateAlarmId(medicationId, i);

      await _notifications.cancel(notificationId);
      try {
        await AndroidAlarmManager.cancel(alarmId);
      } catch (e) {
        print('Error canceling alarm $alarmId: $e');
      }
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _stopAlarm();
  }

  static int generateNotificationId(int medicationId, int reminderIndex) {
    return medicationId * 100 + reminderIndex;
  }

  static int _generateAlarmId(int medicationId, int reminderIndex) {
    return medicationId * 200 + reminderIndex;
  }

  static Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'notification': await Permission.notification.isGranted,
      'phone': await Permission.phone.isGranted,
      'exactAlarm': await Permission.scheduleExactAlarm.isGranted,
      'systemAlertWindow': await Permission.systemAlertWindow.isGranted,
    };
  }

  static Future<void> stopCurrentAlarm() async {
    await _stopAlarm();
  }

  static bool get isAlarmPlaying => _isAlarmPlaying;

  static Future<void> markMedicationAsTaken(int medicationId, int reminderIndex) async {
    try {
      await _stopAlarm();
      final alarmId = _generateAlarmId(medicationId, reminderIndex);
      await AndroidAlarmManager.cancel(alarmId);

      final medications = await MedicationDB.instance.readAllMedications();
      final medicationIndex = medications.indexWhere((m) => m.id == medicationId);

      if (medicationIndex != -1) {
        final medication = medications[medicationIndex];
        final updatedStatus = List<bool>.from(medication.takenStatus);

        if (reminderIndex < updatedStatus.length) {
          updatedStatus[reminderIndex] = true;

          final updatedMedication = medication.copyWith(takenStatus: updatedStatus);
          await MedicationDB.instance.updateMedication(updatedMedication);
        }
      }
    } catch (e) {
      print('Error marking medication as taken: $e');
    }
  }

  static Future<void> snoozeMedication(int medicationId, int reminderIndex) async {
    try {
      await _stopAlarm();
      final notificationId = generateNotificationId(medicationId, reminderIndex);
      await snoozeNotification(
        notificationId,
        'Medication Reminder (Snoozed)',
        'Time to take your medication',
        medicationId,
        reminderIndex,
      );
    } catch (e) {
      print('Error snoozing medication: $e');
    }
  }
}