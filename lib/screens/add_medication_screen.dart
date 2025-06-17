import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';
import '../widgets/glass_clock_widget.dart';
import '../widgets/custom_glass_time_picker.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final List<TimeOfDay> _reminderTimes = [];
  String _selectedFrequency = 'Once Daily';

  static const Color forestGreen = Color(0xFF228B22);

  final List<String> _frequencies = [
    'Once Daily',
    'Twice Daily',
    'Three Times Daily',
    'Custom',
  ];

  void _updateReminderSlots(String frequency) {
    setState(() {
      _reminderTimes.clear();
      int count = _getRequiredReminderCount(frequency);
      for (int i = 0; i < count; i++) {
        _reminderTimes.add(const TimeOfDay(hour: 8, minute: 0));
      }
    });
  }

  void _addReminderTime() async {
    if (_selectedFrequency != 'Custom' &&
        _reminderTimes.length >=
            _getRequiredReminderCount(_selectedFrequency)) {
      return;
    }

    TimeOfDay? picked = await showCustomTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && context.mounted) {
      setState(() {
        _reminderTimes.add(picked);
      });
    }
  }

  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  void _saveMedication() async {
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();

    if (name.isEmpty || unit.isEmpty || _reminderTimes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete all fields")),
        );
      }
      return;
    }

    final reminderTimesStrings =
        _reminderTimes.map((t) {
          return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        }).toList();

    final newMedication = Medication(
      name: name,
      unit: unit,
      frequency: _selectedFrequency,
      reminderTimes: reminderTimesStrings,
      doses: List.filled(_reminderTimes.length, ''),
      takenStatus: List.filled(_reminderTimes.length, false),
    );

    try {
      await MedicationDB.instance.createMedication(newMedication);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medication saved successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving medication: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save medication")),
        );
      }
    }
  }

  int _getRequiredReminderCount(String frequency) {
    switch (frequency) {
      case 'Once Daily':
        return 1;
      case 'Twice Daily':
        return 2;
      case 'Three Times Daily':
        return 3;
      default:
        return _reminderTimes.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveMedication,
        backgroundColor: forestGreen,
        icon: const Icon(Icons.save_alt, color: Colors.white),
        label: const Text(
          "Save Medication",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Current Time",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const GlassClockWidget(
                        size: 200,
                        glassColor: forestGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Set your medication reminders",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              _buildFormCard([
                _buildFormField(
                  "Medication Name",
                  _nameController,
                  "e.g. Amoxicillin",
                  Icons.medication,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  "Unit (mg/ml/tablets)",
                  _unitController,
                  "e.g. 500mg",
                  Icons.balance,
                ),
              ]),
              const SizedBox(height: 16),
              _buildFormCard([
                const Text(
                  "Frequency",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items:
                        _frequencies.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFrequency = value;
                          _updateReminderSlots(value);
                        });
                      }
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _buildFormCard([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Reminder Times",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: forestGreen,
                      ),
                    ),
                    if (_selectedFrequency == 'Custom' ||
                        _reminderTimes.length <
                            _getRequiredReminderCount(_selectedFrequency))
                      ElevatedButton.icon(
                        onPressed: _addReminderTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: forestGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.alarm_add, size: 18),
                        label: const Text("Add Time"),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_reminderTimes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Text(
                        "No reminder times set",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._reminderTimes.asMap().entries.map((entry) {
                    int index = entry.key;
                    TimeOfDay time = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: forestGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: forestGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.schedule, color: forestGreen),
                        title: Text(
                          "Reminder ${index + 1}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          time.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: forestGreen,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeReminderTime(index),
                        ),
                      ),
                    );
                  }),
              ]),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: forestGreen,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: forestGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: forestGreen),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}
