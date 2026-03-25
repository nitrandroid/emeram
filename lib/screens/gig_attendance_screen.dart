// lib/screens/gig_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gig.dart';
import '../models/person.dart';
import '../models/category.dart';
import '../providers/database_provider.dart';

class GigAttendanceScreen extends ConsumerStatefulWidget {
  final Gig gig;

  const GigAttendanceScreen({super.key, required this.gig});

  @override
  ConsumerState<GigAttendanceScreen> createState() =>
      _GigAttendanceScreenState();
}

class _GigAttendanceScreenState extends ConsumerState<GigAttendanceScreen> {
  List<Person> people = [];
  List<Category> categories = [];
  Set<int> present = {};
  Set<int> originalPresent = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get hasChanges =>
      !(present.length == originalPresent.length &&
          present.containsAll(originalPresent) &&
          originalPresent.containsAll(present));

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);

    final allPeople = await db.fetchPersons();
    final allCats = await db.fetchCategories();

    final d = widget.gig.date;

    final active = allPeople.where((p) {
      final fromOk =
          p.fromDate == null ||
          p.fromDate!.isBefore(d) ||
          p.fromDate!.isAtSameMomentAs(d);
      final toOk =
          p.toDate == null ||
          p.toDate!.isAfter(d) ||
          p.toDate!.isAtSameMomentAs(d);
      return fromOk && toOk;
    }).toList();

    final presentIds = await db.fetchGigAttendancePersonIds(widget.gig.id!);

    if (!mounted) return;

    setState(() {
      people = active;
      categories = allCats;
      present = {...presentIds};
      originalPresent = {...presentIds};
      loading = false;
    });
  }

  void _toggle(Person p, bool checked) {
    setState(() {
      if (checked) {
        present.add(p.id!);
      } else {
        present.remove(p.id!);
      }
    });
  }

  Future<void> _save() async {
    final db = ref.read(appDatabaseProvider);

    await db.replaceGigAttendance(widget.gig.id!, present);

    if (!mounted) return;

    setState(() {
      originalPresent = {...present};
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Účasť uložená.")));
  }

  Future<void> _handleSaveOrClose() async {
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Uložiť dochádzku?"),
        content: const Text("Chystáte sa uložiť zmeny dochádzky."),
        actions: [
          TextButton(
            child: const Text("Zrušiť"),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: const Text("Uložiť"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gig;

    return Scaffold(
      appBar: AppBar(
        title: Text("Účasť – ${g.date.day}.${g.date.month}.${g.date.year}"),
        actions: [
          TextButton(
            onPressed: _handleSaveOrClose,
            child: Text(
              hasChanges ? "Uložiť" : "Zavrieť",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildGroupedList(context),
    );
  }

  Widget _buildGroupedList(BuildContext context) {
    final sortedCats = [
      ...categories.where((c) => c.isDefault),
      ...categories.where((c) => !c.isDefault),
    ];

    final List<Widget> widgets = [];

    for (final cat in sortedCats) {
      final groupPeople = people.where((p) => p.categoryId == cat.id).toList();

      if (groupPeople.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(cat.name),
        ),
      );

      for (final p in groupPeople) {
        widgets.add(
          CheckboxListTile(
            title: Text("${p.firstName} ${p.lastName}"),
            value: present.contains(p.id),
            onChanged: (v) => _toggle(p, v ?? false),
          ),
        );
      }
    }

    return ListView(children: widgets);
  }
}
