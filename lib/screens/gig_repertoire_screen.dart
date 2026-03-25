// lib/screens/gig_repertoire_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/gig.dart';
import '../models/song.dart';
import '../models/song_category.dart';

class GigRepertoireScreen extends ConsumerStatefulWidget {
  final Gig gig;

  const GigRepertoireScreen({super.key, required this.gig});

  @override
  ConsumerState<GigRepertoireScreen> createState() =>
      _GigRepertoireScreenState();
}

class _GigRepertoireScreenState extends ConsumerState<GigRepertoireScreen> {
  List<Song> songs = [];
  List<SongCategory> categories = [];
  Set<int> selected = {};
  Set<int> originalSelected = {};
  bool loading = true;

  bool get hasChanges =>
      !(selected.length == originalSelected.length &&
          selected.containsAll(originalSelected) &&
          originalSelected.containsAll(selected));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);

    final allSongs = await db.fetchSongs();
    final allCats = await db.fetchSongCategories();
    final gSongs = await db.fetchGigSongIds(widget.gig.id!);

    setState(() {
      songs = allSongs;
      categories = allCats;
      selected = {...gSongs};
      originalSelected = {...gSongs};
      loading = false;
    });
  }

  void _toggle(Song s, bool value) {
    setState(() {
      if (value) {
        selected.add(s.id!);
      } else {
        selected.remove(s.id!);
      }
    });
  }

  Future<void> _save() async {
    final db = ref.read(appDatabaseProvider);

    await db.replaceGigSongs(widget.gig.id!, selected);

    setState(() {
      originalSelected = {...selected};
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Repertoár uložený.")));
  }

  Future<void> _handleSaveOrClose() async {
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Uložiť repertoár?"),
        content: const Text("Chystáte sa uložiť zmeny repertoáru."),
        actions: [
          TextButton(
            child: const Text("Zrušiť"),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: const Text("Uložiť"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gig;

    return Scaffold(
      appBar: AppBar(
        title: Text("Repertoár – ${g.date.day}.${g.date.month}.${g.date.year}"),
        actions: [
          TextButton(
            onPressed: _handleSaveOrClose,
            child: Text(
              hasChanges ? "Uložiť" : "Zavrieť",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
          ? const Center(child: Text("Žiadna skladba"))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (ctx, i) {
                final s = songs[i];

                return CheckboxListTile(
                  title: Text(s.title),
                  subtitle: s.author != null ? Text(s.author!) : null,
                  value: selected.contains(s.id),
                  onChanged: (v) => _toggle(s, v ?? false),
                );
              },
            ),
    );
  }
}
