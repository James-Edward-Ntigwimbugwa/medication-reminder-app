import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';

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
        takenStatus TEXT NOT NULL
      )
    ''');
  }

  Future<int> createMedication(Medication med) async {
    final db = await instance.database;
    return await db.insert('medications', med.toMap());
  }

  Future<List<Medication>> readAllMedications() async {
    final db = await instance.database;
    final result = await db.query('medications');

    return result.map((map) => Medication.fromMap(map)).toList();
  }

  Future<int> updateMedication(Medication med) async {
    final db = await instance.database;
    return await db.update(
      'medications',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await instance.database;
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
