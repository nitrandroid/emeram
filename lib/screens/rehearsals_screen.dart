import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/rehearsal.dart';
import '../models/person.dart';
import '../widgets/add_edit_rehearsal_sheet.dart';
import 'rehearsal_attendance_screen.dart';
import 'rehearsal_repertoire_screen.dart';

class RehearsalsScreen extends ConsumerStatefulWidget {
  const RehearsalsScreen({super.key});

  @override
  ConsumerState<RehearsalsScreen> createState() => _RehearsalsScreenState();
}

class _RehearsalsScreenState extends ConsumerState<RehearsalsScreen> {
  List<Rehearsal> rehearsals = [];
  Map<int, int> presentCount = {}; // rehearsalId → prítomní
  Map<int, int> activeCount = {}; // rehearsalId → aktívni
  bool loading = true;

  bool sortAscending = false; // 🔥 DEFAULT = NAJNOVŠIE HORE
  int? filterYear; // null = všetky roky

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);

    final allRehearsals = await db.fetchRehearsals();
    final List<Person> allPeople = await db.fetchPersons();
    final attendanceRows = await (await db.database).query(
      'rehearsal_attendance',
    );

    final Map<int, int> presCounts = {};
    final Map<int, int> actCounts = {};
    final Map<int, Set<int>> attendanceMap = {};
    for (final row in attendanceRows) {
      final rid = row['rehearsalId'] as int;
      final pid = row['personId'] as int;
      attendanceMap.putIfAbsent(rid, () => {}).add(pid);
    }

    for (final r in allRehearsals) {
      final presentIds = attendanceMap[r.id!] ?? {};
      presCounts[r.id!] = presentIds.length;

      final d = r.date;
      final active = allPeople.where((p) {
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

      actCounts[r.id!] = active;
    }

    setState(() {
      rehearsals = allRehearsals;
      presentCount = presCounts;
      activeCount = actCounts;
      loading = false;
    });

    _applySortingAndFiltering(); // 💡 uplatní default DESC triedenie
  }

  // 🔧 TRIEDENIE + FILTER
  void _applySortingAndFiltering() {
    List<Rehearsal> list = [...rehearsals];

    // FILTER podľa roku
    if (filterYear != null) {
      list = list.where((r) => r.date.year == filterYear).toList();
    }

    // TRIEDENIE
    list.sort(
      (a, b) =>
          sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
    );

    setState(() {
      rehearsals = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skúšky"),
        actions: [
          // 🔁 TRIEDENIE ASC / DESC
          IconButton(
            icon: Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            tooltip: sortAscending ? "Triediť zostupne" : "Triediť vzostupne",
            onPressed: () {
              setState(() => sortAscending = !sortAscending);
              _applySortingAndFiltering();
            },
          ),

          // 🔍 FILTER PODĽA ROKU
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_alt),
            tooltip: "Filter podľa roku",
            onSelected: (value) {
              setState(() => filterYear = value);
              _applySortingAndFiltering();
            },
            itemBuilder: (context) {
              final years = rehearsals.map((r) => r.date.year).toSet().toList()
                ..sort();

              return [
                const PopupMenuItem(value: null, child: Text("Všetky roky")),
                ...years.map((y) => PopupMenuItem(value: y, child: Text("$y"))),
              ];
            },
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
              return AddEditRehearsalSheet(
                onSubmit: (r) async {
                  final db = ref.read(appDatabaseProvider);
                  await db.addRehearsal(r);
                  await _load();
                },
              );
            },
          );
        },
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rehearsals.isEmpty
          ? const Center(child: Text("Žiadne skúšky"))
          : ListView.builder(
              itemCount: rehearsals.length,
              itemBuilder: (ctx, i) {
                final r = rehearsals[i];

                final pres = presentCount[r.id!] ?? 0;
                final act = activeCount[r.id!] ?? 0;

                return ListTile(
                  leading: const Icon(Icons.event),

                  title: Text(
                    "${r.date.day.toString().padLeft(2, '0')}."
                    "${r.date.month.toString().padLeft(2, '0')}."
                    "${r.date.year}  "
                    "${r.fromTime.format(context)} – ${r.toTime.format(context)}"
                    "${r.place.isNotEmpty ? "  ·  ${r.place}" : ""}",
                  ),

                  subtitle: Text("👥 $pres / $act"),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✏️ Edit
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: "Upraviť skúšku",
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) {
                              return AddEditRehearsalSheet(
                                existing: r,
                                onSubmit: (updated) async {
                                  final db = ref.read(appDatabaseProvider);
                                  await db.updateRehearsal(updated);
                                  await _load();
                                },
                              );
                            },
                          );
                        },
                      ),

                      // 🗑 Delete – len ak attendance = 0
                      if (pres == 0)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: "Zmazať skúšku",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Zmazať skúšku"),
                                content: const Text(
                                  "Naozaj chceš zmazať túto skúšku?",
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
                              final db = ref.read(appDatabaseProvider);
                              await db.deleteRehearsal(r.id!);
                              await _load();
                            }
                          },
                        ),

                      // 🎼 Repertoár
                      IconButton(
                        icon: const Icon(Icons.music_note),
                        tooltip: "Repertoár",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RehearsalRepertoireScreen(rehearsal: r),
                            ),
                          );
                        },
                      ),

                      // 👥 Attendance
                      IconButton(
                        icon: const Icon(Icons.people),
                        tooltip: "Dochádzka",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RehearsalAttendanceScreen(rehearsal: r),
                            ),
                          ).then((_) => _load());
                        },
                      ),
                    ],
                  ),

                  // Kliknutie na celú položku → EDIT
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) {
                        return AddEditRehearsalSheet(
                          existing: r,
                          onSubmit: (updated) async {
                            final db = ref.read(appDatabaseProvider);
                            await db.updateRehearsal(updated);
                            await _load();
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
