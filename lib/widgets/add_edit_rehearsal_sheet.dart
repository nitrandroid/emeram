// lib/widgets/add_edit_rehearsal_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rehearsal.dart';

class AddEditRehearsalSheet extends StatefulWidget {
  final Rehearsal? existing;
  final ValueChanged<Rehearsal> onSubmit;

  const AddEditRehearsalSheet({
    super.key,
    required this.onSubmit,
    this.existing,
  });

  @override
  State<AddEditRehearsalSheet> createState() => _AddEditRehearsalSheetState();
}

class _AddEditRehearsalSheetState extends State<AddEditRehearsalSheet> {
  final DateFormat skDate = DateFormat('dd.MM.yyyy', 'sk_SK');

  late TextEditingController _place;
  DateTime _date = DateTime.now();
  TimeOfDay _from = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();

    _place = TextEditingController(text: widget.existing?.place ?? "");

    if (widget.existing != null) {
      _date = widget.existing!.date;
      _from = _parseTime(widget.existing!.fromTime);
      _to = _parseTime(widget.existing!.toTime);
    }
  }

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  // ========= helper: String "HH:MM" -> TimeOfDay
  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // ========= helper: TimeOfDay -> String "HH:MM"
  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) {
      setState(() => _date = d);
    }
  }

  Future<void> pickFromTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _from,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (t != null && mounted) {
      setState(() => _from = t);
    }
  }

  Future<void> pickToTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _to,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (t != null && mounted) {
      setState(() => _to = t);
    }
  }

  void submit() {
    if (_place.text.trim().isEmpty) return;

    final r = Rehearsal(
      id: widget.existing?.id,
      date: _date,
      fromTime: _formatTime(_from),
      toTime: _formatTime(_to),
      place: _place.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(r);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

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
              isEditing ? "Upraviť skúšku" : "Pridať skúšku",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _place,
              decoration: const InputDecoration(
                labelText: "Miesto",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Dátum"),
              subtitle: Text(skDate.format(_date)),
              trailing: const Icon(Icons.calendar_month),
              onTap: pickDate,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Čas od"),
              subtitle: Text(_from.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: pickFromTime,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Čas do"),
              subtitle: Text(_to.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: pickToTime,
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