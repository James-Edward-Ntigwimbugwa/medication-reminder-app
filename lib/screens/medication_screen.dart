import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';
import '../services/notification_service.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  _MedicationScreenState createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> with WidgetsBindingObserver {
  List<Medication> _medications = [];
  bool _notificationsEnabled = true;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app comes to foreground, refresh medication status
    if (state == AppLifecycleState.resumed) {
      _fetchMedications();
      _checkNotificationPermissions();
    }

    // When app goes to background, ensure notifications are scheduled
    if (state == AppLifecycleState.paused) {
      _rescheduleAllNotifications();
    }
  }

  Future<void> _initializeNotifications() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      print('Initializing notification service...');

      // Initialize the notification service
      final initialized = await NotificationService.initialize();
      print('Notification service initialized: $initialized');

      if (!initialized) {
        _showInitializationError();
      }

      // Check permissions
      await _checkNotificationPermissions();

      // Fetch medications
      await _fetchMedications();

      // Reschedule all notifications to ensure they're active
      await _rescheduleAllNotifications();

      print('Medication screen initialization complete');

    } catch (e) {
      print('Error initializing notifications: $e');
      _showInitializationError();
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _showInitializationError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to initialize notifications. Some features may not work properly.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      final permissions = await NotificationService.checkAllPermissions();
      final notificationEnabled = await NotificationService.areNotificationsEnabled();

      print('Permission status: $permissions');
      print('Notifications enabled: $notificationEnabled');

      setState(() {
        _notificationsEnabled = notificationEnabled && (permissions['notification'] ?? false);
      });

      // Show warning if critical permissions are missing
      if (!_notificationsEnabled) {
        _showPermissionWarning();
      }

    } catch (e) {
      print('Error checking permissions: $e');
      setState(() {
        _notificationsEnabled = false;
      });
    }
  }

  void _showPermissionWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Notification permissions required for medication reminders!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: _showNotificationSettings,
          ),
        ),
      );
    }
  }

  Future<void> _fetchMedications() async {
    try {
      final meds = await MedicationDB.instance.readAllMedications();
      print('Fetched ${meds.length} medications');

      setState(() {
        _medications = meds;
      });
    } catch (e) {
      print('Error fetching medications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleAllNotifications() async {
    try {
      print('Rescheduling all notifications...');
      await MedicationDB.instance.rescheduleAllNotifications();
      print('All notifications rescheduled successfully');
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  // Getter and setter for isAlarmPlaying
  bool get _isAlarmPlaying => NotificationService.isAlarmPlaying;
  set _isAlarmPlaying(bool value) {
    // This setter might not be directly used for setting, but good for symmetry
  }

  Future<void> _toggleTakenStatus(int medIndex, int reminderIndex) async {
    if (medIndex >= _medications.length) return;

    final med = _medications[medIndex];

    // Make sure lists are aligned
    if (reminderIndex >= med.takenStatus.length) return;

    final updatedStatus = List<bool>.from(med.takenStatus);
    updatedStatus[reminderIndex] = !updatedStatus[reminderIndex];

    final updatedMed = Medication(
      id: med.id,
      name: med.name,
      unit: med.unit,
      frequency: med.frequency,
      reminderTimes: med.reminderTimes,
      doses: med.doses,
      takenStatus: updatedStatus,
    );

    try {
      await MedicationDB.instance.updateMedication(updatedMed);

      setState(() {
        _medications[medIndex] = updatedMed;
      });

      // Stop any playing alarm when medication is marked as taken
      if (updatedStatus[reminderIndex]) {
        await NotificationService.stopCurrentAlarm();
      }

      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                updatedStatus[reminderIndex]
                    ? 'Marked as taken!'
                    : 'Marked as not taken'
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: updatedStatus[reminderIndex] ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error updating medication status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(int medicationId, bool enabled) async {
    try {
      await MedicationDB.instance.toggleNotifications(medicationId, enabled);
      await _fetchMedications(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                enabled
                    ? 'Notifications enabled for this medication'
                    : 'Notifications disabled for this medication'
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error toggling notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System notifications: ${_notificationsEnabled ? 'Enabled' : 'Disabled'}'),
            const SizedBox(height: 16),
            if (!_notificationsEnabled) ...[
              const Text(
                'Please enable notifications in your device settings to receive medication reminders.',
                style: TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 8),
              const Text(
                'Required permissions:\n• Notifications\n• Exact Alarms\n• System Alert Window',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _initializeNotifications();
                    },
                    child: const Text('Refresh Status'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await NotificationService.showTestNotification();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Alarm'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        actions: [
          if (_isInitializing) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: _notificationsEnabled ? Colors.green : Colors.red,
              ),
              onPressed: _showNotificationSettings,
            ),
          ],
          // Stop alarm button (only show if alarm is playing)
          if (_isAlarmPlaying)
            IconButton(
              icon: const Icon(Icons.volume_off, color: Colors.red),
              onPressed: () async {
                await NotificationService.stopCurrentAlarm();
                setState(() {}); // Refresh to hide the button
              },
            ),
        ],
      ),
      body: _medications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No medications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first medication',
              style: TextStyle(color: Colors.grey),
            ),
            if (_isInitializing) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Initializing notifications...', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      )
          : ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final med = _medications[index];
          final reminderCount = med.reminderTimes.length;
          final isNotificationEnabled = med.notificationsEnabled ?? true;

          return Dismissible(
            key: Key(med.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Medication?'),
                  content: Text(
                    'Are you sure you want to delete ${med.name}?\n\nThis will also cancel all reminders for this medication.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) async {
              try {
                await MedicationDB.instance.deleteMedication(med.id!);
                setState(() {
                  _medications.removeAt(index);
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${med.name} deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Undo not implemented yet')),
                          );
                        },
                      ),
                    ),
                  );
                }
              } catch (e) {
                print('Error deleting medication: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting medication: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: Colors.teal.shade700,
                  ),
                ),
                title: Text(
                  '${med.name} (${med.unit})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Row(
                  children: [
                    Text(med.frequency),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _toggleNotifications(med.id!, !isNotificationEnabled),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNotificationEnabled ? Icons.notifications_active : Icons.notifications_off,
                            size: 16,
                            color: isNotificationEnabled && _notificationsEnabled ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNotificationEnabled ? 'On' : 'Off',
                            style: TextStyle(
                              fontSize: 12,
                              color: isNotificationEnabled && _notificationsEnabled ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                children: [
                  ...List.generate(reminderCount, (i) {
                    final time = med.reminderTimes[i];
                    final dose = i < med.doses.length ? med.doses[i] : 'Unknown';
                    final taken = i < med.takenStatus.length ? med.takenStatus[i] : false;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: taken ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: taken ? Colors.green.shade200 : Colors.orange.shade200,
                        ),
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _toggleTakenStatus(index, i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              taken ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: taken ? Colors.green : Colors.orange,
                              size: 28,
                            ),
                          ),
                        ),
                        title: Text(
                          'Time: $time',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('Dose: $dose'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: taken ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            taken ? 'Taken' : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onTap: () => _toggleTakenStatus(index, i),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
      // Floating action button to test notifications
      floatingActionButton: _notificationsEnabled
          ? FloatingActionButton.extended(
        onPressed: () async {
          await NotificationService.showTestNotification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Test notification sent! Alarm will play for 2 minutes.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        icon: const Icon(Icons.notifications_active),
        label: const Text('Test'),
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }
}