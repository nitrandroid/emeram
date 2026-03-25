// lib/models/gig.dart
import 'package:flutter/material.dart';

class Gig {
  final int? id;
  final DateTime date;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;
  final String place;
  final DateTime createdAt;

  Gig({
    this.id,
    required this.date,
    required this.fromTime,
    required this.toTime,
    required this.place,
    required this.createdAt,
  });

  Gig copyWith({
    int? id,
    DateTime? date,
    TimeOfDay? fromTime,
    TimeOfDay? toTime,
    String? place,
    DateTime? createdAt,
  }) {
    return Gig(
      id: id ?? this.id,
      date: date ?? this.date,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      place: place ?? this.place,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Gig.fromMap(Map<String, dynamic> map) {
    return Gig(
      id: map['id'] as int?,
      date: DateTime.parse(map['date']),
      fromTime: _parseTime(map['fromTime']),
      toTime: _parseTime(map['toTime']),
      place: map['place'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  static TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}