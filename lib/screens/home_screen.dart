import 'package:flutter/material.dart';
import 'package:doziyangu/l10n/l10n.dart';
import '../database/medication_db.dart';
import '../main.dart';
import '../services/alarm_service.dart';
import 'add_medication_screen.dart';
import 'communication_screen.dart';
import 'health_info_hub_screen.dart';
import 'language_settings_screen.dart';
import 'medication_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool permissionsGranted;

  const HomeScreen({super.key, required this.permissionsGranted});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  bool _showPermissionBanner = false;
  final GlobalKey<State<HealthInfoScreen>> _healthInfoScreenKey =
      GlobalKey<State<HealthInfoScreen>>();
  late final List<Widget> _screens;

  List<String> get _titles => [
    AppLocalizations.of(context)!.medications,
    AppLocalizations.of(context)!.healthInfo,
    AppLocalizations.of(context)!.chat,
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      MedicationScreen(),
      HealthInfoScreen(key: _healthInfoScreenKey),
      const CommunicationScreen(),
    ];
    WidgetsBinding.instance.addObserver(this);
    _showPermissionBanner = !widget.permissionsGranted;
    _checkInitialNotification();

    if (!widget.permissionsGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }
  }

  Future<void> _checkInitialNotification() async {
    final notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
      final payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null) {
        await Future.delayed(Duration.zero);
        navigatorKey.currentState!.pushNamed('/alarm', arguments: payload);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      MedicationDB.instance.rescheduleAllAlarms();
    }
  }

  void _showPermissionDialog() {
    final local = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.alarm, color: Colors.orange),
              const SizedBox(width: 8),
              Text(local.permissionsRequired),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                local.permissionExplanation,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.alarm, size: 20, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(local.exactAlarmReason)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                local.missedReminderWarning,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showPermissionBanner = true;
                });
              },
              child: Text(local.later),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestPermissions();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Text(
                local.grantPermissions,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    final local = AppLocalizations.of(context)!;
    final granted = await AlarmService.initialize();
    if (!mounted) return;
    setState(() {
      _showPermissionBanner = !granted;
    });

    if (granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.allPermissionsGranted),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.permissionDenied),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: local.settings,
            onPressed: () => _showPermissionDialog(),
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _goToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  void _openChatbotModal() {
    final healthInfoState =
        _healthInfoScreenKey.currentState as HealthInfoScreenState?;
    healthInfoState?.openChatbotModal();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue, // Debug color
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showPermissionBanner)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      local.permissionBanner,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _requestPermissions,
                    child: Text(
                      local.fix,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _showPermissionBanner = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                onPressed: _goToAddMedication,
                icon: const Icon(Icons.add),
                label: Text(local.addMedication),
                backgroundColor: Colors.teal,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              )
              : _selectedIndex == 1
              ? FloatingActionButton.extended(
                onPressed: _openChatbotModal,
                label: Text(local.chatbot),
                icon: const Icon(Icons.chat_bubble_outline),
                backgroundColor: Colors.teal,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: local.medications,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            label: local.healthInfo,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medical_services),
            label: local.chat,
          ),
        ],
      ),
    );
  }
}
