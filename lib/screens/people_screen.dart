import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/person.dart';
import '../models/category.dart';
import '../widgets/add_edit_person_sheet.dart';
import '../widgets/people_category_chip_filter.dart';
import '../widgets/person_item.dart';
import 'people_category_screen.dart';
import '../utils/slovak_sort.dart';

// SORT MODES
enum SortMode { lastName, fromDate, toDate }

// SORT DIRECTION
enum SortDirection { ascending, descending }

// AKTÍVNI/NEAKTÍVNI
enum ActivityFilter { all, active, inactive }

class PeopleScreen extends StatefulWidget {
  final dynamic db;

  const PeopleScreen({super.key, this.db});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<Person> persons = [];
  List<Category> categories = [];
  int? selectedCategoryId;
  bool loading = true;

  SortMode sortMode = SortMode.lastName;
  SortDirection sortDirection = SortDirection.ascending;
  ActivityFilter activityFilter = ActivityFilter.all;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final AppDatabase db = widget.db;

    try {
      final catsFuture = db.fetchCategories();
      final peopsFuture = db.fetchPersons();

      final cats = await catsFuture;
      final peops = await peopsFuture;

      if (!mounted) return;

      setState(() {
        categories = cats;
        persons = peops;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        categories = [];
        persons = [];
        loading = false;
      });

      debugPrint("LOAD ERROR: $e");
    }
  }

  // ----------------------
  // FILTER + SORT
  // ----------------------
  List<Person> get filteredPersons {
    List<Person> list = selectedCategoryId == null
        ? [...persons]
        : persons.where((p) => p.categoryId == selectedCategoryId).toList();

    list = switch (activityFilter) {
      ActivityFilter.active => list.where((p) => p.toDate == null).toList(),
      ActivityFilter.inactive => list.where((p) => p.toDate != null).toList(),
      ActivityFilter.all => list,
    };

    // 🔥 chain sa vytvára iba raz
    late final List<int Function(Person, Person)> chain;

    switch (sortMode) {
      case SortMode.lastName:
        chain = [compareLastName, compareFirstName, compareId];
        break;

      case SortMode.fromDate:
        chain = [compareFromDate, compareLastName, compareFirstName, compareId];
        break;

      case SortMode.toDate:
        chain = [compareToDate, compareLastName, compareFirstName, compareId];
        break;
    }

    int comparator(Person a, Person b) {
      final result = chainCompare(chain, a, b); // 🔥 z utilu
      return sortDirection == SortDirection.descending ? -result : result;
    }

    list.sort(comparator);
    return list;
  }

  // ----------------------
  // COMPARATORS (používajú slovakCompare z utilu)
  // ----------------------
  int compareLastName(Person a, Person b) =>
      slovakCompare(a.lastName, b.lastName);

  int compareFirstName(Person a, Person b) =>
      slovakCompare(a.firstName, b.firstName);

  int compareId(Person a, Person b) => (a.id ?? 0).compareTo(b.id ?? 0);

  int compareFromDate(Person a, Person b) =>
      (a.fromDate ?? DateTime(1900)).compareTo(b.fromDate ?? DateTime(1900));

  int compareToDate(Person a, Person b) =>
      (a.toDate ?? DateTime(3000)).compareTo(b.toDate ?? DateTime(3000));

  // ---------------------------------------------------------------
  // ADD PERSON
  // ---------------------------------------------------------------
  void _openAddPerson() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return AddEditPersonSheet(
          categories: categories,
          onSubmit: (person) async {
            final db = widget.db;
            await db.addPerson(person);
            await _loadAll();

            setState(() {
              sortMode = SortMode.lastName;
              sortDirection = SortDirection.ascending;
            });

            Future.delayed(const Duration(milliseconds: 250), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                );
              }
            });
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // EDIT
  // ---------------------------------------------------------------
  void _openEditPerson(Person existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return AddEditPersonSheet(
          categories: categories,
          existing: existing,
          onSubmit: (updated) async {
            final db = widget.db;
            await db.updatePerson(updated);
            await _loadAll();
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------
  Future<void> _deletePerson(Person p) async {
    final db = widget.db;
    await db.deletePerson(p.id!);
    await _loadAll();
  }

  Future<void> confirmAndDelete(Person p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmazať osobu'),
        content: Text(
          'Naozaj chceš zmazať osobu "${p.firstName} ${p.lastName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zmazať'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePerson(p);
    }
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Členovia zboru"),
        actions: [
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: "Triedenie",
            onSelected: (value) {
              setState(() => sortMode = value);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: SortMode.lastName,
                child: Text("Podľa priezviska"),
              ),
              PopupMenuItem(
                value: SortMode.fromDate,
                child: Text("Podľa dátumu OD"),
              ),
              PopupMenuItem(
                value: SortMode.toDate,
                child: Text("Podľa dátumu DO"),
              ),
            ],
          ),

          // ASC / DESC
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

          // CATEGORY MANAGER
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: "Správa kategórií",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryManagerScreen(db: widget.db),
                ),
              ).then((_) => _loadAll());
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPerson,
        child: const Icon(Icons.person_add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CategoryChipFilter(
                        categories: categories,
                        selectedId: selectedCategoryId,
                        onSelected: (id) {
                          setState(() => selectedCategoryId = id);
                        },
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("Všetci"),
                            selected: activityFilter == ActivityFilter.all,
                            onSelected: (_) {
                              setState(
                                () => activityFilter = ActivityFilter.all,
                              );
                            },
                          ),
                          ChoiceChip(
                            label: const Text("Aktívni"),
                            selected: activityFilter == ActivityFilter.active,
                            onSelected: (_) {
                              setState(
                                () => activityFilter = ActivityFilter.active,
                              );
                            },
                          ),
                          ChoiceChip(
                            label: const Text("Neaktívni"),
                            selected: activityFilter == ActivityFilter.inactive,
                            onSelected: (_) {
                              setState(
                                () => activityFilter = ActivityFilter.inactive,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: filteredPersons.isEmpty
                      ? const Center(child: Text("Žiadni členovia"))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: filteredPersons.length,
                          itemBuilder: (ctx, i) {
                            final person = filteredPersons[i];

                            final category = categories.firstWhere(
                              (c) => c.id == person.categoryId,
                              orElse: () => Category(
                                id: 0,
                                name: "Nezaradený",
                                color: Colors.grey.toARGB32(),
                                isDefault: false,
                                singersCount: 0,
                              ),
                            );

                            return PersonItem(
                              person: person,
                              category: category,
                              onEdit: () => _openEditPerson(person),
                              onDelete: () => confirmAndDelete(person),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
