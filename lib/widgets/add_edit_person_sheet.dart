import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/category.dart';

// slovenské triedenie
import '../utils/slovak_sort.dart';

class AddEditPersonSheet extends StatefulWidget {
  final Person? existing;
  final List<Category> categories;
  final ValueChanged<Person> onSubmit;

  const AddEditPersonSheet({
    super.key,
    required this.categories,
    required this.onSubmit,
    this.existing,
  });

  @override
  State<AddEditPersonSheet> createState() => _AddEditPersonSheetState();
}

class _AddEditPersonSheetState extends State<AddEditPersonSheet> {
  final DateFormat skDate = DateFormat('dd.MM.yyyy', 'sk_SK');

  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;

  int? _categoryId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();

    _firstName = TextEditingController(text: widget.existing?.firstName ?? "");
    _lastName = TextEditingController(text: widget.existing?.lastName ?? "");
    _email = TextEditingController(text: widget.existing?.email ?? "");
    _phone = TextEditingController(text: widget.existing?.phone ?? "");

    final firstCat = widget.categories.isNotEmpty
        ? widget.categories.first.id!
        : 1;
    _categoryId = widget.existing?.categoryId ?? firstCat;

    _fromDate = widget.existing?.fromDate;
    _toDate = widget.existing?.toDate;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<DateTime?> pickDate(DateTime? initial) async {
    DateTime? selectedDate = initial ?? DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);

        // TOTO JE PÔVODNÉ — nemením fonty
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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );
  }

  Future<void> _pickStartDate() async {
    final result = await pickDate(_fromDate);
    if (result != null) setState(() => _fromDate = result);
  }

  Future<void> _pickEndDate() async {
    final result = await pickDate(_toDate);
    if (result != null) setState(() => _toDate = result);
  }

  void submit() {
    if (_firstName.text.trim().isEmpty) return;
    if (_lastName.text.trim().isEmpty) return;
    if (_categoryId == null) return;

    final p = Person(
      id: widget.existing?.id,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      categoryId: _categoryId!,
      fromDate: _fromDate,
      toDate: _toDate,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(p);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    // 🎯 SATB triedenie kategórií
    const satbOrder = ["Soprán", "Alt", "Tenor", "Bas"];

    final satbCats =
        widget.categories.where((c) => satbOrder.contains(c.name)).toList()
          ..sort(
            (a, b) =>
                satbOrder.indexOf(a.name).compareTo(satbOrder.indexOf(b.name)),
          );

    final otherCats =
        widget.categories.where((c) => !satbOrder.contains(c.name)).toList()
          ..sort((a, b) => slovakCompare(a.name, b.name));

    final sortedCats = [...satbCats, ...otherCats];

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
              isEditing ? "Upraviť člena" : "Pridať člena",
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _firstName,
              decoration: const InputDecoration(
                labelText: "Meno",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _lastName,
              decoration: const InputDecoration(
                labelText: "Priezvisko",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-mail (nepovinné)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Mobil (nepovinné)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: "Kategória",
                border: OutlineInputBorder(),
              ),
              items: sortedCats.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat.id!,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _categoryId = v);
              },
            ),

            const SizedBox(height: 20),

            // 🔥 PÔVODNÝ UI – každý dátum v samostatnom ListTile
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Dátum od (nepovinné)"),
              subtitle: Text(
                _fromDate != null ? skDate.format(_fromDate!) : "nevyplnené",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_fromDate != null)
                    IconButton(
                      onPressed: () => setState(() => _fromDate = null),
                      icon: const Icon(Icons.clear),
                    ),
                  const Icon(Icons.calendar_month),
                ],
              ),
              onTap: _pickStartDate,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Dátum do (nepovinné)"),
              subtitle: Text(
                _toDate != null
                    ? skDate.format(_toDate!)
                    : "stále aktívny člen",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_toDate != null)
                    IconButton(
                      onPressed: () => setState(() => _toDate = null),
                      icon: const Icon(Icons.clear),
                    ),
                  const Icon(Icons.calendar_month),
                ],
              ),
              onTap: _pickEndDate,
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
