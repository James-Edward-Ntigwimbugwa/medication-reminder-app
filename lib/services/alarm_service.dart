import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../database/medication_db.dart';
import '../models/medication.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Map<int, Map<String, dynamic>> _alarmMedicationData = {};

@pragma('vm:entry-point')
void alarmCallback(int alarmId) {
  print('🔔 Alarm callback triggered with ID: $alarmId');
  AlarmService.handleAlarmTrigger(alarmId);

  // Reschedule for the next day
  final medicationData = _alarmMedicationData[alarmId];
  if (medicationData != null) {
    final timeString = medicationData['reminderTime'] as String;
    final nextAlarmTime = AlarmService._getNextAlarmTimeForTomorrow(timeString);
    AndroidAlarmManager.oneShotAt(
      nextAlarmTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    ).then((success) {
      if (success) {
        print('✅ Alarm rescheduled for next day at $nextAlarmTime');
      } else {
        print('❌ Failed to reschedule alarm');
      }
    });
  }
}

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static bool _isAlarmPlaying = false;
  static Function(String?)? _onAlarmTriggered;

  static Future<bool> initialize() async {
    try {
      tz.initializeTimeZones();
      final alarmInitialized = await AndroidAlarmManager.initialize();
      print('AndroidAlarmManager initialized: $alarmInitialized');

      final permissionGranted = await _requestAlarmPermissions();
      print('Alarm permissions granted: $permissionGranted');

      return permissionGranted && alarmInitialized;
    } catch (e) {
      print('Error initializing AlarmService: $e');
      return false;
    }
  }

  static DateTime _getNextAlarmTimeForTomorrow(String timeString) {
    final now = DateTime.now();
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    var todayAlarmTime = DateTime(now.year, now.month, now.day, hour, minute);
    return todayAlarmTime.add(const Duration(days: 1));
  }

  static Future<bool> _requestAlarmPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      final notificationStatus = await Permission.notification.status;
      print('Notification permission: ${notificationStatus.isGranted}');

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      print('Exact alarm permission: ${exactAlarmStatus.isGranted}');

      return notificationStatus.isGranted && exactAlarmStatus.isGranted;
    } catch (e) {
      print('Error requesting alarm permissions: $e');
      return false;
    }
  }

  static Future<void> handleAlarmTrigger(int alarmId) async {
    print('🔔 Alarm triggered from AndroidAlarmManager with ID: $alarmId');

    final medicationData = _alarmMedicationData[alarmId];
    String title = 'Medication Reminder';
    String body = 'Time to take your medication';
    String? payload;
    if (medicationData != null) {
      title = 'Time to take ${medicationData['medicationName']}';
      body = 'Dose: ${medicationData['dose']}';
      payload = '${medicationData['medicationId']}:${medicationData['reminderIndex']}';
      print('💊 $title ($body)');
    }

    // Show full-screen notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_id',
      'Alarm Notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      alarmId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    // Play alarm sound and set 1-minute timeout
    await playAlarmSound();
    Future.delayed(const Duration(minutes: 1), () async {
      if (_isAlarmPlaying) {
        await _stopAlarm();
        if (medicationData != null) {
          final missedTitle = 'Missed Medication';
          final missedBody = 'You missed your ${medicationData['medicationName']} at ${medicationData['reminderTime']}';
          const AndroidNotificationDetails missedDetails = AndroidNotificationDetails(
            'missed_medication_channel_id',
            'Missed Medication Notifications',
            importance: Importance.high,
            priority: Priority.high,
          );
          const NotificationDetails missedNotificationDetails = NotificationDetails(android: missedDetails);
          await _notificationsPlugin.show(
            alarmId + 10000,
            missedTitle,
            missedBody,
            missedNotificationDetails,
          );
          print('📢 Sent missed medication notification');
        }
      }
    });

    if (_onAlarmTriggered != null) {
      print('🔔 Triggering callback with payload: $payload');
      _onAlarmTriggered!(payload);
    } else {
      print('⚠️ No alarm callback registered!');
    }
  }

  static void setAlarmTriggerCallback(Function(String?)? callback) {
    _onAlarmTriggered = callback;
    print('🔔 Alarm trigger callback ${callback != null ? 'registered' : 'cleared'}');
  }

  static Future<void> playAlarmSound() async {
    debugPrint('🔊 playAlarmSound called');
    if (_isAlarmPlaying) {
      print('🔊 Alarm already playing, skipping...');
      return;
    }

    print('🔊 Starting alarm sound...');
    _isAlarmPlaying = true;

    try {
      await _ringtonePlayer.playAlarm(
        asAlarm: true,
        volume: 1.0,
        looping: true,
      );
      print('🔊 Alarm playing');
    } catch (e) {
      print('❌ Error playing alarm: $e');
      _isAlarmPlaying = false;
    }
  }

  static Future<void> _stopAlarm() async {
    if (!_isAlarmPlaying) return;

    try {
      await _ringtonePlayer.stop();
      _isAlarmPlaying = false;
      print('🔊 Alarm stopped successfully');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
  }

  static Future<void> scheduleMedicationAlarms(Medication medication) async {
    if (medication.id == null) {
      print('❌ Cannot schedule alarms: medication ID is null');
      return;
    }

    print('🔔 Scheduling alarms for medication: ${medication.name}');
    await cancelMedicationAlarms(medication.id!);

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final timeString = medication.reminderTimes[i];
      final dose = i < medication.doses.length ? medication.doses[i] : '1 dose';

      final timeParts = timeString.split(':');
      if (timeParts.length != 2) {
        print('❌ Invalid time format: $timeString');
        continue;
      }

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) {
        print('❌ Cannot parse time: $timeString');
        continue;
      }

      final alarmId = _generateAlarmId(medication.id!, i);
      final nextAlarmTime = _getNextAlarmTime(timeString);

      _alarmMedicationData[alarmId] = {
        'medicationId': medication.id!,
        'reminderIndex': i,
        'medicationName': medication.name,
        'dose': dose,
        'reminderTime': timeString,
      };

      final success = await AndroidAlarmManager.oneShotAt(
        nextAlarmTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
      );

      if (success) {
        print('✅ Alarm scheduled at ${nextAlarmTime.toString()}');
      } else {
        print('❌ Failed to schedule alarm');
      }
    }
  }

  static DateTime _getNextAlarmTime(String timeString) {
    final now = DateTime.now();
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }
    return alarmTime;
  }

  static Future<void> testAlarmIn30Seconds() async {
    final testAlarmId = 99999;
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 30));

    print('🧪 Testing alarm in 30 seconds at: ${testTime.toString()}');

    _alarmMedicationData[testAlarmId] = {
      'medicationId': 999,
      'reminderIndex': 0,
      'medicationName': 'Test Medication',
      'dose': '1 test dose',
      'reminderTime': '${now.hour}:${now.minute}',
    };

    final success = await AndroidAlarmManager.oneShot(
      const Duration(seconds: 30),
      testAlarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );

    print(success ? '✅ Test alarm scheduled for 30 seconds' : '❌ Test alarm failed');
  }

  static Future<void> testAlarmIn2Minutes() async {
    final testAlarmId = 99998;
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 2));

    print('🧪 Testing alarm in 2 minutes at: ${testTime.toString()}');

    _alarmMedicationData[testAlarmId] = {
      'medicationId': 998,
      'reminderIndex': 0,
      'medicationName': 'Test Medication 2min',
      'dose': '1 test dose',
      'reminderTime': '${now.hour}:${now.minute}',
    };

    final success = await AndroidAlarmManager.oneShot(
      const Duration(minutes: 2),
      testAlarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );

    print(success ? '✅ Test alarm scheduled for 2 minutes' : '❌ Test alarm failed');
  }

  static Future<void> cancelMedicationAlarms(int medicationId) async {
    final medications = await MedicationDB.instance.readAllMedications();
    final medication = medications.firstWhere(
          (m) => m.id == medicationId,
      orElse: () => Medication(name: '', unit: '', frequency: '', reminderTimes: [], doses: [], takenStatus: []),
    );

    if (medication.name.isEmpty) {
      print('❌ Medication with ID $medicationId not found, cannot cancel alarms.');
      return;
    }

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final alarmId = _generateAlarmId(medicationId, i);
      _alarmMedicationData.remove(alarmId);

      try {
        await AndroidAlarmManager.cancel(alarmId);
        print('✅ Cancelled alarm $alarmId for medication $medicationId');
      } catch (e) {
        print('❌ Error canceling alarm $alarmId: $e');
      }
    }
  }

  static Future<void> cancelAllAlarms() async {
    _alarmMedicationData.clear();
    _stopAlarm();
    print('🔔 All alarms cancelled');
  }

  static int _generateAlarmId(int medicationId, int reminderIndex) {
    return medicationId * 200 + reminderIndex;
  }

  static Future<Map<String, bool>> checkAlarmPermissions() async {
    return {
      'notification': await Permission.notification.isGranted,
      'exactAlarm': await Permission.scheduleExactAlarm.isGranted,
    };
  }

  static Future<void> stopCurrentAlarm() async {
    await _stopAlarm();
  }

  static bool get isAlarmPlaying => _isAlarmPlaying;

  static Future<void> markMedicationAsTaken(int medicationId, int reminderIndex) async {
    try {
      await _stopAlarm();

      final medications = await MedicationDB.instance.readAllMedications();
      final medicationIndex = medications.indexWhere((m) => m.id == medicationId);

      if (medicationIndex != -1) {
        final medication = medications[medicationIndex];
        final updatedStatus = List<bool>.from(medication.takenStatus);

        if (reminderIndex < updatedStatus.length) {
          updatedStatus[reminderIndex] = true;

          final updatedMedication = medication.copyWith(takenStatus: updatedStatus);
          await MedicationDB.instance.updateMedication(updatedMedication);

          print('✅ Marked ${medication.name} as taken');
        }
      }
    } catch (e) {
      print('❌ Error marking medication as taken: $e');
    }
  }

  static Future<void> snoozeMedication(int medicationId, int reminderIndex) async {
    try {
      await _stopAlarm();

      final snoozeAlarmId = _generateAlarmId(medicationId, reminderIndex) + 1000;
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));

      print('⏰ Snoozing alarm until: ${snoozeTime.toString()}');

      final success = await AndroidAlarmManager.oneShot(
        const Duration(minutes: 10),
        snoozeAlarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
      );

      if (success) {
        print('✅ Medication snoozed for 10 minutes');
      } else {
        print('❌ Failed to snooze medication');
      }
    } catch (e) {
      print('❌ Error snoozing medication: $e');
    }
  }
}