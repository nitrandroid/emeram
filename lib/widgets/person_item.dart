import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/person.dart';
import '../models/category.dart';

class PersonItem extends StatelessWidget {
  final Person person;
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final DateFormat _dateFormat = DateFormat.yMd('sk_SK');

  const PersonItem({
    super.key,
    required this.person,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);

    return ListTile(
      isThreeLine: true,

      title: Text(
        '${person.firstName} ${person.lastName}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EMAIL + PHONE (len text, nie klikateľné)
          if (person.email != null || person.phone != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (person.email != null)
                  Flexible(
                    child: Text(
                      person.email!,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                if (person.email != null && person.phone != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text("•", style: TextStyle(fontSize: 12)),
                  ),

                if (person.phone != null)
                  Text(person.phone!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],

          // DATES
          if (person.fromDate != null || person.toDate != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDates(),
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],

          const SizedBox(height: 4),

          // CATEGORY BADGE + DOT
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Icon(Icons.circle, color: color, size: 10),
            ],
          ),
        ],
      ),

      // 🔥 FIXNÁ ŠÍRKA → ikony sa nehýbu
      trailing: SizedBox(
        width: 160,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (person.phone != null && person.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone),
                tooltip: 'Zavolať',
                onPressed: () => _confirmAndCall(context, person.phone!),
              ),

            if (person.email != null && person.email!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.email),
                tooltip: 'Napísať e-mail',
                onPressed: () => _confirmAndEmail(context, person.email!),
              ),

            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Upraviť',
              onPressed: onEdit,
            ),

            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Zmazať',
              onPressed: onDelete,
            ),
          ],
        ),
      ),

      onTap: onEdit,
    );
  }

  // ----------------------
  // DATE FORMAT
  // ----------------------
  String _formatDates() {
    String f(DateTime d) => _dateFormat.format(d);

    if (person.fromDate != null && person.toDate != null) {
      return "Od ${f(person.fromDate!)} do ${f(person.toDate!)}";
    } else if (person.fromDate != null) {
      return "Od ${f(person.fromDate!)}";
    } else if (person.toDate != null) {
      return "Do ${f(person.toDate!)}";
    }
    return "";
  }

  // ----------------------
  // EMAIL
  // ----------------------
  Future<void> _confirmAndEmail(BuildContext context, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Napísať e-mail'),
        content: Text('Naozaj chceš napísať e-mail na $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Napísať'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri(scheme: 'mailto', path: email);

      if (!await launchUrl(uri)) {
        throw Exception('Could not launch email');
      }
    }
  }

  // ----------------------
  // PHONE
  // ----------------------
  Future<void> _confirmAndCall(BuildContext context, String phone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zavolať'),
        content: Text('Naozaj chceš zavolať na číslo $phone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zavolať'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri(scheme: 'tel', path: phone);

      if (!await launchUrl(uri)) {
        throw Exception('Could not launch phone');
      }
    }
  }
}
