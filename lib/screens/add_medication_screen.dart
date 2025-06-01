// File: lib/screens/add_medication_screen.dart

import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';

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

  final List<String> _frequencies = [
    'Once Daily',
    'Twice Daily',
    'Three Times Daily',
    'Custom',
  ];

  void _updateReminderSlots(String frequency) {
    setState(() {
      _reminderTimes.clear(); // Instead of _reminderTimes = [];
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
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final newMedication = Medication(
      name: name,
      unit: unit,
      frequency: _selectedFrequency,
      reminderTimes: _reminderTimes.map((t) => t.format(context)).toList(),
      doses: List.filled(_reminderTimes.length, ''),
      takenStatus: List.filled(_reminderTimes.length, false),
    );

    try {
      await MedicationDB.instance.createMedication(newMedication);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medication saved successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error saving medication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save medication")),
      );
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
      appBar: AppBar(
        title: const Text('Add Medication'),
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
        icon: const Icon(Icons.save_alt),
        label: const Text("Save Medication"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Medication Name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: "e.g. Amoxicillin"),
              ),
              const SizedBox(height: 16),
              const Text(
                "Unit (mg/ml/tablets)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _unitController,
                decoration: const InputDecoration(hintText: "e.g. 500mg"),
              ),
              const SizedBox(height: 16),
              const Text(
                "Frequency",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedFrequency,
                isExpanded: true,
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
              const SizedBox(height: 16),
              if (_selectedFrequency == 'Custom' ||
                  _reminderTimes.length <
                      _getRequiredReminderCount(_selectedFrequency))
                ElevatedButton.icon(
                  onPressed: _addReminderTime,
                  icon: const Icon(Icons.alarm_add),
                  label: const Text("Add Reminder Time"),
                ),
              const SizedBox(height: 8),
              ..._reminderTimes.asMap().entries.map((entry) {
                int index = entry.key;
                TimeOfDay time = entry.value;
                return ListTile(
                  title: Text("Reminder ${index + 1}: ${time.format(context)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeReminderTime(index),
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
