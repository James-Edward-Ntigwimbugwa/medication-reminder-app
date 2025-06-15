import 'package:flutter/material.dart';

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

  static final List<Widget> _screens = [
    MedicationScreen(),
    HealthInfoScreen(),
    const CommunicationScreen(),
  ];

  static const List<String> _titles = [
    'Medications',
    'Health Info Hub',
    'Communication',
  ];

  @override
  void initState() {
    super.initState();
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.alarm, color: Colors.orange),
              SizedBox(width: 8),
              Text('Permissions Required'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DoziYangu needs the following permissions for medication alarms:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.alarm, size: 20, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Exact alarms - For precise medication timing'),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Without these permissions, you may miss important medication reminders.',
                style: TextStyle(color: Colors.red, fontSize: 13),
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
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestPermissions();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                'Grant Permissions',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    final granted = await AlarmService.initialize();
    if (!mounted) return;
    setState(() {
      _showPermissionBanner = !granted;
    });

    if (granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ All permissions granted! Medication alarms are now active.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Some permissions were denied. Please enable them in Settings.',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Settings',
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
      MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
    );
  }

  void _goToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
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
                  const Expanded(
                    child: Text(
                      'Exact alarm permission missing. Medication alarms may not work.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _requestPermissions,
                    child: const Text(
                      'Fix',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                label: const Text("Add Medication"),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Medications'),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Health Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
