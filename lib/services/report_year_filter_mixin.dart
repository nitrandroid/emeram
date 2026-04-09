import 'package:flutter/material.dart';

mixin ReportYearFilterMixin<T extends StatefulWidget> on State<T> {
  /// null = všetky roky
  int? selectedYear;

  List<int> availableYears = [];
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  /// musí implementovať konkrétny screen
  Future<List<int>> loadAvailableYears();
  Future<List<Map<String, dynamic>>> loadReportData(int? year);

  Future<void> initReport() async {
    setState(() {
      loading = true;
    });

    final years = await loadAvailableYears();
    final data = await loadReportData(selectedYear);

    setState(() {
      availableYears = years;
      rows = data;
      loading = false;
    });
  }

  Future<void> changeYear(int? year) async {
    selectedYear = year;
    await initReport();
  }

  String reportTitle(
    String prefix, {
    required String allYearsLabel,
    required String yearLabelPrefix,
  }) {
    if (selectedYear == null) {
      return "$prefix $allYearsLabel";
    }
    return "$prefix $yearLabelPrefix $selectedYear";
  }
}