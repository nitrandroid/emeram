// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../utils/slovak_sort.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  int year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final data = List<Map<String, dynamic>>.from(
      await db.fetchAttendanceReport(year),
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
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dochádzka – report"),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (y) {
              setState(() => year = y);
              _load();
            },
            itemBuilder: (context) {
              final current = DateTime.now().year;
              final years = List.generate(5, (i) => current - i);

              return years
                  .map((y) => PopupMenuItem(value: y, child: Text("$y")))
                  .toList();
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
