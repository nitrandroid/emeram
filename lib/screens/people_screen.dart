// lib/screens/people_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/people_provider.dart';
import '../providers/categories_provider.dart';
import '../models/person.dart';
import '../models/category.dart';
import '../widgets/add_edit_person_sheet.dart';
import '../widgets/people_category_chip_filter.dart';
import '../widgets/person_item.dart';
import 'people_category_screen.dart';
import '../utils/slovak_sort.dart';
import '../providers/people_actions_provider.dart';

// SORT MODES
enum SortMode { lastName, fromDate, toDate }

// SORT DIRECTION
enum SortDirection { ascending, descending }

// AKTÍVNI/NEAKTÍVNI
enum ActivityFilter { all, active, inactive }

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  int? selectedCategoryId;
  Set<int> usedPersonIds = {}; // osoby použité v attendance
  SortMode sortMode = SortMode.lastName;
  SortDirection sortDirection = SortDirection.ascending;
  ActivityFilter activityFilter = ActivityFilter.all;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          categories: ref.read(categoriesProvider).value ?? [],
          onSubmit: (person) async {
            final actions = ref.read(peopleActionsProvider);
            await actions.add(person);

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
          categories: ref.read(categoriesProvider).value ?? [],
          existing: existing,
          onSubmit: (updated) async {
            final actions = ref.read(peopleActionsProvider);
            await actions.update(updated);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------
  Future<void> _deletePerson(Person p) async {
    final actions = ref.read(peopleActionsProvider);
    await actions.delete(p.id!);
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
    final peopleAsync = ref.watch(peopleProvider);
    final categoriesAsync = ref.read(categoriesProvider);
    final providerPersons = peopleAsync.value ?? [];
    final providerCategories = categoriesAsync.value ?? [];

    if (usedPersonIds.isEmpty) {
      ref.read(appDatabaseProvider).database.then((db) async {
        final rows = await db.query(
          'rehearsal_attendance',
          columns: ['personId'],
        );
        if (mounted) {
          setState(() {
            usedPersonIds = rows.map((r) => r['personId'] as int).toSet();
          });
        }
      });
    }

    List<Person> filteredPersons = selectedCategoryId == null
        ? [...providerPersons]
        : providerPersons
              .where((p) => p.categoryId == selectedCategoryId)
              .toList();

    filteredPersons = switch (activityFilter) {
      ActivityFilter.active =>
        filteredPersons.where((p) => p.toDate == null).toList(),
      ActivityFilter.inactive =>
        filteredPersons.where((p) => p.toDate != null).toList(),
      ActivityFilter.all => filteredPersons,
    };

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

    final sortedPersons = [...filteredPersons]
      ..sort((a, b) {
        final result = chainCompare(chain, a, b);
        return sortDirection == SortDirection.descending ? -result : result;
      });
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
                  builder: (_) => const CategoryManagerScreen(),
                ),
              ).then((_) => ref.invalidate(peopleProvider));
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPerson,
        child: const Icon(Icons.person_add),
      ),

      body: (peopleAsync.isLoading || categoriesAsync.isLoading)
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("Načítavam údaje..."),
                ],
              ),
            )
          : peopleAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Načítavam údaje..."),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text("Nepodarilo sa načítať údaje"),
                    const SizedBox(height: 6),
                    Text("$e", textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryChipFilter(
                          categories: providerCategories,
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
                              selected:
                                  activityFilter == ActivityFilter.inactive,
                              onSelected: (_) {
                                setState(
                                  () =>
                                      activityFilter = ActivityFilter.inactive,
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
                    child: sortedPersons.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text("Žiadni členovia"),
                                SizedBox(height: 6),
                                Text("Pridaj prvého člena pomocou tlačidla +"),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: sortedPersons.length,
                            itemBuilder: (ctx, i) {
                              final person = sortedPersons[i];

                              final category = providerCategories.firstWhere(
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
                                onDelete: usedPersonIds.contains(person.id)
                                    ? null
                                    : () => confirmAndDelete(person),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
