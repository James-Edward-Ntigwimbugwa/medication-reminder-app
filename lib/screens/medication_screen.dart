// File: lib/screens/medication_screen.dart

import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';
import '../services/notification_service.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  _MedicationScreenState createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<Medication> _medications = [];
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _fetchMedications() async {
    final meds = await MedicationDB.instance.readAllMedications();
    setState(() {
      _medications = meds;
    });
  }

  Future<void> _toggleTakenStatus(int medIndex, int reminderIndex) async {
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

    await MedicationDB.instance.updateMedication(updatedMed);
    _medications[medIndex] = updatedMed;

    setState(() {});

    // Show confirmation message
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

  Future<void> _toggleNotifications(int medicationId, bool enabled) async {
    await MedicationDB.instance.toggleNotifications(medicationId, enabled);
    _fetchMedications(); // Refresh the list

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            enabled
                ? 'Notifications enabled for this medication'
                : 'Notifications disabled for this medication'
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
            if (!_notificationsEnabled)
              const Text(
                'Please enable notifications in your device settings to receive medication reminders.',
                style: TextStyle(color: Colors.orange),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NotificationService.initialize();
                _checkNotificationPermissions();
                Navigator.of(context).pop();
              },
              child: const Text('Refresh Permission Status'),
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
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: _notificationsEnabled ? Colors.green : Colors.red,
            ),
            onPressed: _showNotificationSettings,
          ),
        ],
      ),
      body: _medications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No medications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first medication',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final med = _medications[index];
          final reminderCount = med.reminderTimes.length;

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
              await MedicationDB.instance.deleteMedication(med.id!);
              _medications.removeAt(index);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${med.name} deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // Note: In a real app, you'd want to implement proper undo functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Undo not implemented yet')),
                      );
                    },
                  ),
                ),
              );
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
                    Icon(
                      Icons.notifications,
                      size: 16,
                      color: _notificationsEnabled ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _notificationsEnabled ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: 12,
                        color: _notificationsEnabled ? Colors.green : Colors.grey,
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
    );
  }
}