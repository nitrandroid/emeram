// lib/providers/gigs_actions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/gig.dart';

final gigsActionsProvider = Provider((ref) {
  final db = AppDatabase.instance;

  return (
    add: (Gig g) async {
      await db.addGig(g);
    },
    update: (Gig g) async {
      await db.updateGig(g);
    },
    delete: (int id) async {
      await db.deleteGig(id);
    },
  );
});