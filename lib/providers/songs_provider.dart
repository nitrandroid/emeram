import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/songs_repository.dart';
import '../models/song.dart';

final songsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = SongsRepository();
  return repo.fetchSongs();
});