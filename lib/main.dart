// main.dart
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'screens/add_medication_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/health_info_hub_screen.dart';
import 'screens/communication_screen.dart';
import 'screens/language_settings_screen.dart';
import 'services/alarm_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'database/medication_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize alarm service and request permissions
  final permissionsGranted = await AlarmService.initialize();
  tz.initializeTimeZones();

  if (!permissionsGranted) {
    developer.log(
      'Some permissions were not granted. Alarms may not work properly.',
    );
  }

  // Reschedule all medication alarms on app start
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
    // Reschedule alarms when app comes back to foreground
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
                    child: Text(
                      'Exact alarms - For precise medication timing',
                    ),
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