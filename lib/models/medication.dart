class Medication {
  final int? id; // For SQLite auto-increment ID
  final String name;
  final String unit;
  final String frequency; // e.g., "Once daily", "Twice daily"
  final List<String> reminderTimes; // e.g., ["08:00", "20:00"]
  final List<String> doses; // e.g., ["1 pill", "1 pill"]
  final List<bool> takenStatus; // For each reminder time
  late bool notificationsEnabled = true; // Default to true

  Medication({
    this.id,
    required this.name,
    required this.unit,
    required this.frequency,
    required this.reminderTimes,
    required this.doses,
    required this.takenStatus,
  });

  // Convert to Map<String, dynamic> for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'frequency': frequency,
      'reminderTimes': reminderTimes.join(','), // Store as CSV
      'doses': doses.join(','),
      'takenStatus': takenStatus.map((e) => e ? '1' : '0').join(','),
    };
  }

  // Convert back from SQLite Map with safe parsing
  factory Medication.fromMap(Map<String, dynamic> map) {
    String reminderTimesStr = map['reminderTimes']?.toString() ?? '';
    String dosesStr = map['doses']?.toString() ?? '';
    String takenStatusStr = map['takenStatus']?.toString() ?? '';

    List<String> parseCsvString(String str) {
      if (str.isEmpty) return <String>[];
      return str.split(',');
    }

    List<bool> parseTakenStatus(String str) {
      if (str.isEmpty) return <bool>[];
      return str.split(',').map((e) => e == '1').toList();
    }

    return Medication(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      frequency: map['frequency']?.toString() ?? '',
      reminderTimes: parseCsvString(reminderTimesStr),
      doses: parseCsvString(dosesStr),
      takenStatus: parseTakenStatus(takenStatusStr),
    );
  }

  // Optional: copyWith method for easier updates
  Medication copyWith({
    int? id,
    String? name,
    String? unit,
    String? frequency,
    List<String>? reminderTimes,
    List<String>? doses,
    List<bool>? takenStatus,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      doses: doses ?? this.doses,
      takenStatus: takenStatus ?? this.takenStatus,
    );
  }
}
