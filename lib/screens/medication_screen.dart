import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../database/medication_db.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  _MedicationScreenState createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _fetchMedications();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medications')),
      body:
          _medications.isEmpty
              ? const Center(child: Text('No medications yet'))
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
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Delete Medication?'),
                              content: const Text(
                                'Are you sure you want to delete this medication?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );
                    },
                    onDismissed: (_) async {
                      await MedicationDB.instance.deleteMedication(med.id!);
                      _medications.removeAt(index);
                      setState(() {});
                    },
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 4,
                      child: ExpansionTile(
                        title: Text('${med.name} (${med.unit})'),
                        subtitle: Text(med.frequency),
                        children: List.generate(reminderCount, (i) {
                          final time = med.reminderTimes[i];
                          final dose =
                              i < med.doses.length ? med.doses[i] : 'Unknown';
                          final taken =
                              i < med.takenStatus.length
                                  ? med.takenStatus[i]
                                  : false;

                          return ListTile(
                            leading: Icon(
                              taken
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: taken ? Colors.green : Colors.red,
                            ),
                            title: Text('Time: $time | Dose: $dose'),
                            trailing: Text(taken ? 'Taken' : 'Pending'),
                            onTap: () => _toggleTakenStatus(index, i),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
