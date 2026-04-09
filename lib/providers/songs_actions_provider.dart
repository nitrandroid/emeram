// lib/providers/songs_actions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/song.dart';
import 'songs_provider.dart';

final songsActionsProvider = Provider((ref) {
  final db = AppDatabase.instance;

  return (
    add: (Song s) async {
      await db.addSong(s);
      ref.invalidate(songsProvider);
    },
    update: (Song s) async {
      await db.updateSong(s);
      ref.invalidate(songsProvider);
    },
    delete: (int id) async {
      await db.deleteSong(id);
      ref.invalidate(songsProvider);
    },
  );
});