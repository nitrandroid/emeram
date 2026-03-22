import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/rehearsal.dart';
import '../models/song.dart';
import '../models/song_category.dart';

class RehearsalRepertoireScreen extends ConsumerStatefulWidget {
  final Rehearsal rehearsal;

  const RehearsalRepertoireScreen({super.key, required this.rehearsal});

  @override
  ConsumerState<RehearsalRepertoireScreen> createState() =>
      _RehearsalRepertoireScreenState();
}

class _RehearsalRepertoireScreenState
    extends ConsumerState<RehearsalRepertoireScreen> {
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
    final rSongs = await db.fetchRehearsalSongIds(widget.rehearsal.id!);

    setState(() {
      songs = allSongs;
      categories = allCats;
      selected = {...rSongs};
      originalSelected = {...rSongs};
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

    await db.replaceRehearsalSongs(widget.rehearsal.id!, selected);

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
    final r = widget.rehearsal;

    return Scaffold(
      appBar: AppBar(
        title: Text("Repertoár – ${r.date.day}.${r.date.month}.${r.date.year}"),
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
          ? _buildEmpty()
          : _buildList(context),
    );
  }

  // 🔥 Presne rovnaký vizuál ako na obrazovke skladieb
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Žiadna skladba",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
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
    );
  }
}
