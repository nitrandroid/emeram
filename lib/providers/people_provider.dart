// lib/providers/people_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/person.dart';
import 'database_provider.dart';

final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  ref.keepAlive();
  return db.fetchPersons();
});