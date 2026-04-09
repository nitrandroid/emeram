// lib/screens/gig_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../utils/slovak_sort.dart';
import '../utils/report_pdf.dart';

class GigReportScreen extends ConsumerStatefulWidget {
  const GigReportScreen({super.key});

  @override
  ConsumerState<GigReportScreen> createState() => _GigReportScreenState();
}

class _GigReportScreenState extends ConsumerState<GigReportScreen> {
  List<Map<String, dynamic>> rows = [];
  List<int> years = [];
  bool loading = true;
  int? year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);

    final gigs = await db.fetchGigs();
    final ys = gigs.map((g) => g.date.year).toSet().toList()..sort();

    final data = List<Map<String, dynamic>>.from(
      await db.fetchGigAttendanceReport(year),
    );

    data.sort((a, b) {
      final percentA = (a['total'] == 0) ? 0 : a['attended'] / a['total'];
      final percentB = (b['total'] == 0) ? 0 : b['attended'] / b['total'];

      final cmp = percentB.compareTo(percentA);
      if (cmp != 0) return cmp;

      return slovakCompare(
        "${a['lastName']} ${a['firstName']}",
        "${b['lastName']} ${b['firstName']}",
      );
    });

    setState(() {
      rows = data;
      years = ys;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          year == null
              ? "Dochádzka – vystúpenia za všetky roky"
              : "Dochádzka – vystúpenia za rok $year",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              printReportPdf(
                title: year == null
                    ? "Dochádzka – vystúpenia za všetky roky"
                    : "Dochádzka – vystúpenia za rok $year",
                rows: rows,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              exportReportPdf(
                title: year == null
                    ? "Dochádzka – vystúpenia za všetky roky"
                    : "Dochádzka – vystúpenia za rok $year",
                rows: rows,
              );
            },
          ),
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) async {
              year = value;
              await _load();
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(value: null, child: Text("Všetky roky")),
                ...years.map((y) => PopupMenuItem(value: y, child: Text("$y"))),
              ];
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: rows.length,
              itemBuilder: (ctx, i) {
                final r = rows[i];

                final attended = r['attended'] ?? 0;
                final total = r['total'] ?? 0;
                final percent = total == 0
                    ? 0
                    : ((attended / total) * 100).round();

                return ListTile(
                  title: Text("${r['firstName']} ${r['lastName']}"),
                  subtitle: Text("👥 $attended / $total  ($percent %)"),
                );
              },
            ),
    );
  }
}
