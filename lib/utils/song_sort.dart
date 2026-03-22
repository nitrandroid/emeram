// lib/utils/song_sort.dart

import '../models/song.dart';
import 'slovak_sort.dart';

enum SongSortMode {
  title,
  author,
  arranger,
  language,
  firstRehearsal,
  createdAt,
}

enum SortDirection { ascending, descending }

int compareTitle(Song a, Song b) => slovakCompare(a.title, b.title);
int compareAuthor(Song a, Song b) =>
    slovakCompare(a.author ?? "", b.author ?? "");
int compareArranger(Song a, Song b) =>
    slovakCompare(a.arranger ?? "", b.arranger ?? "");
int compareLanguage(Song a, Song b) =>
    slovakCompare(a.language ?? "", b.language ?? "");
int compareFirstRehearsal(Song a, Song b) =>
    (a.firstRehearsalDate ?? DateTime(1900))
        .compareTo(b.firstRehearsalDate ?? DateTime(1900));
int compareCreatedAt(Song a, Song b) =>
    a.createdAt.compareTo(b.createdAt);
