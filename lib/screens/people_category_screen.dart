import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/category.dart';
import '../utils/slovak_sort.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() =>
      _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  List<Category> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = ref.read(appDatabaseProvider);
    final cats = await db.fetchCategories();

    // načítame všetkých ľudí
    final persons = await db.fetchPersons();

    // SATB poradie
    const satbOrder = ["Soprán", "Alt", "Tenor", "Bas"];

    final satbCats = cats.where((c) => satbOrder.contains(c.name)).toList()
      ..sort(
        (a, b) =>
            satbOrder.indexOf(a.name).compareTo(satbOrder.indexOf(b.name)),
      );

    final otherCats = cats.where((c) => !satbOrder.contains(c.name)).toList()
      ..sort((a, b) => slovakCompare(a.name, b.name));

    // 🔥 doplnenie počtov
    final withCounts = [...satbCats, ...otherCats].map((c) {
      final active = persons
          .where((p) => p.categoryId == c.id && p.toDate == null)
          .length;

      final inactive = persons
          .where((p) => p.categoryId == c.id && p.toDate != null)
          .length;

      return c.copyWith(
        singersCount: active + inactive,
        activeCount: active,
        inactiveCount: inactive,
      );
    }).toList();

    setState(() {
      categories = withCounts;
      loading = false;
    });
  }

  // -------------------------------------------------------------
  // ADD / EDIT CATEGORY
  // -------------------------------------------------------------
  void _openCategorySheet({Category? existing}) {
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
                    existing == null ? "Pridať kategóriu" : "Upraviť kategóriu",
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
                          final selected =
                              c.toARGB32() == selectedColor.toARGB32();
                          return GestureDetector(
                            onTap: () => setModal(() => selectedColor = c),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: selected
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
                        if (nameCtrl.text.trim().isEmpty) return;

                        final db = ref.read(appDatabaseProvider);
                        Navigator.pop(context);

                        if (existing == null) {
                          await db.addCategory(
                            Category(
                              id: null,
                              name: nameCtrl.text.trim(),
                              color: selectedColor.toARGB32(),
                              isDefault: false,
                              singersCount: 0,
                            ),
                          );
                        } else {
                          await db.updateCategory(
                            existing.copyWith(
                              name: nameCtrl.text.trim(),
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
  // DELETE
  // -------------------------------------------------------------
  Future<void> _deleteCategory(Category c) async {
    final db = ref.read(appDatabaseProvider);

    if (c.singersCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kategóriu nie je možné odstrániť — obsahuje členov."),
        ),
      );
      return;
    }

    await db.deleteCategory(c.id!);
    await _loadCategories();
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kategórie spevákov")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategorySheet(),
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? const Center(child: Text("Žiadne kategórie"))
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
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  title: Text(c.name),
                  subtitle: Text(
                    "Aktívni: ${c.activeCount} · Neaktívni: ${c.inactiveCount} · Spolu: ${c.singersCount}",
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // EDIT
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openCategorySheet(existing: c),
                      ),

                      // DELETE only if empty
                      if (c.singersCount == 0)
                        IconButton(
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
