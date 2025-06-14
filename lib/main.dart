import 'package:doziyangu/screens/home_screen.dart';
import 'package:doziyangu/widgets/glass_alarm_overlay_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'services/alarm_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'database/medication_db.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool permissionsGranted = await AlarmService.initialize();
  tz.initializeTimeZones();

  // Initialize flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  // Create notification channels
  final AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
    'alarm_channel_id',
    'Alarm Notifications',
    description: 'Channel for medication alarm notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  final AndroidNotificationChannel missedChannel = AndroidNotificationChannel(
    'missed_medication_channel_id',
    'Missed Medication Notifications',
    description: 'Channel for missed medication notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(alarmChannel);
  await androidPlugin?.createNotificationChannel(missedChannel);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/alarm', arguments: payload);
      }
    },
  );

  if (!permissionsGranted) {
    developer.log('Some permissions were not granted. Alarms may not work properly.');
  }

  await MedicationDB.instance.rescheduleAllAlarms();

  runApp(DoziYanguApp(permissionsGranted: permissionsGranted));
}

class DoziYanguApp extends StatelessWidget {
  final bool permissionsGranted;

  const DoziYanguApp({super.key, required this.permissionsGranted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoziYangu',
      theme: ThemeData(primarySwatch: Colors.teal),
      navigatorKey: navigatorKey,
      home: HomeScreen(permissionsGranted: permissionsGranted),
      routes: {
        '/alarm': (context) => AlarmOverlayScreen(payload: ModalRoute.of(context)!.settings.arguments as String?),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
