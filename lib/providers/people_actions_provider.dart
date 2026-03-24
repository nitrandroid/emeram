import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/person.dart';
import 'people_provider.dart';

final peopleActionsProvider = Provider((ref) {
  final db = AppDatabase.instance;

  return (
    add: (Person p) async {
      await db.addPerson(p);
      ref.invalidate(peopleProvider);
    },
    update: (Person p) async {
      await db.updatePerson(p);
      ref.invalidate(peopleProvider);
    },
    delete: (int id) async {
      await db.deletePerson(id);
      ref.invalidate(peopleProvider);
    },
  );
});