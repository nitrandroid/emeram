import '../models/song.dart';
import '../utils/slovak_sort.dart';
import '../screens/songs_screen.dart';

class SongFilterService {
  static List<Song> apply({
    required List<Song> songs,
    int? categoryId,
    String? author,
    String? arranger,
    String? language,
    required SongSortMode sortMode,
    required SortDirection sortDirection,
  }) {
    List<Song> list = [...songs];

    // FILTER
    if (categoryId != null) {
      list = list.where((s) => s.categoryId == categoryId).toList();
    }

    if (author != null) {
      list = list.where((s) => s.author == author).toList();
    }

    if (arranger != null) {
      list = list.where((s) => s.arranger == arranger).toList();
    }

    if (language != null) {
      list = list.where((s) => s.language == language).toList();
    }

    // SORT
    late final List<int Function(Song, Song)> chain;

    switch (sortMode) {
      case SongSortMode.title:
        chain = [compareTitle];
        break;
      case SongSortMode.author:
        chain = [compareAuthor, compareTitle];
        break;
      case SongSortMode.arranger:
        chain = [compareArranger, compareTitle];
        break;
      case SongSortMode.language:
        chain = [compareLanguage, compareTitle];
        break;
      case SongSortMode.firstRehearsal:
        chain = [compareFirstRehearsal, compareTitle];
        break;
      case SongSortMode.createdAt:
        chain = [compareCreatedAt];
        break;
    }

    int comparator(Song a, Song b) {
      final r = chainCompare(chain, a, b);
      return sortDirection == SortDirection.descending ? -r : r;
    }

    list.sort(comparator);
    return list;
  }
}
