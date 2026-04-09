// lib/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});