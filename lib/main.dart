import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'screens/add_medication_screen.dart';
import 'screens/medication_screen.dart';
import 'package:doziyangu/screens/health_info_hub_screen.dart';
import 'screens/communication_screen.dart';
import 'screens/language_settings_screen.dart';
import 'services/notification_service.dart' as notification_svc;
import 'database/medication_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service and request permissions
  final permissionsGranted =
      await notification_svc.NotificationService.initialize();

  if (!permissionsGranted) {
    developer.log(
      'Some permissions were not granted. Notifications may not work properly.',
    );
  }

  // Reschedule all medication notifications on app start
  await MedicationDB.instance.rescheduleAllNotifications();

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
      home: HomeScreen(permissionsGranted: permissionsGranted),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

    // Show permission dialog if not granted
    if (!widget.permissionsGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
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
    // Reschedule notifications when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      MedicationDB.instance.rescheduleAllNotifications();
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    final permissions =
        await notification_svc.NotificationService.checkAllPermissions();
    final allGranted = permissions.values.every((granted) => granted);

    if (!mounted) return;
    setState(() {
      _showPermissionBanner = !allGranted;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notification_important, color: Colors.orange),
              SizedBox(width: 8),
              Text('Permissions Required'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DoziYangu needs the following permissions to remind you about your medications:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.notifications, size: 20, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifications - To alert you when it\'s time to take medication',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.vibration, size: 20, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phone access - To use ringtone and vibration for alerts',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
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
    final granted = await notification_svc.NotificationService.initialize();
    if (!mounted) return;
    setState(() {
      _showPermissionBanner = !granted;
    });

    if (granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ All permissions granted! Medication reminders are now active.',
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

  void _testNotification() async {
    await notification_svc.NotificationService.showTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '🔔 Test notification sent! Check how it sounds and vibrates.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0) // Show test button only on medication screen
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: _testNotification,
              tooltip: 'Test Notification',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Permission banner
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
                      'Some permissions are missing. Medication reminders may not work properly.',
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
          // Main content
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
