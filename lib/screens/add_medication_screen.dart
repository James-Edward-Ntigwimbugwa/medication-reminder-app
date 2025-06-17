// Imports necessary packages for Flutter UI, state management, and app-specific models/widgets.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';
import '../widgets/glass_clock_widget.dart';
import '../widgets/custom_glass_time_picker.dart';

// Stateless widget serving as the entry point for the Add Medication screen.
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  // Creates the state object for this widget.
  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

// State class managing user input and UI state for AddMedicationScreen.
class _AddMedicationScreenState extends State<AddMedicationScreen> {
  // Controller for the medication name input field.
  final TextEditingController _nameController = TextEditingController();

  // List storing selected reminder times for the medication.
  final List<TimeOfDay> _reminderTimes = [];

  // Default frequency for medication reminders.
  String _selectedFrequency = 'Once Daily';

  // Default unit for medication dosage.
  String _selectedUnit = 'pills';

  // Constant color for consistent theming throughout the app.
  static const Color forestGreen = Color(0xFF228B22);

  // Predefined frequency options for medication reminders.
  final List<String> _frequencies = [
    'Once Daily',
    'Twice Daily',
    'Three Times Daily',
    'Custom',
  ];

  // Predefined unit options for medication dosage.
  final List<String> _units = [
    'pills',
    'tablets',
    'capsules',
    'mg',
    'ml',
    'drops',
    'sprays',
    'patches',
    'injections',
    'grams',
    'teaspoons',
    'tablespoons',
  ];

  // Updates reminder time slots based on selected frequency.
  void _updateReminderSlots(String frequency) {
    setState(() {
      _reminderTimes.clear();
      int count = _getRequiredReminderCount(frequency);
      for (int i = 0; i < count; i++) {
        _reminderTimes.add(const TimeOfDay(hour: 8, minute: 0));
      }
    });
  }

  // Adds a new reminder time using a custom time picker dialog.
  void _addReminderTime() async {
    // Restricts adding times beyond limit for non-custom frequencies.
    if (_selectedFrequency != 'Custom' &&
        _reminderTimes.length >= _getRequiredReminderCount(_selectedFrequency)) {
      return;
    }

    // Displays custom time picker and awaits user selection.
    TimeOfDay? picked = await showCustomTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    // Adds selected time to reminders if valid and widget is mounted.
    if (picked != null && mounted) {
      setState(() {
        _reminderTimes.add(picked);
      });
    }
  }

  // Removes a reminder time at the specified index.
  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  // Saves medication details to the database and navigates back.
  void _saveMedication() async {
    final name = _nameController.text.trim();

    // Validates required fields are completed.
    if (name.isEmpty || _reminderTimes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete all fields")),
        );
      }
      return;
    }

    // Converts TimeOfDay objects to string format (HH:mm).
    final reminderTimesStrings = _reminderTimes.map((t) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }).toList();

    // Creates a new Medication object with user inputs.
    final newMedication = Medication(
      name: name,
      unit: _selectedUnit,
      frequency: _selectedFrequency,
      reminderTimes: reminderTimesStrings,
      doses: List.filled(_reminderTimes.length, ''),
      takenStatus: List.filled(_reminderTimes.length, false),
    );

    try {
      // Persists medication to the database.
      await MedicationDB.instance.createMedication(newMedication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medication saved successfully")),
        );
        Navigator.pop(context); // Returns to previous screen.
      }
    } catch (e) {
      // Logs error in debug mode for troubleshooting.
      if (kDebugMode) {
        print('Error saving medication: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save medication")),
        );
      }
    }
  }

  // Determines required number of reminder times for a given frequency.
  int _getRequiredReminderCount(String frequency) {
    switch (frequency) {
      case 'Once Daily':
        return 1;
      case 'Twice Daily':
        return 2;
      case 'Three Times Daily':
        return 3;
      default:
        return _reminderTimes.length; // Custom allows variable count.
    }
  }

  // Constructs the UI for the Add Medication screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Alice Blue for clean, medical aesthetic.
      appBar: AppBar(
        elevation: 0, // Removes shadow for a flat, modern look.
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 237, 238, 238), // Light gray for subtle contrast.
                Color.fromARGB(255, 11, 117, 216), // Blue for professional appearance.
              ],
            ),
          ),
        ),
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
                Icons.add_circle,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Medication',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C5F41), // Dark green for emphasis.
              ),
            ),
          ],
        ),
        actions: [
          // Settings button navigating to the settings screen.
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.blue.shade700),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color.fromARGB(255, 87, 133, 168), Colors.blue.shade600],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 61, 117, 167).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _saveMedication,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.save_alt, color: Colors.white),
          label: const Text(
            "Save Medication",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Container(
        // Gradient background consistent with MedicationScreen for visual harmony.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8FF), // Alice Blue - Clean medical feel.
              Color(0xFFE6F3FF), // Light Sky Blue.
              Color(0xFFF5F9FF), // Very Light Blue.
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section displaying current time and reminder prompt.
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                            color: Color(0xFF2C5F41),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Custom widget displaying a stylized clock.
                        GlassClockWidget(
                          size: 200,
                          glassColor: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Set your medication reminders",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Form card for medication name and unit input.
                _buildFormCard([
                  _buildFormField(
                    "Medication Name",
                    _nameController,
                    "e.g. Amoxicillin",
                    Icons.medication,
                  ),
                  const SizedBox(height: 16),
                  _buildUnitDropdown(),
                ]),
                const SizedBox(height: 16),
                // Form card for selecting medication frequency.
                _buildFormCard([
                  const Text(
                    "Frequency",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2C5F41),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFrequency,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: _frequencies.map((String value) {
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
                // Form card for managing reminder times.
                _buildFormCard([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Reminder Times",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2C5F41),
                        ),
                      ),
                      // Button to add reminder time, shown when permitted.
                      if (_selectedFrequency == 'Custom' ||
                          _reminderTimes.length <
                              _getRequiredReminderCount(_selectedFrequency))
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade600.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _addReminderTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.alarm_add, size: 18),
                            label: const Text(
                              "Add Time",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Placeholder when no reminder times are set.
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
                    // Lists all reminder times with delete option.
                    ..._reminderTimes.asMap().entries.map((entry) {
                      int index = entry.key;
                      TimeOfDay time = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.schedule,
                            color: Colors.blue.shade600,
                          ),
                          title: Text(
                            "Reminder ${index + 1}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            time.format(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
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
                const SizedBox(height: 100), // Ensures FAB doesn't overlap content.
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Creates a styled card to group form elements.
  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Constructs a text input field with consistent styling.
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
            color: Color(0xFF2C5F41),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(icon, color: Colors.blue.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Builds a dropdown menu for selecting medication units.
  Widget _buildUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Unit",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2C5F41),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.balance, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text(
                    "Select unit",
                    style: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _units.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnit = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}