// Imports necessary packages for Flutter UI, localization, database, and app-specific screens/services.
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

// Stateless widget serving as the main entry point for the app's home screen.
class HomeScreen extends StatefulWidget {
  // Flag indicating whether necessary permissions are granted.
  final bool permissionsGranted;

  // Constructor with required permissionsGranted parameter.
  const HomeScreen({super.key, required this.permissionsGranted});

  // Creates the state object for this widget.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// State class managing navigation, permissions, and lifecycle for HomeScreen.
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Index of the currently selected bottom navigation bar item.
  int _selectedIndex = 0; // Changed from 1 to 0 to open MedicationScreen

  // Flag to show/hide the permission banner.
  bool _showPermissionBanner = false;

  // Global key to access HealthInfoScreen's state for chatbot modal control.
  final GlobalKey<State<HealthInfoScreen>> _healthInfoScreenKey =
      GlobalKey<State<HealthInfoScreen>>();

  // List of screens for bottom navigation bar navigation.
  late final List<Widget> _screens;

  // Getter for app bar titles based on selected screen index.
  List<String> get _titles => [
    AppLocalizations.of(context)!.medications,
    AppLocalizations.of(context)!.healthInfo,
    AppLocalizations.of(context)!.chat,
  ];

  // Initializes state, sets up screens, and handles permissions.
  @override
  void initState() {
    super.initState();
    // Initialize screens for navigation.
    _screens = [
      MedicationScreen(),
      HealthInfoScreen(key: _healthInfoScreenKey),
      const CommunicationScreen(),
    ];
    // Register as a lifecycle observer.
    WidgetsBinding.instance.addObserver(this);
    // Set permission banner visibility based on permissionsGranted.
    _showPermissionBanner = !widget.permissionsGranted;
    // Check for notification that launched the app.
    _checkInitialNotification();

    // Show permission dialog if permissions are not granted.
    if (!widget.permissionsGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }
  }

  // Checks if the app was launched by a notification and navigates accordingly.
  Future<void> _checkInitialNotification() async {
    final notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
      final payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null) {
        // Delay navigation to ensure UI is ready.
        await Future.delayed(Duration.zero);
        navigatorKey.currentState!.pushNamed('/alarm', arguments: payload);
      }
    }
  }

  // Cleans up resources when the widget is disposed.
  @override
  void dispose() {
    // Remove lifecycle observer.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handles app lifecycle changes, such as resuming the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reschedule alarms when the app resumes.
    if (state == AppLifecycleState.resumed) {
      MedicationDB.instance.rescheduleAllAlarms();
    }
  }

  // Displays a dialog prompting the user to grant permissions.
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
              // Explain why permissions are needed.
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
              // Warn about consequences of not granting permissions.
              Text(
                local.missedReminderWarning,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
          actions: [
            // Allow user to postpone permission request.
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showPermissionBanner = true;
                });
              },
              child: Text(local.later),
            ),
            // Request permissions immediately.
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

  // Requests permissions for alarms and updates UI based on result.
  Future<void> _requestPermissions() async {
    final local = AppLocalizations.of(context)!;
    final granted = await AlarmService.initialize();
    if (!mounted) return;
    setState(() {
      _showPermissionBanner = !granted;
    });

    // Show success message if permissions are granted.
    if (granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.allPermissionsGranted),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show error message with option to retry if permissions are denied.
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

  // Updates the selected bottom navigation bar index.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Navigates to the settings screen.
  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // Navigates to the add medication screen.
  void _goToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  // Opens the chatbot modal from HealthInfoScreen.
  void _openChatbotModal() {
    final healthInfoState =
        _healthInfoScreenKey.currentState as HealthInfoScreenState?;
    healthInfoState?.openChatbotModal();
  }

  // Constructs the UI for the HomeScreen.
  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue, // Debug color for visibility.
        actions: [
          // Settings button to navigate to settings screen.
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Permission banner shown if permissions are not granted.
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
                  // Button to request permissions.
                  TextButton(
                    onPressed: _requestPermissions,
                    child: Text(
                      local.fix,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Button to dismiss the banner.
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
          // Displays the selected screen from _screens list.
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: _goToAddMedication,
                  icon: const Icon(Icons.add),
                  label: Text(local.addMedication),
                  backgroundColor: const Color.fromARGB(255, 27, 151, 209),
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
                      backgroundColor: const Color.fromARGB(255, 128, 182, 243),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )
                  : null, // No FAB for other screens.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          // Navigation item for Medications screen.
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: local.medications,
          ),
          // Navigation item for Health Info screen.
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            label: local.healthInfo,
          ),
          // Navigation item for Chat screen.
          BottomNavigationBarItem(
            icon: const Icon(Icons.medical_services),
            label: local.chat,
          ),
        ],
      ),
    );
  }
}