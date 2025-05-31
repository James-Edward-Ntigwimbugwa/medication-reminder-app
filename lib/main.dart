import 'package:flutter/material.dart';
import 'screens/add_medication_screen.dart';
import 'screens/medication_screen.dart';
import 'package:doziyangu/screens/health_info_hub_screen.dart';
import 'screens/communication_screen.dart';
import 'screens/language_settings_screen.dart';
import 'services/notification_service.dart';
import 'database/medication_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService.initialize();

  // Reschedule all medication notifications on app start
  await MedicationDB.instance.rescheduleAllNotifications();

  runApp(const DoziYanguApp());
}

class DoziYanguApp extends StatelessWidget {
  const DoziYanguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoziYangu',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;

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
      body: _screens[_selectedIndex],
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