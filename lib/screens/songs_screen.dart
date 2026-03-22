import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/song.dart';
import '../models/song_category.dart';
import '../widgets/song_category_chip_filter.dart';
import '../widgets/add_edit_song_sheet.dart';
import 'song_category_screen.dart';

// 🔥 nové jednotné triedenie
import '../utils/slovak_sort.dart';

// ===========================================================
// SORT MODES FOR SONGS
// ===========================================================
enum SongSortMode {
  title,
  author,
  arranger,
  language,
  firstRehearsal,
  createdAt,
}

enum SortDirection { ascending, descending }

// ===========================================================
// SONG COMPARATORS (používajú slovakCompare zo slovak_sort.dart)
// ===========================================================
int compareTitle(Song a, Song b) => slovakCompare(a.title, b.title);

int compareAuthor(Song a, Song b) =>
    slovakCompare(a.author ?? "", b.author ?? "");

int compareArranger(Song a, Song b) =>
    slovakCompare(a.arranger ?? "", b.arranger ?? "");

int compareLanguage(Song a, Song b) =>
    slovakCompare(a.language ?? "", b.language ?? "");

int compareFirstRehearsal(Song a, Song b) =>
    (a.firstRehearsalDate ?? DateTime(1900)).compareTo(
      b.firstRehearsalDate ?? DateTime(1900),
    );

int compareCreatedAt(Song a, Song b) => a.createdAt.compareTo(b.createdAt);

