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
  List<Gig> gigs = [];
  Map<int, int> presentCount = {};
  Map<int, int> activeCount = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);

    final allGigs = await db.fetchGigs();
    final List<Person> allPeople = await db.fetchPersons();

    final attendanceRows =
        await (await db.database).query('gig_attendance');

    final Map<int, int> presCounts = {};
    final Map<int, Set<int>> attendanceMap = {};

    for (final row in attendanceRows) {
      final gid = row['gigId'] as int;
      final pid = row['personId'] as int;

      attendanceMap.putIfAbsent(gid, () => {}).add(pid);
    }

    final Map<int, int> actCounts = {};

    for (final g in allGigs) {
      final presentIds = attendanceMap[g.id!] ?? {};
      presCounts[g.id!] = presentIds.length;

      final d = g.date;

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

      actCounts[g.id!] = active;
    }

    setState(() {
      gigs = allGigs;
      presentCount = presCounts;
      activeCount = actCounts;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vystúpenia")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) {
              return AddEditGigSheet(
                onSubmit: (g) async {
                  final actions = ref.read(gigsActionsProvider);
                  await actions.add(g);
                  await _load();
                },
              );
            },
          );
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : gigs.isEmpty
              ? const Center(child: Text("Žiadne vystúpenia"))
              : ListView.builder(
                  itemCount: gigs.length,
                  itemBuilder: (ctx, i) {
                    final g = gigs[i];

                    final pres = presentCount[g.id!] ?? 0;
                    final act = activeCount[g.id!] ?? 0;

                    return ListTile(
                      leading: const Icon(Icons.celebration),

                      title: Text(
                        "${g.date.day}.${g.date.month}.${g.date.year}",
                      ),

                      subtitle: Text(
                        "${g.place}  ·  👥 $pres / $act",
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 👥 Attendance
                          IconButton(
                            icon: const Icon(Icons.people),
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

                          // 🎼 Repertoire
                          IconButton(
                            icon: const Icon(Icons.music_note),
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

                          // 🗑 Delete (len ak bez attendance)
                          if (pres == 0)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text(
                                        "Zmazať vystúpenie"),
                                    content: const Text(
                                        "Naozaj chceš zmazať toto vystúpenie?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, false),
                                        child:
                                            const Text("Zrušiť"),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, true),
                                        child:
                                            const Text("Zmazať"),
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
                        ],
                      ),

                      // EDIT
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
                        );
                      },
                    );
                  },
                ),
    );
  }
}