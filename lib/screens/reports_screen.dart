// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'rehearsal_report_screen.dart';
import 'gig_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reporty")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Dochádzka – skúšky"),
            subtitle: const Text("Prehľad účasti na skúškach"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RehearsalReportScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.celebration),
            title: const Text("Dochádzka – vystúpenia"),
            subtitle: const Text("Prehľad účasti na vystúpeniach"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GigReportScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Dochádzka podľa osôb"),
            subtitle: const Text("Súhrnné štatistiky"),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("Použitie skladieb"),
            subtitle: const Text("Najčastejšie hrané skladby"),
            onTap: () {
              // TODO
            },
          ),
        ],
      ),
    );
  }
}
