// lib/screens/gigs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/gig.dart';
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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final data = await db.fetchGigs();

    setState(() {
      gigs = data;
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

                return ListTile(
                  leading: const Icon(Icons.celebration),
                  title: Text("${g.date.day}.${g.date.month}.${g.date.year}"),
                  subtitle: FutureBuilder(
                    future: Future.wait([
                      ref
                          .read(appDatabaseProvider)
                          .fetchGigAttendancePersonIds(g.id!),
                      ref.read(appDatabaseProvider).fetchPersons(),
                    ]),
                    builder: (context, snap) {
                      if (!snap.hasData) return Text(g.place);

                      final present = (snap.data![0] as Set).length;
                      final people = snap.data![1] as List;

                      final d = g.date;
                      final active = people.where((p) {
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

                      return Text("${g.place}  ·  👥 $present / $active");
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.people),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GigAttendanceScreen(gig: g),
                            ),
                          ).then((_) => _load());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.music_note),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GigRepertoireScreen(gig: g),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {},
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
                            final actions = ref.read(gigsActionsProvider);
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
