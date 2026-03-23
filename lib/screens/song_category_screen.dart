import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/song_category.dart';
import '../utils/slovak_sort.dart';

class SongCategoryManagerScreen extends StatefulWidget {
  final AppDatabase db;

  const SongCategoryManagerScreen({super.key, required this.db});

  @override
  State<SongCategoryManagerScreen> createState() =>
      _SongCategoryManagerScreenState();
}

class _SongCategoryManagerScreenState extends State<SongCategoryManagerScreen> {
  List<SongCategory> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = widget.db;
    final cats = await db.fetchSongCategories();

    if (!mounted) return;

    // 🔥 Default kategória vždy ako prvá
    final def = cats.firstWhere((c) => c.isDefault == true);
    final rest = cats.where((c) => c.isDefault == false).toList()
      ..sort((a, b) => slovakCompare(a.name, b.name));

    setState(() {
      categories = [def, ...rest];
      loading = false;
    });
  }

  // -------------------------------------------------------------
  // ADD / EDIT CATEGORY
  // -------------------------------------------------------------
  void _openCategorySheet({SongCategory? existing}) {
    // 🔥 Default kategória sa NEDÁ upraviť
    if (existing != null && existing.isDefault == true) return;

    final nameCtrl = TextEditingController(text: existing?.name ?? "");
    Color selectedColor = existing != null
        ? Color(existing.color)
        : Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null
                        ? "Pridať kategóriu skladieb"
                        : "Upraviť kategóriu",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Názov kategórie",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text("Farba", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    children:
                        [
                          Colors.pink,
                          Colors.purple,
                          Colors.blue,
                          Colors.brown,
                          Colors.orange,
                          Colors.green,
                          Colors.grey,
                        ].map((c) {
                          final isSelected = (c == selectedColor);
                          return GestureDetector(
                            onTap: () => setModal(() => selectedColor = c),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        Navigator.pop(context);

                        final db = widget.db;

                        if (existing == null) {
                          await db.addSongCategory(
                            SongCategory(
                              id: null,
                              name: name,
                              color: selectedColor.toARGB32(),
                              songsCount: 0,
                              isDefault: false,
                            ),
                          );
                        } else {
                          await db.updateSongCategory(
                            existing.copyWith(
                              name: name,
                              color: selectedColor.toARGB32(),
                            ),
                          );
                        }

                        await _loadCategories();
                      },
                      child: Text(existing == null ? "Pridať" : "Uložiť"),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // DELETE CATEGORY (only if songsCount == 0)
  // -------------------------------------------------------------
  Future<void> _deleteCategory(SongCategory c) async {
    final db = widget.db;

    final ok = await db.deleteSongCategory(c.id!);

    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Kategóriu nie je možné odstrániť — obsahuje skladby alebo je predvolená.",
          ),
        ),
      );
      return;
    }

    await _loadCategories();
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kategórie skladieb")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategorySheet(),
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (ctx, i) {
                final c = categories[i];
                final color = Color(c.color);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    radius: 18,
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  title: Text(c.name),
                  subtitle: Text("Skladieb: ${c.songsCount}"),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔥 Default kategória NEMÁ žiadne akcie
                      if (!c.isDefault)
                        IconButton(
                          tooltip: "Upraviť",
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openCategorySheet(existing: c),
                        ),

                      if (!c.isDefault && c.songsCount == 0)
                        IconButton(
                          tooltip: "Zmazať",
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCategory(c),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
