import '../services/song_filter_service.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/song_category.dart';
import '../widgets/song_category_chip_filter.dart';
import 'song_category_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/songs_provider.dart';
import '../utils/slovak_sort.dart';
import '../data/database.dart';
import '../utils/song_sort.dart';
import '../widgets/add_edit_song_sheet.dart';
import '../providers/songs_actions_provider.dart';

// ===========================================================
// COMPARATORS
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
class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  List<SongCategory> categories = [];
  Map<int, SongCategory> categoryMap = {};
  Set<int> usedSongIds = {};

  int? selectedCategoryId;
  String? selectedAuthor;
  String? selectedArranger;
  String? selectedLanguage;

  SortDirection sortDirection = SortDirection.ascending;
  SongSortMode sortMode = SongSortMode.title;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = AppDatabase.instance;
    final cats = await db.fetchSongCategories();

    final usedRows = await (await db.database).query(
      'rehearsal_songs',
      columns: ['songId'],
    );

    setState(() {
      categories = cats;
      categoryMap = {for (var c in cats) c.id!: c};
      usedSongIds = usedRows.map((r) => r['songId'] as int).toSet();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // =======================================================
  // FILTER HELPERS (TERAZ BERÚ data)
  // =======================================================
  Set<String> _authors(List<Song> data) => data
      .where((s) => s.author != null && s.author!.trim().isNotEmpty)
      .map((s) => s.author!.trim())
      .toSet();

  Set<String> _arrangers(List<Song> data) => data
      .where((s) => s.arranger != null && s.arranger!.trim().isNotEmpty)
      .map((s) => s.arranger!.trim())
      .toSet();

  Set<String> _languages(List<Song> data) => data
      .where((s) => s.language != null && s.language!.trim().isNotEmpty)
      .map((s) => s.language!.trim())
      .toSet();

  List<Song> filteredSongs(List<Song> data) {
    return SongFilterService.apply(
      songs: data,
      categoryId: selectedCategoryId,
      author: selectedAuthor,
      arranger: selectedArranger,
      language: selectedLanguage,
      sortMode: sortMode,
      sortDirection: sortDirection,
    );
  }

  // =======================================================
  // UI
  // =======================================================
  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);

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
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SongCategoryManagerScreen(db: AppDatabase.instance),
                ),
              );
            },
          ),
        ],
      ),

      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text("Chyba")),
        data: (data) {
          final filtered = filteredSongs(data);

          final authors = _authors(data);
          final arrangers = _arrangers(data);
          final languages = _languages(data);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SongCategoryChipFilter(
                      categories: categories,
                      selectedId: selectedCategoryId,
                      onSelected: (id) {
                        setState(() => selectedCategoryId = id);
                      },
                    ),

                    if (authors.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("Všetci autori"),
                            selected: selectedAuthor == null,
                            onSelected: (_) =>
                                setState(() => selectedAuthor = null),
                          ),
                          ...authors.map(
                            (a) => ChoiceChip(
                              label: Text(a),
                              selected: selectedAuthor == a,
                              onSelected: (_) =>
                                  setState(() => selectedAuthor = a),
                            ),
                          ),
                        ],
                      ),

                    if (arrangers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("Všetci aranžéri"),
                            selected: selectedArranger == null,
                            onSelected: (_) =>
                                setState(() => selectedArranger = null),
                          ),
                          ...arrangers.map(
                            (a) => ChoiceChip(
                              label: Text(a),
                              selected: selectedArranger == a,
                              onSelected: (_) =>
                                  setState(() => selectedArranger = a),
                            ),
                          ),
                        ],
                      ),

                    if (languages.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("Všetky jazyky"),
                            selected: selectedLanguage == null,
                            onSelected: (_) =>
                                setState(() => selectedLanguage = null),
                          ),
                          ...languages.map(
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

              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text("Žiadne skladby"))
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final s = filtered[i];

                          final cat =
                              categoryMap[s.categoryId] ??
                              SongCategory(
                                id: 0,
                                name: "Nezaradené",
                                color: Colors.grey.toARGB32(),
                                songsCount: 0,
                                isDefault: false,
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
                            subtitle:
                                (s.author?.trim().isNotEmpty ?? false) ||
                                    (s.arranger?.trim().isNotEmpty ?? false)
                                ? Text(
                                    [
                                      if (s.author?.trim().isNotEmpty ?? false)
                                        s.author,
                                      if (s.arranger?.trim().isNotEmpty ??
                                          false)
                                        "arr. ${s.arranger}",
                                    ].join("; "),
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
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
                                            final actions = ref.read(
                                              songsActionsProvider,
                                            );
                                            await actions.update(updated);
                                            await _loadCategories();
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                if (!usedSongIds.contains(s.id))
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

                                        final used = await (await db.database)
                                            .query(
                                              'rehearsal_songs',
                                              where: 'songId = ?',
                                              whereArgs: [s.id],
                                            );

                                        if (used.isNotEmpty) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Skladbu nie je možné odstrániť — je použitá v skúške.",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final actions = ref.read(
                                          songsActionsProvider,
                                        );
                                        await actions.delete(s.id!);
                                        await _loadCategories();
                                      }
                                    },
                                  ),
                              ],
                            ),
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
                                      final actions = ref.read(
                                        songsActionsProvider,
                                      );
                                      await actions.update(updated);
                                      await _loadCategories();
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
