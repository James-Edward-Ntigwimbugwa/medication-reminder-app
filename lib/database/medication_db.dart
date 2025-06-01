import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';

class MedicationDB {
  static final MedicationDB instance = MedicationDB._init();

  static Database? _database;

  MedicationDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medications.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        frequency TEXT NOT NULL,
        reminderTimes TEXT NOT NULL,
        doses TEXT NOT NULL,
        takenStatus TEXT NOT NULL,
        notificationsEnabled INTEGER DEFAULT 1
      )
    ''');
  }

  Future<int> createMedication(Medication med) async {
    final db = await instance.database;
    final id = await db.insert('medications', med.toMap());

    // Schedule notifications for the new medication
    final medicationWithId = med.copyWith(id: id);
    await NotificationService.scheduleMedicationReminders(medicationWithId);

    return id;
  }

  Future<List<Medication>> readAllMedications() async {
    final db = await instance.database;
    final result = await db.query('medications');

    return result.map((map) => Medication.fromMap(map)).toList();
  }

  Future<int> updateMedication(Medication med) async {
    final db = await instance.database;
    final result = await db.update(
      'medications',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
    );

    // Reschedule notifications for the updated medication
    if (med.id != null) {
      await NotificationService.scheduleMedicationReminders(med);
    }

    return result;
  }

  Future<int> deleteMedication(int id) async {
    final db = await instance.database;

    // Cancel notifications before deleting
    await NotificationService.cancelMedicationReminders(id);

    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleNotifications(int medicationId, bool enabled) async {
    final db = await instance.database;
    await db.update(
      'medications',
      {'notificationsEnabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [medicationId],
    );

    if (enabled) {
      // Re-enable notifications
      final result = await db.query('medications', where: 'id = ?', whereArgs: [medicationId]);
      if (result.isNotEmpty) {
        final medication = Medication.fromMap(result.first);
        await NotificationService.scheduleMedicationReminders(medication);
      }
    } else {
      // Disable notifications
      await NotificationService.cancelMedicationReminders(medicationId);
    }
  }

  // Reschedule all medication notifications (useful after app restart)
  Future<void> rescheduleAllNotifications() async {
    final medications = await readAllMedications();
    for (final medication in medications) {
      if (medication.id != null) {
        await NotificationService.scheduleMedicationReminders(medication);
      }
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}