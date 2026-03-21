import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/song.dart';
import '../models/song_category.dart';

// centrálne slovenské triedenie
import '../utils/slovak_sort.dart';

class AddEditSongSheet extends StatefulWidget {
  final Song? existing;
  final List<SongCategory> categories;
  final ValueChanged<Song> onSubmit;

  const AddEditSongSheet({
    super.key,
    required this.categories,
    required this.onSubmit,
    this.existing,
  });

  @override
  State<AddEditSongSheet> createState() => _AddEditSongSheetState();
}

class _AddEditSongSheetState extends State<AddEditSongSheet> {
  final DateFormat skDate = DateFormat('dd.MM.yyyy', 'sk_SK');

  late TextEditingController _title;
  late TextEditingController _author;
  late TextEditingController _arranger;
  late TextEditingController _language;

  int? _categoryId;
  DateTime? _firstRehearsalDate;

  @override
  void initState() {
    super.initState();

    _title = TextEditingController(text: widget.existing?.title ?? "");
    _author = TextEditingController(text: widget.existing?.author ?? "");
    _arranger = TextEditingController(text: widget.existing?.arranger ?? "");
    _language = TextEditingController(text: widget.existing?.language ?? "");

    final firstCategory = widget.categories.isNotEmpty
        ? widget.categories.first.id!
        : null;

    _categoryId = widget.existing?.categoryId ?? firstCategory;
    _firstRehearsalDate = widget.existing?.firstRehearsalDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _arranger.dispose();
    _language.dispose();
    super.dispose();
  }

  // Unified date picker
  Future<DateTime?> pickDate(DateTime? initial) async {
    DateTime? selectedDate = initial ?? DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              headerHelpStyle: theme.textTheme.labelSmall!.copyWith(
                fontSize: 12,
                height: 1.0,
              ),
              headerHeadlineStyle: theme.textTheme.headlineMedium!.copyWith(
                fontSize: 18,
                height: 1.0,
              ),
              dayStyle: theme.textTheme.bodyLarge!.copyWith(fontSize: 14),
              yearStyle: theme.textTheme.bodyLarge!.copyWith(fontSize: 14),
            ),
          ),
          child: Builder(
            builder: (ctx) {
              return MediaQuery(
                data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickFirstRehearsalDate() async {
    final result = await pickDate(_firstRehearsalDate);
    if (result != null) {
      setState(() => _firstRehearsalDate = result);
    }
  }

  void submit() {
    if (_title.text.trim().isEmpty) return;
    if (_categoryId == null) return;

    final Song song = Song(
      id: widget.existing?.id,
      title: _title.text.trim(),
      author: _author.text.trim().isEmpty ? null : _author.text.trim(),
      arranger: _arranger.text.trim().isEmpty ? null : _arranger.text.trim(),
      language: _language.text.trim().isEmpty ? null : _language.text.trim(),
      categoryId: _categoryId!,
      firstRehearsalDate: _firstRehearsalDate,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(song);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    // 🔥 Default kategória navrchu, ostatné podľa abecedy
    final def = widget.categories.firstWhere((c) => c.isDefault == true);
    final rest = widget.categories.where((c) => c.isDefault == false).toList()
      ..sort((a, b) => slovakCompare(a.name, b.name));

    final sortedCats = [def, ...rest];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? "Upraviť skladbu" : "Pridať skladbu",
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 20),

            // Názov
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: "Názov skladby",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Autor
            TextField(
              controller: _author,
              decoration: const InputDecoration(
                labelText: "Autor (nepovinné)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Aranžér
            TextField(
              controller: _arranger,
              decoration: const InputDecoration(
                labelText: "Aranžér (nepovinné)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Jazyk
            TextField(
              controller: _language,
              decoration: const InputDecoration(
                labelText: "Jazyk (napr. SK, EN, LAT…) (nepovinné)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Kategória skladby
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: "Kategória skladby",
                border: OutlineInputBorder(),
              ),
              items: sortedCats.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat.id!,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => _categoryId = v);
              },
            ),

            const SizedBox(height: 20),

            // Dátum prvej skúšky
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Dátum prvej skúšky (nepovinné)"),
              subtitle: Text(
                _firstRehearsalDate != null
                    ? skDate.format(_firstRehearsalDate!)
                    : "nevyplnené",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_firstRehearsalDate != null)
                    IconButton(
                      onPressed: () =>
                          setState(() => _firstRehearsalDate = null),
                      icon: const Icon(Icons.clear),
                    ),
                  const Icon(Icons.calendar_month),
                ],
              ),
              onTap: _pickFirstRehearsalDate,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submit,
                child: Text(isEditing ? "Uložiť" : "Pridať"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
