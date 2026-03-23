import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'database_provider.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  ref.keepAlive();
  return db.fetchCategories();
});