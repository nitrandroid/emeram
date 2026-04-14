// lib/screens/maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../data/database.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  Future<void> _exportDb() async {
    final db = AppDatabase.instance;

    // ✅ KRITICKÉ: zapíše WAL zmeny do hlavného .db súboru
    await db.flushWalToDb();

    final database = await db.database;
    final path = database.path;

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final file = await getSaveLocation(suggestedName: 'emeram_backup.db');

      if (file == null) return;

      final target = File(file.path);

      // Overwrite dialog
      if (await target.exists()) {
        if (!mounted) return;

        final action = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Súbor už existuje"),
            content: Text(
              "Súbor ${file.path.split('/').last} už existuje. Vyber, čo chceš spraviť.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, "cancel"),
                child: const Text("Zrušiť"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, "new"),
                child: const Text("Uložiť ako nový"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, "overwrite"),
                child: const Text("Prepísať"),
              ),
            ],
          ),
        );

        if (action == "cancel" || action == null) return;

        if (action == "new") {
          final newFile = await getSaveLocation(
            suggestedName: 'emeram_backup_copy.db',
          );
          if (newFile == null) return;
          await File(path).copy(newFile.path);
          return;
        }
      }

      await File(path).copy(file.path);
    } else {
      final tempDir = await getTemporaryDirectory();
      final exportPath = '${tempDir.path}/emeram_backup.db';

      await File(path).copy(exportPath);

      await SharePlus.instance.share(ShareParams(files: [XFile(exportPath)]));
    }
  }

  // 🔥 IMPORT
  Future<void> _importDb() async {
    final db = AppDatabase.instance;
    final dbPath = (await db.database).path;

    String? sourcePath;

    // ---------------------------
    // 1️⃣ Výber súboru
    // ---------------------------
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'Database', extensions: ['db']),
        ],
      );
      if (file == null) return;
      sourcePath = file.path;
    } else {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      if (result == null) return;
      sourcePath = result.files.single.path;
    }

    if (sourcePath == null) return;
    if (!mounted) return;

    // ---------------------------
    // 2️⃣ Potvrdenie
    // ---------------------------
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Import databázy"),
        content: const Text(
          "Import prepíše aktuálne dáta.\n\n"
          "Odporúčame urobiť zálohu.\n\n"
          "Pokračovať?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Zrušiť"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Importovať"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // ---------------------------
    // 3️⃣ Backup starej DB
    // ---------------------------
    final backupPath =
        '${dbPath}_backup_${DateTime.now().millisecondsSinceEpoch}.db';
    await File(dbPath).copy(backupPath);

    // ---------------------------
    // 4️⃣ Import novej DB
    // ---------------------------
    await File(sourcePath).copy(dbPath);
    await db.reset();

    if (!mounted) return;

    // ---------------------------
    // 5️⃣ Info pre používateľa
    // ---------------------------
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Import dokončený"),
        content: const Text(
          "Databáza bola úspešne naimportovaná.\n\n"
          "Aplikácia sa teraz vráti na úvodnú obrazovku.",
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // ---------------------------
    // 6️⃣ Návrat na home
    // ---------------------------
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 🔥 KONTROLA
  Future<void> _checkDb() async {
    final db = AppDatabase.instance;
    final database = await db.database;

    final result = await database.rawQuery('PRAGMA integrity_check');

    final ok = result.first.values.first == 'ok';

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kontrola databázy"),
        content: Text(
          ok ? "Databáza je v poriadku." : "Databáza obsahuje chyby.",
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // PREINDEXOVANIE
  Future<void> _reindexDb() async {
    final db = AppDatabase.instance;
    final database = await db.database;

    await database.execute('REINDEX');
    await database.execute('ANALYZE');

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Optimalizácia databázy"),
        content: const Text("Databáza bola úspešne optimalizovaná."),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // INFORMÁCIE O APLIKÁCII
  Future<void> _showAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    final db = AppDatabase.instance;
    final dbPath = (await db.database).path;

    final file = File(dbPath);
    final size = await file.length();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Informácie o aplikácii"),
        content: Text(
          "Verzia: ${info.version}\n"
          "Build: ${info.buildNumber}\n\n"
          "Databáza:\n$dbPath\n\n"
          "Veľkosť: ${(size / 1024).toStringAsFixed(1)} KB",
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Údržba")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text("Export databázy"),
            onTap: _exportDb,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Import databázy"),
            onTap: _importDb,
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text("Kontrola databázy"),
            onTap: _checkDb,
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text("Preindexovanie databázy"),
            onTap: _reindexDb,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Informácie o aplikácii"),
            onTap: _showAppInfo,
          ),
        ],
      ),
    );
  }
}
