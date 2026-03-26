// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/database_provider.dart';
import '../utils/slovak_sort.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  List<Map<String, dynamic>> rows = [];
  List<int> years = [];
  bool loading = true;
  int? year = DateTime.now().year;
  bool showGigs = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);

    // roky z rehearsals
    final rehearsals = await db.fetchRehearsals();
    final ys = rehearsals.map((r) => r.date.year).toSet().toList()..sort();

    final data = List<Map<String, dynamic>>.from(
      showGigs
          ? await db.fetchGigAttendanceReport(year)
          : await db.fetchAttendanceReport(year),
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

  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    final font = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
    );

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
            pw.Text(
              showGigs ? "Dochádzka – vystúpenia" : "Dochádzka – skúšky",
              style: pw.TextStyle(font: font, fontSize: 18),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  // header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Meno", style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Účasť",
                          style: pw.TextStyle(font: font),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("%", style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),

                  // rows
                  ...rows.map((r) {
                    final attended = r['attended'] ?? 0;
                    final total = r['total'] ?? 0;
                    final percent = total == 0
                        ? 0
                        : ((attended / total) * 100).round();

                    final color = percent < 50
                        ? PdfColors.red
                        : (percent >= 80 ? PdfColors.green : PdfColors.black);

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            "${r['firstName']} ${r['lastName']}",
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            "$attended / $total",
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            "$percent %",
                            style: pw.TextStyle(font: font, color: color),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          )
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'report.pdf');
  }

  Future<void> _printPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                showGigs ? "Dochádzka – vystúpenia" : "Dochádzka – skúšky",
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 12),
              ...rows.map((r) {
                final attended = r['attended'] ?? 0;
                final total = r['total'] ?? 0;
                final percent = total == 0
                    ? 0
                    : ((attended / total) * 100).round();

                return pw.Text(
                  "${r['firstName']} ${r['lastName']}  —  $attended / $total ($percent %)",
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showGigs ? "Dochádzka – vystúpenia" : "Dochádzka – skúšky"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Tlač",
            onPressed: _printPdf,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: Icon(showGigs ? Icons.event : Icons.celebration),
            tooltip: showGigs ? "Zobraziť skúšky" : "Zobraziť vystúpenia",
            onPressed: () {
              setState(() => showGigs = !showGigs);
              _load();
            },
          ),
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              setState(() => year = value);
              _load();
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
