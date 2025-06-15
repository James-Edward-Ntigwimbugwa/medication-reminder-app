// medication.dart
class Medication {
  final int? id;
  final String name;
  final String unit;
  final String frequency;
  final List<String> reminderTimes;
  final List<String> doses;
  final List<bool> takenStatus;
  bool notificationsEnabled;

  Medication({
    this.id,
    required this.name,
    required this.unit,
    required this.frequency,
    required this.reminderTimes,
    required this.doses,
    required this.takenStatus,
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'frequency': frequency,
      'reminderTimes': reminderTimes.join(','),
      'doses': doses.join(','),
      'takenStatus': takenStatus.map((e) => e ? '1' : '0').join(','),
      'notificationsEnabled': notificationsEnabled ? '1' : '0',
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    String reminderTimesStr = map['reminderTimes']?.toString() ?? '';
    String dosesStr = map['doses']?.toString() ?? '';
    String takenStatusStr = map['takenStatus']?.toString() ?? '';
    String notificationsEnabledStr =
        map['notificationsEnabled']?.toString() ?? '1';

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
      notificationsEnabled: notificationsEnabledStr == '1',
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? unit,
    String? frequency,
    List<String>? reminderTimes,
    List<String>? doses,
    List<bool>? takenStatus,
    bool? notificationsEnabled,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      doses: doses ?? this.doses,
      takenStatus: takenStatus ?? this.takenStatus,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
