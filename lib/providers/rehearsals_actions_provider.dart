// lib/providers/rehearsals_actions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/rehearsal.dart';

final rehearsalsActionsProvider = Provider((ref) {
  final db = AppDatabase.instance;

  return (
    add: (Rehearsal r) async {
      await db.addRehearsal(r);
    },
    update: (Rehearsal r) async {
      await db.updateRehearsal(r);
    },
    delete: (int id) async {
      await db.deleteRehearsal(id);
    },
  );
});
