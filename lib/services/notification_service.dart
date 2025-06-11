import 'dart:typed_data';
import 'dart:ui';
import 'dart:math';
import 'package:doziyangu/utils/alarm_sounds.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/medication_db.dart';
import '../models/medication.dart';

// TOP-LEVEL ALARM CALLBACK FUNCTION - MUST BE OUTSIDE CLASS
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

  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isAlarmPlaying = false;
  static int? _currentAlarmId;
  static Function(String?)? _onAlarmTriggered;
  static BuildContext? _overlayContext;

  // Getter for the alarm trigger callback
  static Function(String?)? getAlarmTriggerCallback() {
    return _onAlarmTriggered;
  }

  // Initialize notifications and alarm manager
  static Future<bool> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize Android Alarm Manager
      final alarmInitialized = await AndroidAlarmManager.initialize();
      print('AndroidAlarmManager initialized: $alarmInitialized');

      // Request permissions first
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

      // Create notification channel with high importance for Android
      await _createNotificationChannel();

      return permissionGranted && alarmInitialized;
    } catch (e) {
      print('Error initializing NotificationService: $e');
      return false;
    }
  }

  static Future<bool> _requestAllPermissions() async {
    try {
      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      print('Notification permission: ${notificationStatus.isGranted}');

      // Request phone permission for ringtone access
      final phoneStatus = await Permission.phone.request();
      print('Phone permission: ${phoneStatus.isGranted}');

      // Request exact alarm permission for Android 12+
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      print('Exact alarm permission: ${exactAlarmStatus.isGranted}');

      // Request system alert window permission for alarm overlay
      final systemAlertWindowStatus = await Permission.systemAlertWindow.request();
      print('System alert window permission: ${systemAlertWindowStatus.isGranted}');

      // Additional permissions for Android
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final exactAlarmPermission = await androidImplementation.requestExactAlarmsPermission();
        final notificationPermission = await androidImplementation.requestNotificationsPermission();
        print('Android exact alarm permission: $exactAlarmPermission');
        print('Android notification permission: $notificationPermission');
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
      playSound: false, // We'll handle sound with AudioPlayer
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

    // Trigger alarm and show overlay dialog
    _handleAlarmFromNotification(response.payload);

    // Handle different actions
    switch (response.actionId) {
      case 'mark_taken':
        _handleMarkAsTaken(response.payload);
        break;
      case 'snooze':
        _handleSnooze(response.payload);
        break;
      default:
      // Handle default tap - show overlay
        break;
    }
  }

  // New method to handle alarm trigger from notification
  static void _handleAlarmFromNotification(String? payload) {
    // Start playing alarm
    playAlarmSound();

    // Show overlay dialog if context is available
    if (_onAlarmTriggered != null) {
      _onAlarmTriggered!(payload);
    }
  }

  // New method to handle alarm trigger from AndroidAlarmManager
  static void handleAlarmTrigger() {
    print('Alarm triggered from AndroidAlarmManager!');
    playAlarmSound();

    // Trigger overlay if callback is set
    if (_onAlarmTriggered != null) {
      _onAlarmTriggered!(null); // No payload from alarm manager
    }
  }

  // Set alarm trigger callback
  static void setAlarmTriggerCallback(Function(String?)? callback) {
    _onAlarmTriggered = callback;
  }

  static void _handleMarkAsTaken(String? payload) {
    if (payload != null) {
      print('Marking medication as taken: $payload');
      _stopAlarm();
      // Cancel the alarm for this medication time
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

  static void _handleSnooze(String? payload) {
    if (payload != null) {
      print('Snoozing medication: $payload');
      _stopAlarm();
      final parts = payload.split(':');
      if (parts.length == 2) {
        final medicationId = int.tryParse(parts[0]);
        final reminderIndex = int.tryParse(parts[1]);
        if (medicationId != null && reminderIndex != null) {
          final notificationId = _generateNotificationId(medicationId, reminderIndex);
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

  // Play alarm sound continuously (ONLY when alarm actually triggers)
  static Future<void> playAlarmSound() async {
    debugPrint('playAlarmSound called');
    if (_isAlarmPlaying) {
      print('Alarm already playing, skipping...');
      return;
    }

    print('Starting alarm sound...');
    _isAlarmPlaying = true;

    try {
      // Select random alarm sound
      final random = Random();
      final selectedAlarm = Alarms.alarmSounds[random.nextInt(Alarms.alarmSounds.length)];
      print('Selected alarm sound: $selectedAlarm');

      // Stop any previous audio first
      await _audioPlayer.stop();
      print('Audio player stopped');

      // Set audio player mode for alarm
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0); // Maximum volume
      print('Audio player mode and volume set');

      // Play the alarm sound in loop
      await _audioPlayer.play(AssetSource(selectedAlarm));
      print('Alarm playing: $selectedAlarm');

      // Stop alarm after 2 minutes if not stopped manually
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
      // Android notification without sound (handled by AudioPlayer when triggered)
      AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'medication_reminders_high',
        'Medication Reminders',
        channelDescription: 'High priority notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,

        // No sound - handled by our custom alarm ONLY when triggered
        playSound: false,

        // Vibration settings
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),

        // Visual settings
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,

        // Behavior settings
        autoCancel: false,
        ongoing: true, // Keep notification persistent
        showWhen: true,
        onlyAlertOnce: false,

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

      // iOS notification
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false, // Custom sound handled by AudioPlayer
        badgeNumber: 1,
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
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: payload,
      );

      print('Notification scheduled successfully');

      // DO NOT play alarm sound here - only when notification actually triggers!
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Stop alarm sound
  static Future<void> _stopAlarm() async {
    if (!_isAlarmPlaying) return;

    try {
      await _audioPlayer.stop();
      _isAlarmPlaying = false;
      print('Alarm stopped successfully');
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  // Schedule notifications for a medication with alarm
  static Future<void> scheduleMedicationReminders(Medication medication) async {
    if (medication.id == null) {
      print('Cannot schedule reminders: medication ID is null');
      return;
    }

    print('Scheduling reminders for medication: ${medication.name}');

    // Cancel existing notifications and alarms for this medication
    await cancelMedicationReminders(medication.id!);

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final timeString = medication.reminderTimes[i];
      final dose = i < medication.doses.length ? medication.doses[i] : '1 dose';

      // Parse time string (assuming format "HH:mm")
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

      // Create unique notification and alarm IDs
      final notificationId = _generateNotificationId(medication.id!, i);
      final alarmId = _generateAlarmId(medication.id!, i);

      print('Scheduling notification $notificationId and alarm $alarmId for ${hour}:${minute}');

      // Schedule daily recurring notification
      await _scheduleRepeatingNotification(
        id: notificationId,
        title: '💊 Medication Time!',
        body: 'Take ${medication.name} (${medication.unit}) - $dose',
        hour: hour,
        minute: minute,
        payload: '${medication.id}:$i',
      );

      // Schedule daily recurring alarm
      await _scheduleRepeatingAlarm(alarmId, hour, minute);
    }
  }

  // Schedule repeating alarm using AndroidAlarmManager
  static Future<void> _scheduleRepeatingAlarm(int alarmId, int hour, int minute) async {
    try {
      // Calculate next occurrence
      final now = DateTime.now();
      var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has passed today, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      print('Scheduling alarm $alarmId for ${alarmTime.toString()}');

      // Schedule daily recurring alarm using the top-level callback
      final success = await AndroidAlarmManager.periodic(
        const Duration(days: 1), // Repeat every day
        alarmId,
        alarmCallback, // Use the top-level function
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

  // Enhanced snooze with alarm
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

    // Schedule snoozed notification
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

    // Schedule snoozed alarm
    final snoozeAlarmId = _generateAlarmId(medicationId, reminderIndex) + 1000;
    await AndroidAlarmManager.oneShot(
      const Duration(minutes: 10),
      snoozeAlarmId,
      alarmCallback, // Use the top-level function
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  // Cancel a specific notification
  static Future<void> cancelSpecificNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      print('Notification $notificationId cancelled successfully');
    } catch (e) {
      print('Error cancelling notification $notificationId: $e');
    }
  }

  // Show immediate test notification with alarm
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

    // Play test alarm immediately for testing
    playAlarmSound();
  }

  // Cancel all notifications and alarms for a specific medication
  static Future<void> cancelMedicationReminders(int medicationId) async {
    final medications = await MedicationDB.instance.readAllMedications();
    final medication = medications.firstWhere((m) => m.id == medicationId, orElse: () => Medication(name: '', unit: '', frequency: '', reminderTimes: [], doses: [], takenStatus: []));

    if (medication.name.isEmpty) {
      print('Medication with ID $medicationId not found, cannot cancel reminders.');
      return;
    }

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final notificationId = _generateNotificationId(medicationId, i);
      final alarmId = _generateAlarmId(medicationId, i);

      await _notifications.cancel(notificationId);
      try {
        await AndroidAlarmManager.cancel(alarmId);
      } catch (e) {
        print('Error canceling alarm $alarmId: $e');
      }
    }
  }

  // Cancel all notifications and alarms
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    // Note: AndroidAlarmManager doesn't have cancelAll,
    // you'll need to track and cancel individual alarms
    _stopAlarm();
  }

  // Generate unique notification ID
  static int _generateNotificationId(int medicationId, int reminderIndex) {
    return medicationId * 100 + reminderIndex;
  }

  // Generate unique alarm ID
  static int _generateAlarmId(int medicationId, int reminderIndex) {
    return medicationId * 200 + reminderIndex; // Different range from notifications
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
      'systemAlertWindow': await Permission.systemAlertWindow.isGranted,
    };
  }

  // Stop any currently playing alarm (public method)
  static Future<void> stopCurrentAlarm() async {
    await _stopAlarm();
  }

  // Check if alarm is currently playing
  static bool get isAlarmPlaying => _isAlarmPlaying;

  // Public method to handle medication taken from overlay
  static Future<void> markMedicationAsTaken(int medicationId, int reminderIndex) async {
    try {
      // Stop the alarm
      await _stopAlarm();

      // Cancel the specific alarm
      final alarmId = _generateAlarmId(medicationId, reminderIndex);
      await AndroidAlarmManager.cancel(alarmId);

      // Update the medication status in database
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

  // Public method to handle snooze from overlay
  static Future<void> snoozeMedication(int medicationId, int reminderIndex) async {
    try {
      // Stop the current alarm
      await _stopAlarm();

      // Schedule snooze
      final notificationId = _generateNotificationId(medicationId, reminderIndex);
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