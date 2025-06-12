// alarm_service.dart - FIXED VERSION
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz2;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../database/medication_db.dart';
import '../models/medication.dart';

// Global variable to store medication data for alarm callback
Map<int, Map<String, dynamic>> _alarmMedicationData = {};

@pragma('vm:entry-point')
void alarmCallback(int alarmId) {
  print('🔔 Alarm callback triggered with ID: $alarmId');
  AlarmService.handleAlarmTrigger(alarmId);
}

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

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

  static Future<bool> _requestAlarmPermissions() async {
    try {
      // Request notification permission first
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      final notificationStatus = await Permission.notification.status;
      print('Notification permission: ${notificationStatus.isGranted}');

      // Request exact alarm permission (critical for Android 12+)
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

  static void handleAlarmTrigger(int alarmId) {
    print('🔔 Alarm triggered from AndroidAlarmManager with ID: $alarmId');

    // Get medication data
    final medicationData = _alarmMedicationData[alarmId];
    if (medicationData != null) {
      final medicationName = medicationData['medicationName'];
      final dose = medicationData['dose'];
      print('💊 Time to take: $medicationName ($dose)');
    }

    // Play alarm sound immediately
    playAlarmSound();

    // Trigger callback if set
    if (_onAlarmTriggered != null) {
      final payload = medicationData != null
          ? '${medicationData['medicationId']}:${medicationData['reminderIndex']}'
          : null;
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
      // Play alarm with maximum volume
      await _ringtonePlayer.playAlarm(
        asAlarm: true,
        volume: 1.0, // Maximum volume
        looping: true, // Keep playing until stopped
      );
      print('🔊 Alarm playing');

      // Auto-stop after 5 minutes to prevent infinite playing
      Future.delayed(const Duration(minutes: 5), () {
        if (_isAlarmPlaying) {
          print('🔊 Auto-stopping alarm after 5 minutes');
          _stopAlarm();
        }
      });
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

  // Main method to schedule medication alarms
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

      // Store medication data for alarm callback
      _alarmMedicationData[alarmId] = {
        'medicationId': medication.id!,
        'reminderIndex': i,
        'medicationName': medication.name,
        'dose': dose,
      };

      // Schedule the repeating alarm
      await _scheduleRepeatingAlarm(alarmId, hour, minute);
    }
  }

  static Future<void> _scheduleRepeatingAlarm(
      int alarmId,
      int hour,
      int minute,
      ) async {
    try {
      // FIXED: Use proper local timezone handling
      final now = DateTime.now();

      // Create the target time for today in local timezone
      var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has passed today, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
        print('⏰ Time has passed today, scheduling for tomorrow');
      }

      // CRITICAL FIX: Don't convert to TZDateTime - use DateTime directly
      print('🔔 Current time: ${now.toString()}');
      print('🔔 Scheduling alarm $alarmId for: ${alarmTime.toString()}');
      print('🔔 Time until alarm: ${alarmTime.difference(now)}');

      // Use DateTime directly instead of TZDateTime
      final success = await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        alarmCallback,
        startAt: alarmTime, // Use DateTime directly
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );

      if (success) {
        print('✅ Alarm scheduled successfully at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      } else {
        print('❌ Failed to schedule alarm');
      }
    } catch (e) {
      print('❌ Error scheduling alarm: $e');
    }
  }

  // Add test method for immediate testing
  static Future<void> testAlarmIn30Seconds() async {
    final testAlarmId = 99999;
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 30));

    print('🧪 Testing alarm in 30 seconds at: ${testTime.toString()}');

    // Store test data
    _alarmMedicationData[testAlarmId] = {
      'medicationId': 999,
      'reminderIndex': 0,
      'medicationName': 'Test Medication',
      'dose': '1 test dose',
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

  // Add test method for 2 minutes (easier to catch)
  static Future<void> testAlarmIn2Minutes() async {
    final testAlarmId = 99998;
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 2));

    print('🧪 Testing alarm in 2 minutes at: ${testTime.toString()}');

    // Store test data
    _alarmMedicationData[testAlarmId] = {
      'medicationId': 998,
      'reminderIndex': 0,
      'medicationName': 'Test Medication 2min',
      'dose': '1 test dose',
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
        orElse: () => Medication(
            name: '', unit: '', frequency: '', reminderTimes: [], doses: [], takenStatus: []));

    if (medication.name.isEmpty) {
      print('❌ Medication with ID $medicationId not found, cannot cancel alarms.');
      return;
    }

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final alarmId = _generateAlarmId(medicationId, i);

      // Remove stored data
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

      // Schedule a one-time alarm for 10 minutes from now
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