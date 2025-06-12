// medication_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../services/alarm_service.dart';

class MedicationDB {
  static final MedicationDB instance = MedicationDB._init();
  static Database? _database;

  MedicationDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
        notificationsEnabled TEXT NOT NULL
      )
    ''');
  }

  Future<Medication> createMedication(Medication medication) async {
    final db = await instance.database;
    final id = await db.insert('medications', medication.toMap());
    return medication.copyWith(id: id);
  }

  Future<Medication> readMedication(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'medications',
      columns: MedicationFields.values,
      where: '${MedicationFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Medication>> readAllMedications() async {
    final db = await instance.database;
    final result = await db.query('medications');
    return result.map((json) => Medication.fromMap(json)).toList();
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await instance.database;
    return db.update(
      'medications',
      medication.toMap(),
      where: '${MedicationFields.id} = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await instance.database;
    return await db.delete(
      'medications',
      where: '${MedicationFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleNotifications(int medicationId, bool enabled) async {
    final medication = await readMedication(medicationId);
    final updated = medication.copyWith(notificationsEnabled: enabled);
    return await updateMedication(updated);
  }

  Future<void> rescheduleAllAlarms() async {
    final medications = await readAllMedications();
    for (final medication in medications) {
      if (medication.notificationsEnabled) {
        await AlarmService.scheduleMedicationAlarms(medication);
      }
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

class MedicationFields {
  static final List<String> values = [
    id,
    name,
    unit,
    frequency,
    reminderTimes,
    doses,
    takenStatus,
    notificationsEnabled,
  ];

  static const String id = 'id';
  static const String name = 'name';
  static const String unit = 'unit';
  static const String frequency = 'frequency';
  static const String reminderTimes = 'reminderTimes';
  static const String doses = 'doses';
  static const String takenStatus = 'takenStatus';
  static const String notificationsEnabled = 'notificationsEnabled';
}