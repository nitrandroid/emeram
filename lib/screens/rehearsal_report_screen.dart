import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../utils/slovak_sort.dart';
import '../utils/report_pdf.dart';
import '../services/report_year_filter_mixin.dart';

class RehearsalReportScreen extends ConsumerStatefulWidget {
  const RehearsalReportScreen({super.key});

  @override
  ConsumerState<RehearsalReportScreen> createState() =>
      _RehearsalReportScreenState();
}

class _RehearsalReportScreenState
    extends ConsumerState<RehearsalReportScreen>
    with ReportYearFilterMixin {
  static const int allYearsValue = -1;

  @override
  void initState() {
    super.initState();
    selectedYear = null; // štart = všetky roky
    initReport();
  }

  @override
  Future<List<int>> loadAvailableYears() async {
    final db = ref.read(appDatabaseProvider);
    final rehearsals = await db.fetchRehearsals();
    return rehearsals
        .map((r) => r.date.year)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Future<List<Map<String, dynamic>>> loadReportData(int? year) async {
    final db = ref.read(appDatabaseProvider);

    final data = List<Map<String, dynamic>>.from(
      await db.fetchAttendanceReport(year),
    );

    data.sort((a, b) {
      final pA = (a['total'] == 0) ? 0 : a['attended'] / a['total'];
      final pB = (b['total'] == 0) ? 0 : b['attended'] / b['total'];

      final cmp = pB.compareTo(pA);
      if (cmp != 0) return cmp;

      return slovakCompare(
        "${a['lastName']} ${a['firstName']}",
        "${b['lastName']} ${b['firstName']}",
      );
    });

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          reportTitle(
            "Dochádzka – skúšky",
            allYearsLabel: "za všetky roky",
            yearLabelPrefix: "za rok",
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: rows.isEmpty
                ? null
                : () {
                    printReportPdf(
                      title: reportTitle(
                        "Dochádzka – skúšky",
                        allYearsLabel: "za všetky roky",
                        yearLabelPrefix: "za rok",
                      ),
                      rows: rows,
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: rows.isEmpty
                ? null
                : () {
                    exportReportPdf(
                      title: reportTitle(
                        "Dochádzka – skúšky",
                        allYearsLabel: "za všetky roky",
                        yearLabelPrefix: "za rok",
                      ),
                      rows: rows,
                    );
                  },
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              changeYear(value == allYearsValue ? null : value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: allYearsValue,
                child: Text("Všetky roky"),
              ),
              ...availableYears.map(
                (y) => PopupMenuItem(value: y, child: Text("$y")),
              ),
            ],
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
                final percent =
                    total == 0 ? 0 : ((attended / total) * 100).round();

                return ListTile(
                  title: Text("${r['firstName']} ${r['lastName']}"),
                  subtitle:
                      Text("👥 $attended / $total  ($percent %)"),
                );
              },
            ),
    );
  }
}