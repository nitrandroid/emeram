// lib/models/rehearsal.dart

class Rehearsal {
  final int? id;
  final DateTime date; // dátum skúšky

  /// čas vo formáte HH:MM (24h, zero-padded)
  final String fromTime;
  final String toTime;

  final String place;
  final DateTime createdAt;

  Rehearsal({
    this.id,
    required this.date,
    required this.fromTime,
    required this.toTime,
    required this.place,
    required this.createdAt,
  });

  Rehearsal copyWith({
    int? id,
    DateTime? date,
    String? fromTime,
    String? toTime,
    String? place,
    DateTime? createdAt,
  }) {
    return Rehearsal(
      id: id ?? this.id,
      date: date ?? this.date,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      place: place ?? this.place,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Rehearsal.fromMap(Map<String, dynamic> map) {
    return Rehearsal(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      fromTime: _normalizeTime(map['fromTime'] as String),
      toTime: _normalizeTime(map['toTime'] as String),
      place: map['place'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date.toIso8601String(),
      'fromTime': fromTime,
      'toTime': toTime,
      'place': place,
      'createdAt': createdAt.toIso8601String(),
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// zabezpečí formát HH:MM
  static String _normalizeTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $value');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
