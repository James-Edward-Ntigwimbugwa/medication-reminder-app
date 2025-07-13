import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';
import '../services/alarm_service.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  _MedicationScreenState createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen>
    with WidgetsBindingObserver {
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
        SnackBar(
          content: const Text(
            'Failed to initialize alarms. Medication reminders may not work.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            content: Text(
              updatedStatus[reminderIndex]
                  ? '✓ Marked as taken!'
                  : '⏰ Marked as not taken',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: updatedStatus[reminderIndex] 
                ? Colors.green.shade600 
                : Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error updating medication status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            content: Text(
              enabled ? '🔔 Alarms enabled' : '🔕 Alarms disabled',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: enabled 
                ? Colors.green.shade600 
                : Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error toggling alarms: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling alarms: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showAlarmSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.settings, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Alarm Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _alarmPermissionsGranted 
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _alarmPermissionsGranted 
                      ? Colors.green.shade200 
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _alarmPermissionsGranted ? Icons.check_circle : Icons.error,
                    color: _alarmPermissionsGranted 
                        ? Colors.green.shade700 
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Alarms: ${_alarmPermissionsGranted ? 'Enabled' : 'Disabled'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _alarmPermissionsGranted 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_alarmPermissionsGranted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  '⚠️ Please enable exact alarms in your device settings for medication reminders to work properly.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _initializeAlarms();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Alice Blue
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_liquid,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Medications',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C5F41),
              ),
            ),
          ],
        ),
        actions: [
          if (_isInitializing) ...[
            Container(
              margin: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _alarmPermissionsGranted 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.alarm,
                  color: _alarmPermissionsGranted 
                      ? Colors.green.shade700 
                      : Colors.red.shade700,
                ),
                onPressed: _showAlarmSettings,
              ),
            ),
          ],
          if (_isAlarmPlaying)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.volume_off, color: Colors.red.shade700),
                onPressed: () async {
                  await AlarmService.stopCurrentAlarm();
                  setState(() {});
                },
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8FF), // Alice Blue - Clean medical feel
              Color(0xFFE6F3FF), // Light Sky Blue
              Color(0xFFF5F9FF), // Very Light Blue
            ],
          ),
        ),
        child: _medications.isEmpty
            ? _buildEmptyState()
            : _buildMedicationsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.medication_liquid,
                    size: 64,
                    color: Colors.blue.shade300,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No medications yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5F41),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first medication\nand start managing your health journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                if (_isInitializing) ...[
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Initializing alarms...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        final reminderCount = med.reminderTimes.length;
        final isAlarmEnabled = med.notificationsEnabled;

        return Dismissible(
          key: Key(med.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                const SizedBox(height: 4),
                const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    const Text('Delete Medication?', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Text(
                  'Are you sure you want to delete ${med.name}?\n\nThis will also cancel all alarms for this medication.',
                  style: const TextStyle(height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    content: Text('${med.name} deleted successfully'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Undo feature coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
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
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: const EdgeInsets.only(bottom: 16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_liquid,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                med.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C5F41),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${med.unit} • ${med.frequency}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAlarmEnabled && _alarmPermissionsGranted
                              ? Colors.green.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GestureDetector(
                          onTap: () => _toggleAlarms(med.id!, !isAlarmEnabled),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAlarmEnabled ? Icons.alarm : Icons.alarm_off,
                                size: 16,
                                color: isAlarmEnabled && _alarmPermissionsGranted
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAlarmEnabled ? 'Reminders On' : 'Reminders Off',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isAlarmEnabled && _alarmPermissionsGranted
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Daily Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(reminderCount, (i) {
                        final time = med.reminderTimes[i];
                        final dose = i < med.doses.length ? med.doses[i] : 'Unknown';
                        final taken = i < med.takenStatus.length ? med.takenStatus[i] : false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: taken
                                  ? [Colors.green.shade50, Colors.green.shade100]
                                  : [Colors.orange.shade50, Colors.orange.shade100],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: taken ? Colors.green.shade200 : Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: GestureDetector(
                              onTap: () => _toggleTakenStatus(index, i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: taken ? Colors.green.shade600 : Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  taken ? Icons.check : Icons.schedule,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.medication,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Dose: $dose',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: taken ? Colors.green.shade600 : Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                taken ? 'Taken' : 'Pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () => _toggleTakenStatus(index, i),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
