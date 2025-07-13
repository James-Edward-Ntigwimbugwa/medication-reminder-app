import 'package:doziyangu/screens/home_screen.dart';
import 'package:doziyangu/screens/language_settings_screen.dart';
import 'package:doziyangu/widgets/glass_alarm_overlay_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/alarm_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'database/medication_db.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:doziyangu/l10n/l10n.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool permissionsGranted = await AlarmService.initialize();
  tz.initializeTimeZones();

  // Initialize flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

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

  final androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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
    developer.log(
      'Some permissions were not granted. Alarms may not work properly.',
    );
    developer.log(
      'Some permissions were not granted. Alarms may not work properly.',
    );
  }

  await MedicationDB.instance.rescheduleAllAlarms();

  runApp(MyApp(permissionsGranted: permissionsGranted));
}

class MyApp extends StatefulWidget {
  final bool permissionsGranted;

  const MyApp({super.key, required this.permissionsGranted});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('sw'); // Default to Swahili

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('language');
    if (savedLocale != null &&
        AppLocalizations.supportedLocales.any(
          (locale) => locale.languageCode == savedLocale,
        )) {
      setState(() {
        _locale = Locale(savedLocale);
      });
    }
  }

  void setLocale(Locale locale) async {
    if (AppLocalizations.supportedLocales.contains(locale)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);
      setState(() {
        _locale = locale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoziYangu',
      theme: ThemeData(primarySwatch: Colors.teal),
      navigatorKey: navigatorKey,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: HomeScreen(permissionsGranted: widget.permissionsGranted),
      routes: {
        '/alarm':
            (context) => AlarmOverlayScreen(
              payload: ModalRoute.of(context)!.settings.arguments as String?,
            ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