// ===========================================================
// SCREEN
// ===========================================================
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<Song> songs = [];
  List<SongCategory> categories = [];

  int? selectedCategoryId;
  String? selectedAuthor;
  String? selectedArranger;
  String? selectedLanguage;

  SortDirection sortDirection = SortDirection.ascending;
  SongSortMode sortMode = SongSortMode.title;

  bool loading = true;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final db = AppDatabase.instance;
    final cats = await db.fetchSongCategories();
    final sngs = await db.fetchSongs();

    if (!mounted) return;

    setState(() {
      categories = cats;
      songs = sngs;
      loading = false;
    });
  }

  // AUTHORS collected dynamically
  Set<String> get _authors => songs
      .where((s) => s.author != null && s.author!.trim().isNotEmpty)
      .map((s) => s.author!.trim())
      .toSet();

  Set<String> get _arrangers => songs
      .where((s) => s.arranger != null && s.arranger!.trim().isNotEmpty)
      .map((s) => s.arranger!.trim())
      .toSet();

  Set<String> get _languages => songs
      .where((s) => s.language != null && s.language!.trim().isNotEmpty)
      .map((s) => s.language!.trim())
      .toSet();

  // =======================================================
  // FILTER & SORT
  // =======================================================
  List<Song> get filteredSongs {
    List<Song> list = [...songs];

    // Category
    if (selectedCategoryId != null) {
      list = list.where((s) => s.categoryId == selectedCategoryId).toList();
    }

    // Author
    if (selectedAuthor != null) {
      list = list.where((s) => s.author == selectedAuthor).toList();
    }

    // Arranger
    if (selectedArranger != null) {
      list = list.where((s) => s.arranger == selectedArranger).toList();
    }

    // Language
    if (selectedLanguage != null) {
      list = list.where((s) => s.language == selectedLanguage).toList();
    }

    // Sorting chain
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
      final r = chainCompare(chain, a, b); // 🔥 z utils/slovak_sort.dart
      return sortDirection == SortDirection.descending ? -r : r;
    }

    list.sort(comparator);
    return list;
  }

  // =======================================================
  // UI
  // =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skladby"),
        actions: [
          PopupMenuButton<SongSortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => sortMode = v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: SongSortMode.title, child: Text("Názov")),
              PopupMenuItem(value: SongSortMode.author, child: Text("Autor")),
              PopupMenuItem(
                value: SongSortMode.arranger,
                child: Text("Aranžér"),
              ),
              PopupMenuItem(value: SongSortMode.language, child: Text("Jazyk")),
              PopupMenuItem(
                value: SongSortMode.firstRehearsal,
                child: Text("Dátum prvej skúšky"),
              ),
              PopupMenuItem(
                value: SongSortMode.createdAt,
                child: Text("Dátum pridania"),
              ),
            ],
          ),

          // ASC/DESC
          IconButton(
            tooltip: sortDirection == SortDirection.ascending
                ? "Zoradiť zostupne"
                : "Zoradiť vzostupne",
            icon: Icon(
              sortDirection == SortDirection.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
            onPressed: () {
              setState(() {
                sortDirection = sortDirection == SortDirection.ascending
                    ? SortDirection.descending
                    : SortDirection.ascending;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: "Správa kategórií skladieb",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SongCategoryManagerScreen(),
                ),
              ).then((_) => _loadAll()); // refresh po návrate
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) {
              return AddEditSongSheet(
                categories: categories,
                onSubmit: (song) async {
                  final db = AppDatabase.instance;
                  await db.addSong(song);
                  await _loadAll();
                },
              );
            },
          );
        },
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // =========================================
                // FILTERS
                // =========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CATEGORY
                      SongCategoryChipFilter(
                        categories: categories,
                        selectedId: selectedCategoryId,
                        onSelected: (id) {
                          setState(() => selectedCategoryId = id);
                        },
                      ),
                      const SizedBox(height: 12),

                      // AUTHOR FILTER
                      if (_authors.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text("Všetci autori"),
                              selected: selectedAuthor == null,
                              onSelected: (_) =>
                                  setState(() => selectedAuthor = null),
                            ),
                            ..._authors.map(
                              (a) => ChoiceChip(
                                label: Text(a),
                                selected: selectedAuthor == a,
                                onSelected: (_) =>
                                    setState(() => selectedAuthor = a),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // ARRANGER FILTER
                      if (_arrangers.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text("Všetci aranžéri"),
                              selected: selectedArranger == null,
                              onSelected: (_) =>
                                  setState(() => selectedArranger = null),
                            ),
                            ..._arrangers.map(
                              (a) => ChoiceChip(
                                label: Text(a),
                                selected: selectedArranger == a,
                                onSelected: (_) =>
                                    setState(() => selectedArranger = a),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // LANGUAGE FILTER
                      if (_languages.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text("Všetky jazyky"),
                              selected: selectedLanguage == null,
                              onSelected: (_) =>
                                  setState(() => selectedLanguage = null),
                            ),
                            ..._languages.map(
                              (l) => ChoiceChip(
                                label: Text(l),
                                selected: selectedLanguage == l,
                                onSelected: (_) =>
                                    setState(() => selectedLanguage = l),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // =========================================
                // SONG LIST
                // =========================================
                Expanded(
                  child: filteredSongs.isEmpty
                      ? const Center(child: Text("Žiadne skladby"))
                      : ListView.builder(
                          controller: _scroll,
                          itemCount: filteredSongs.length,
                          itemBuilder: (ctx, i) {
                            final s = filteredSongs[i];

                            final cat = categories.firstWhere(
                              (c) => c.id == s.categoryId,
                              orElse: () => SongCategory(
                                id: 0,
                                name: "Nezaradené",
                                color: Colors.grey.toARGB32(),
                                songsCount: 0,
                                isDefault: false,
                              ),
                            );

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(cat.color),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                ),
                              ),

                              title: Text(s.title),

                              subtitle: Text(
                                [
                                  if (s.author != null &&
                                      s.author!.trim().isNotEmpty)
                                    "Autor: ${s.author}",
                                  if (s.arranger != null &&
                                      s.arranger!.trim().isNotEmpty)
                                    "Aranžér: ${s.arranger}",
                                  if (s.language != null &&
                                      s.language!.trim().isNotEmpty)
                                    "Jazyk: ${s.language}",
                                  if (s.firstRehearsalDate != null)
                                    "1. skúška: ${s.firstRehearsalDate!.toLocal().toString().split(' ')[0]}",
                                ].join("   •   "),
                              ),

                              // 🔥 EDIT po kliknutí na celý riadok
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) {
                                    return AddEditSongSheet(
                                      categories: categories,
                                      existing: s,
                                      onSubmit: (updated) async {
                                        final db = AppDatabase.instance;
                                        await db.updateSong(updated);
                                        await _loadAll();
                                      },
                                    );
                                  },
                                );
                              },

                              // 🔥 EDIT + DELETE BUTTONS
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        builder: (_) {
                                          return AddEditSongSheet(
                                            categories: categories,
                                            existing: s,
                                            onSubmit: (updated) async {
                                              final db = AppDatabase.instance;
                                              await db.updateSong(updated);
                                              await _loadAll();
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Zmazať skladbu"),
                                          content: Text(
                                            'Naozaj chceš zmazať skladbu "${s.title}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Zrušiť"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Zmazať"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        final db = AppDatabase.instance;
                                        await db.deleteSong(s.id!);
                                        await _loadAll();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
