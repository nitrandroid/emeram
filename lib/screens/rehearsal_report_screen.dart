import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../utils/report_pdf.dart';
import '../services/report_year_filter_mixin.dart';
import '../utils/report_sort.dart';

enum ReportSortField { name, percent }

class RehearsalReportScreen extends ConsumerStatefulWidget {
  const RehearsalReportScreen({super.key});

  @override
  ConsumerState<RehearsalReportScreen> createState() =>
      _RehearsalReportScreenState();
}

class _RehearsalReportScreenState extends ConsumerState<RehearsalReportScreen>
    with ReportYearFilterMixin {
  static const int allYearsValue = -1;

  /// Default správanie = ako doteraz
  ReportSortField sortField = ReportSortField.percent;
  bool sortAscending = false;

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
    return rehearsals.map((r) => r.date.year).toSet().toList()..sort();
  }

  @override
  Future<List<Map<String, dynamic>>> loadReportData(int? year) async {
    final db = ref.read(appDatabaseProvider);
    final data = List<Map<String, dynamic>>.from(
      await db.fetchAttendanceReport(year),
    );

    _sortData(data);
    return data;
  }

  void _sortData(List<Map<String, dynamic>> data) {
    data.sort((a, b) {
      if (sortField == ReportSortField.name) {
        return compareByName(a, b, ascending: sortAscending);
      }

      return compareByAttendancePercent(a, b, ascending: sortAscending);
    });
  }

  String get _sortTooltip {
    final field = sortField == ReportSortField.name ? "mena" : "účasti";
    final dir = sortAscending ? "vzostupne" : "zostupne";
    return "Triedené podľa $field ($dir)";
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
          // 🖨 Print
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

          // 📄 PDF
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

          // 🔤 / 📊 Výber poľa triedenia
          PopupMenuButton<ReportSortField>(
            icon: const Icon(Icons.sort),
            tooltip: "Triediť podľa",
            onSelected: (value) {
              setState(() {
                sortField = value;
              });
              _sortData(rows);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ReportSortField.percent,
                child: Text("Podľa účasti (%)"),
              ),
              PopupMenuItem(
                value: ReportSortField.name,
                child: Text("Podľa mena"),
              ),
            ],
          ),

          // 🔼🔽 Smer triedenia
          IconButton(
            icon: Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            tooltip: _sortTooltip,
            onPressed: () {
              setState(() {
                sortAscending = !sortAscending;
              });
              _sortData(rows);
            },
          ),

          // 📅 Filter podľa roku
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_alt),
            tooltip: "Filter podľa roku",
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
