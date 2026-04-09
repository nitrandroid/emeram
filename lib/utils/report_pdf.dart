// lib/utils/report_pdf.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

Future<void> exportReportPdf({
  required String title,
  required List<Map<String, dynamic>> rows,
}) async {
  final pdf = pw.Document();

  final font = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
  );

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(font: font, fontSize: 18)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("Meno", style: pw.TextStyle(font: font)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("Účasť", style: pw.TextStyle(font: font)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("%", style: pw.TextStyle(font: font)),
                ),
              ],
            ),

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
    ),
  );

  await Printing.sharePdf(bytes: await pdf.save(), filename: 'report.pdf');
}

// TLAČ
Future<void> printReportPdf({
  required String title,
  required List<Map<String, dynamic>> rows,
}) async {
  final pdf = pw.Document();

  final font = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
  );

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(font: font, fontSize: 18)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("Meno", style: pw.TextStyle(font: font)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("Účasť", style: pw.TextStyle(font: font)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("%", style: pw.TextStyle(font: font)),
                ),
              ],
            ),
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
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
