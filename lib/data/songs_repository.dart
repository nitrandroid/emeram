import 'database.dart';
import '../models/song.dart';
import '../models/song_category.dart';

class SongsRepository {
  final db = AppDatabase.instance;

  Future<List<Song>> fetchSongs() {
    return db.fetchSongs();
  }

  Future<List<SongCategory>> fetchCategories() {
    return db.fetchSongCategories();
  }

  Future<void> addSong(Song song) async {
    await db.addSong(song);
  }

  Future<void> updateSong(Song song) async {
    await db.updateSong(song);
  }

  Future<void> deleteSong(int id) async {
    await db.deleteSong(id);
  }
}