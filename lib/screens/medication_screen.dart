// medication_screen.dart
import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';
import '../services/alarm_service.dart';
import '../widgets/glass_alarm_overlay_dialog.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  _MedicationScreenState createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> with WidgetsBindingObserver {
  List<Medication> _medications = [];
  bool _alarmPermissionsGranted = true;
  bool _isInitializing = false;
  String? _currentPayload;
  bool _isAlarmDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AlarmService.setAlarmTriggerCallback(_onAlarmTriggered);
    _initializeAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AlarmService.setAlarmTriggerCallback(null);
    super.dispose();
  }

  void _onAlarmTriggered(String? payload) {
    if (!_isAlarmDialogVisible && mounted) {
      setState(() {
        _currentPayload = payload;
        _isAlarmDialogVisible = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlarmOverlayDialog(
            payload: _currentPayload,
            onDismiss: () {
              if (mounted) {
                setState(() {
                  _isAlarmDialogVisible = false;
                  _currentPayload = null;
                });
              }
            },
          );
        },
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchMedications();
    }
    if (state == AppLifecycleState.paused) {
      _rescheduleAllAlarms();
    }
  }

  Future<void> _initializeAlarms() async {
    if (_isInitializing) return;
    setState(() => _isInitializing = true);

    try {
      final initialized = await AlarmService.initialize();
      if (!initialized) _showInitializationError();

      // Check alarm permissions
      final permissions = await AlarmService.checkAlarmPermissions();
      setState(() {
        _alarmPermissionsGranted = permissions['exactAlarm'] ?? false;
      });

      await _fetchMedications();
      await _rescheduleAllAlarms();
    } catch (e) {
      print('Error initializing alarms: $e');
      _showInitializationError();
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  void _showInitializationError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to initialize alarms. Medication reminders may not work.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showPermissionWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Exact alarm permission required for medication reminders!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: _showAlarmSettings,
          ),
        ),
      );
    }
  }

  Future<void> _fetchMedications() async {
    try {
      final meds = await MedicationDB.instance.readAllMedications();
      setState(() => _medications = meds);
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

  Future<void> _rescheduleAllAlarms() async {
    try {
      await MedicationDB.instance.rescheduleAllAlarms();
    } catch (e) {
      print('Error rescheduling alarms: $e');
    }
  }

  bool get _isAlarmPlaying => AlarmService.isAlarmPlaying;

  Future<void> _toggleTakenStatus(int medIndex, int reminderIndex) async {
    if (medIndex >= _medications.length) return;
    final med = _medications[medIndex];
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
      setState(() => _medications[medIndex] = updatedMed);

      if (updatedStatus[reminderIndex]) {
        await AlarmService.stopCurrentAlarm();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedStatus[reminderIndex] ? 'Marked as taken!' : 'Marked as not taken'),
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

  Future<void> _toggleAlarms(int medicationId, bool enabled) async {
    try {
      await MedicationDB.instance.toggleNotifications(medicationId, enabled);
      await _fetchMedications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Alarms enabled' : 'Alarms disabled'),
            duration: const Duration(seconds: 2),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error toggling alarms: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling alarms: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAlarmSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alarm Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alarms: ${_alarmPermissionsGranted ? 'Enabled' : 'Disabled'}'),
            const SizedBox(height: 16),
            if (!_alarmPermissionsGranted) ...[
              const Text(
                'Please enable exact alarms in your device settings for medication reminders',
                style: TextStyle(color: Colors.orange),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _initializeAlarms();
                    },
                    child: const Text('Refresh Status'),
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
                Icons.alarm,
                color: _alarmPermissionsGranted ? Colors.green : Colors.red,
              ),
              onPressed: _showAlarmSettings,
            ),
          ],
          if (_isAlarmPlaying)
            IconButton(
              icon: const Icon(Icons.volume_off, color: Colors.red),
              onPressed: () async {
                await AlarmService.stopCurrentAlarm();
                setState(() {});
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
              const Text('Initializing alarms...', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      )
          : ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final med = _medications[index];
          final reminderCount = med.reminderTimes.length;
          final isAlarmEnabled = med.notificationsEnabled;

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
                    'Are you sure you want to delete ${med.name}?\n\nThis will also cancel all alarms for this medication.',
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
                setState(() => _medications.removeAt(index));
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
                      onTap: () => _toggleAlarms(med.id!, !isAlarmEnabled),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAlarmEnabled ? Icons.alarm : Icons.alarm_off,
                            size: 16,
                            color: isAlarmEnabled && _alarmPermissionsGranted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAlarmEnabled ? 'On' : 'Off',
                            style: TextStyle(
                              fontSize: 12,
                              color: isAlarmEnabled && _alarmPermissionsGranted ? Colors.green : Colors.grey,
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
    );
  }
}