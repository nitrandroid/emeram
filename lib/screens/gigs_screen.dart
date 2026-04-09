// lib/screens/gigs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../models/gig.dart';
import '../models/person.dart';
import '../widgets/add_edit_gig_sheet.dart';
import '../providers/gigs_actions_provider.dart';
import 'gig_attendance_screen.dart';
import 'gig_repertoire_screen.dart';

class GigsScreen extends ConsumerStatefulWidget {
  const GigsScreen({super.key});

  @override
  ConsumerState<GigsScreen> createState() => _GigsScreenState();
}

class _GigsScreenState extends ConsumerState<GigsScreen> {
  static const int allYearsValue = -1;

  List<Gig> _allGigs = [];
  List<Gig> gigs = [];

  Map<int, int> presentCount = {}; // gigId → prítomní
  Map<int, int> activeCount = {}; // gigId → aktívni

  bool loading = true;
  bool sortAscending = false; // 🔥 DEFAULT = NAJNOVŠIE HORE

  int selectedYearValue = allYearsValue;

  int? get selectedYear =>
      selectedYearValue == allYearsValue ? null : selectedYearValue;

  String get titleText =>
      selectedYear == null
          ? "Vystúpenia – všetky roky"
          : "Vystúpenia – rok $selectedYear";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);

    final rows = await db.fetchGigsWithStats();
    final List<Gig> allGigs =
        rows.map((r) => Gig.fromMap(r)).toList();

    final List<Person> allPeople = await db.fetchPersons();
    final Map<String, int> activeCache = {};
    final Map<int, int> presCounts = {
      for (final r in rows)
        r['id'] as int: (r['presentCount'] as int? ?? 0),
    };
    final Map<int, int> actCounts = {};

    for (final r in rows) {
      final d = DateTime.parse(r['date']);
      final key = d.toIso8601String();

      if (!activeCache.containsKey(key)) {
        activeCache[key] = allPeople.where((p) {
          final fromOk =
              p.fromDate == null ||
              p.fromDate!.isBefore(d) ||
              p.fromDate!.isAtSameMomentAs(d);

          final toOk =
              p.toDate == null ||
              p.toDate!.isAfter(d) ||
              p.toDate!.isAtSameMomentAs(d);

          return fromOk && toOk;
        }).length;
      }

      actCounts[r['id'] as int] = activeCache[key]!;
    }

    setState(() {
      _allGigs = allGigs;
      presentCount = presCounts;
      activeCount = actCounts;
      loading = false;
    });

    _applySortingAndFiltering();
  }

  // 🔧 TRIEDENIE + FILTER
  void _applySortingAndFiltering() {
    List<Gig> list = [..._allGigs];

    // FILTER podľa roku
    if (selectedYear != null) {
      list = list.where((g) => g.date.year == selectedYear).toList();
    }

    // TRIEDENIE
    list.sort(
      (a, b) => sortAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date),
    );

    setState(() {
      gigs = list;
    });
  }

  List<int> get availableYears =>
      _allGigs.map((g) => g.date.year).toSet().toList()
        ..sort();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          // 🔁 TRIEDENIE ASC / DESC
          IconButton(
            icon: Icon(
              sortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
            tooltip:
                sortAscending ? "Triediť zostupne" : "Triediť vzostupne",
            onPressed: () {
              setState(() => sortAscending = !sortAscending);
              _applySortingAndFiltering();
            },
          ),

          // 🔍 FILTER PODĽA ROKU (SENTINEL)
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_alt),
            tooltip: "Filter podľa roku",
            onSelected: (value) {
              setState(() {
                selectedYearValue = value;
              });
              _applySortingAndFiltering();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: allYearsValue,
                child: Text("Všetky roky"),
              ),
              ...availableYears.map(
                (y) => PopupMenuItem(
                  value: y,
                  child: Text("$y"),
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            builder: (_) {
              return AddEditGigSheet(
                onSubmit: (g) async {
                  final actions = ref.read(gigsActionsProvider);
                  await actions.add(g);
                  await _load();
                },
              );
            },
          ).then((_) => _load());
        },
      ),

      body: loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("Načítavam vystúpenia..."),
                ],
              ),
            )
          : gigs.isEmpty
              ? const Center(child: Text("Žiadne vystúpenia"))
              : ListView.builder(
                  itemCount: gigs.length,
                  itemBuilder: (ctx, i) {
                    final g = gigs[i];

                    final pres = presentCount[g.id!] ?? 0;
                    final act = activeCount[g.id!] ?? 0;

                    return ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(
                        "${g.date.day.toString().padLeft(2, '0')}."
                        "${g.date.month.toString().padLeft(2, '0')}."
                        "${g.date.year}  "
                        "${g.fromTime} – ${g.toTime}"
                        "${g.place.isNotEmpty ? "  ·  ${g.place}" : ""}",
                      ),
                      subtitle: Text("👥 $pres / $act"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: "Upraviť vystúpenie",
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) {
                                  return AddEditGigSheet(
                                    existing: g,
                                    onSubmit: (updated) async {
                                      final actions =
                                          ref.read(gigsActionsProvider);
                                      await actions.update(updated);
                                      await _load();
                                    },
                                  );
                                },
                              ).then((_) => _load());
                            },
                          ),
                          if (pres == 0)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: "Zmazať vystúpenie",
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text(
                                        "Zmazať vystúpenie"),
                                    content: const Text(
                                      "Naozaj chceš zmazať toto vystúpenie?",
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text("Zrušiť"),
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                      ),
                                      FilledButton(
                                        child: const Text("Zmazať"),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final actions =
                                      ref.read(gigsActionsProvider);
                                  await actions.delete(g.id!);
                                  await _load();
                                }
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.music_note),
                            tooltip: "Repertoár",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GigRepertoireScreen(gig: g),
                                ),
                              ).then((_) => _load());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.people),
                            tooltip: "Dochádzka",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GigAttendanceScreen(gig: g),
                                ),
                              ).then((_) => _load());
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
                            return AddEditGigSheet(
                              existing: g,
                              onSubmit: (updated) async {
                                final actions =
                                    ref.read(gigsActionsProvider);
                                await actions.update(updated);
                                await _load();
                              },
                            );
                          },
                        ).then((_) => _load());
                      },
                    );
                  },
                ),
    );
  }
}