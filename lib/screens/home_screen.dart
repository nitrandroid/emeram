import 'package:flutter/material.dart';
import 'people_screen.dart';
import 'songs_screen.dart';
import 'rehearsals_screen.dart';
import 'gigs_screen.dart';
import 'reports_screen.dart';
import 'maintenance_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildMenuItem({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  child: Icon(icon, size: 32, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Spevácky zbor Emerám")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ČLENOVIA ZBORU
            buildMenuItem(
              icon: Icons.people,
              title: "Členovia zboru",
              subtitle: "Zobrazenie, filtrovanie a správa osôb",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeopleScreen()),
                );
              },
            ),

            // ============================
            // SKLADBY (NOVÁ POLOŽKA)
            // ============================
            buildMenuItem(
              icon: Icons.music_note,
              title: "Skladby",
              subtitle: "Prehľad, filtrovanie a správa skladieb",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SongsScreen()),
                );
              },
            ),

            buildMenuItem(
              icon: Icons.event,
              title: "Skúšky",
              subtitle: "Prehľad a správa skúšok",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RehearsalsScreen()),
                );
              },
            ),

            buildMenuItem(
              icon: Icons.celebration,
              title: "Vystúpenia",
              subtitle: "Prehľad a správa vystúpení",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GigsScreen()),
                );
              },
            ),

            buildMenuItem(
              icon: Icons.bar_chart,
              title: "Reporty",
              subtitle: "Dochádzka podľa osôb",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),

            buildMenuItem(
              icon: Icons.settings,
              title: "Údržba",
              subtitle: "Export, import a správa databázy",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
