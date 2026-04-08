import 'dart:io';
import 'package:flutter/services.dart'; // ← TOTO PRIDAJ
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/category.dart';
import '../models/person.dart';
import '../models/song_category.dart';
import '../models/song.dart';
import '../models/rehearsal.dart';
import '../models/gig.dart';

class AppDatabase {
  AppDatabase._();
  static AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<void> reset() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> _initDb() async {
    // ✅ multiplatform správna cesta
    late String path;

    if (Platform.isAndroid || Platform.isIOS) {
      final dbDir = await getDatabasesPath();
      path = join(dbDir, 'emeram.db');
    } else {
      final dbDir = join(Directory.current.path, 'dev_data');
      await Directory(dbDir).create(recursive: true);
      path = join(dbDir, 'emeram.db');
    }

    // Skontroluj, či runtime databáza existuje
    final exists = await databaseExists(path);

    // Ak neexistuje → skopíruj ju z assets
    if (!exists) {
      try {
        final data = await rootBundle.load('assets/db/emeram.db');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        await File(path).writeAsBytes(bytes, flush: true);
      } catch (_) {}
    }

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ============================================================
  // PEOPLE CATEGORY CRUD
  // ============================================================

  Future<int> addCategory(Category c) async {
    final db = await database;
    return await db.insert('categories', {
      'name': c.name,
      'color': c.color,
      'isDefault': c.isDefault ? 1 : 0,
      'singersCount': c.singersCount,
    });
  }

  Future<List<Category>> fetchCategories() async {
    final db = await database;
    final rows = await db.query('categories');

    return rows.map((r) {
      return Category(
        id: r['id'] as int,
        name: r['name'] as String,
        color: r['color'] as int,
        isDefault: (r['isDefault'] as int) == 1,
        singersCount: r['singersCount'] as int,
      );
    }).toList();
  }

  Future<int> updateCategory(Category c) async {
    final db = await database;
    return await db.update(
      'categories',
      {'name': c.name, 'color': c.color, 'isDefault': c.isDefault ? 1 : 0},
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<bool> deleteCategory(int id) async {
    final db = await database;

    final used = await db.query(
      'persons',
      where: 'categoryId = ?',
      whereArgs: [id],
    );

    if (used.isNotEmpty) return false;

    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  // ============================================================
  // PERSON CRUD
  // ============================================================

  Future<int> addPerson(Person p) async {
    final db = await database;
    return await db.insert('persons', {
      'firstName': p.firstName,
      'lastName': p.lastName,
      'email': p.email,
      'phone': p.phone,
      'categoryId': p.categoryId,
      'fromDate': p.fromDate?.toIso8601String(),
      'toDate': p.toDate?.toIso8601String(),
      'createdAt': p.createdAt?.toIso8601String(),
    });
  }

  Future<List<Person>> fetchPersons() async {
    final db = await database;
    final rows = await db.query('persons');

    return rows.map((r) {
      return Person(
        id: r['id'] as int,
        firstName: r['firstName'] as String,
        lastName: r['lastName'] as String,
        email: r['email'] as String?,
        phone: r['phone'] as String?,
        categoryId: r['categoryId'] as int,
        fromDate: r['fromDate'] != null
            ? DateTime.parse(r['fromDate'] as String)
            : null,
        toDate: r['toDate'] != null
            ? DateTime.parse(r['toDate'] as String)
            : null,
        createdAt: r['createdAt'] != null
            ? DateTime.parse(r['createdAt'] as String)
            : null,
      );
    }).toList();
  }

  Future<int> updatePerson(Person p) async {
    final db = await database;
    return await db.update(
      'persons',
      {
        'firstName': p.firstName,
        'lastName': p.lastName,
        'email': p.email,
        'phone': p.phone,
        'categoryId': p.categoryId,
        'fromDate': p.fromDate?.toIso8601String(),
        'toDate': p.toDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  /// 🔥 dôležité: vráti TRUE ak sa podarilo zmazať, FALSE ak má dochádzku
  Future<bool> deletePerson(int id) async {
    final db = await database;

    // 1) Skontroluj attendance
    final attendanceRows = await db.query(
      'rehearsal_attendance',
      where: 'personId = ?',
      whereArgs: [id],
    );

    if (attendanceRows.isNotEmpty) {
      // osoba má dochádzku → nesmie sa zmazať
      return false;
    }

    // 2) Bezpečné mazanie
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);

    return true;
  }

  // ============================================================
  // SONG CATEGORY CRUD
  // ============================================================

  Future<int> addSongCategory(SongCategory c) async {
    final db = await database;
    return await db.insert('song_categories', {
      'name': c.name,
      'color': c.color,
      'songsCount': c.songsCount,
      'isDefault': c.isDefault ? 1 : 0,
    });
  }

  Future<List<SongCategory>> fetchSongCategories() async {
    final db = await database;
    final rows = await db.query('song_categories');

    return rows.map((r) {
      return SongCategory(
        id: r['id'] as int,
        name: r['name'] as String,
        color: r['color'] as int,
        songsCount: r['songsCount'] as int,
        isDefault: (r['isDefault'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<int> updateSongCategory(SongCategory c) async {
    final db = await database;
    return await db.update(
      'song_categories',
      {
        'name': c.name,
        'color': c.color,
        'songsCount': c.songsCount,
        'isDefault': c.isDefault ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<bool> deleteSongCategory(int id) async {
    final db = await database;

    // BLOCK DEFAULT CATEGORY
    final found = await db.query(
      'song_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (found.isNotEmpty && (found.first['isDefault'] as int) == 1) {
      return false;
    }

    // BLOCK CATEGORY USED BY SONGS
    final used = await db.query(
      'songs',
      where: 'categoryId = ?',
      whereArgs: [id],
    );
    if (used.isNotEmpty) return false;

    await db.delete('song_categories', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  // ============================================================
  // SONG CRUD
  // ============================================================

  Future<int> addSong(Song s) async {
    final db = await database;
    return await db.insert('songs', {
      'title': s.title,
      'author': s.author,
      'arranger': s.arranger,
      'language': s.language,
      'categoryId': s.categoryId,
      'firstRehearsalDate': s.firstRehearsalDate?.toIso8601String(),
      'createdAt': s.createdAt.toIso8601String(),
    });
  }

  Future<List<Song>> fetchSongs() async {
    final db = await database;
    final rows = await db.query('songs');
    return rows.map((r) => Song.fromMap(r)).toList();
  }

  Future<int> updateSong(Song s) async {
    final db = await database;
    return await db.update(
      'songs',
      {
        'title': s.title,
        'author': s.author,
        'arranger': s.arranger,
        'language': s.language,
        'categoryId': s.categoryId,
        'firstRehearsalDate': s.firstRehearsalDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<void> deleteSong(int id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // REHEARSALS CRUD
  // ============================================================

  Future<int> addRehearsal(Rehearsal r) async {
    final db = await database;
    return await db.insert('rehearsals', {
      'date': r.date.toIso8601String(),
      'fromTime': "${r.fromTime.hour}:${r.fromTime.minute}",
      'toTime': "${r.toTime.hour}:${r.toTime.minute}",
      'place': r.place,
      'createdAt': r.createdAt.toIso8601String(),
    });
  }

  Future<List<Rehearsal>> fetchRehearsals() async {
    final db = await database;
    final rows = await db.query('rehearsals');
    return rows.map((r) => Rehearsal.fromMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchRehearsalsWithStats() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        r.*,
        COUNT(DISTINCT ra.personId) as presentCount
      FROM rehearsals r
      LEFT JOIN rehearsal_attendance ra ON ra.rehearsalId = r.id
      GROUP BY r.id
      ORDER BY r.date DESC
    ''');
  }

  Future<void> updateRehearsal(Rehearsal r) async {
    final db = await database;
    await db.update(
      'rehearsals',
      {
        'date': r.date.toIso8601String(),
        'fromTime': "${r.fromTime.hour}:${r.fromTime.minute}",
        'toTime': "${r.toTime.hour}:${r.toTime.minute}",
        'place': r.place,
      },
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<void> deleteRehearsal(int id) async {
    final db = await database;
    await db.delete('rehearsals', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // REHEARSAL SONGS
  // ============================================================
  Future<Set<int>> fetchRehearsalSongIds(int rehearsalId) async {
    final db = await database;

    final rows = await db.query(
      'rehearsal_songs',
      where: 'rehearsalId = ?',
      whereArgs: [rehearsalId],
    );

    return rows.map((r) => r['songId'] as int).toSet();
  }

  Future<void> replaceRehearsalSongs(int rehearsalId, Set<int> songIds) async {
    final db = await database;

    final batch = db.batch();

    // zmaž staré
    batch.delete(
      'rehearsal_songs',
      where: 'rehearsalId = ?',
      whereArgs: [rehearsalId],
    );

    // vlož nové
    for (final sid in songIds) {
      batch.insert('rehearsal_songs', {
        'rehearsalId': rehearsalId,
        'songId': sid,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  // ============================================================
  // REHEARSAL ATTENDANCE
  // ============================================================

  // Vracia Set<int> personId členov, ktorí sú prítomní na skúške
  Future<Set<int>> fetchRehearsalAttendancePersonIds(int rehearsalId) async {
    final db = await database;

    final rows = await db.query(
      'rehearsal_attendance',
      where: 'rehearsalId = ?',
      whereArgs: [rehearsalId],
    );

    return rows.map((r) => r['personId'] as int).toSet();
  }

  // Nahradí dochádzku pre skúšku novými údajmi
  Future<void> replaceRehearsalAttendance(
    int rehearsalId,
    Set<int> personIds,
  ) async {
    final db = await database;

    final batch = db.batch();

    batch.delete(
      'rehearsal_attendance',
      where: 'rehearsalId = ?',
      whereArgs: [rehearsalId],
    );

    for (final pid in personIds) {
      batch.insert('rehearsal_attendance', {
        'rehearsalId': rehearsalId,
        'personId': pid,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  // Vráti ID skúšok, na ktorých bol člen prítomný
  Future<Set<int>> fetchRehearsalIdsForPerson(int personId) async {
    final db = await database;

    final rows = await db.query(
      'rehearsal_attendance',
      where: 'personId = ?',
      whereArgs: [personId],
    );

    return rows.map((r) => r['rehearsalId'] as int).toSet();
  }

  // ============================================================
  // GIGSS CRUD
  // ============================================================

  Future<int> addGig(Gig g) async {
    final db = await database;
    return await db.insert('gigs', {
      'date': g.date.toIso8601String(),
      'fromTime': "${g.fromTime.hour}:${g.fromTime.minute}",
      'toTime': "${g.toTime.hour}:${g.toTime.minute}",
      'place': g.place,
      'createdAt': g.createdAt.toIso8601String(),
    });
  }

  Future<void> updateGig(Gig g) async {
    final db = await database;
    await db.update(
      'gigs',
      {
        'date': g.date.toIso8601String(),
        'fromTime': "${g.fromTime.hour}:${g.fromTime.minute}",
        'toTime': "${g.toTime.hour}:${g.toTime.minute}",
        'place': g.place,
      },
      where: 'id = ?',
      whereArgs: [g.id],
    );
  }

  Future<void> deleteGig(int id) async {
    final db = await database;
    await db.delete('gigs', where: 'id = ?', whereArgs: [id]);
  }

  Future<Set<int>> fetchGigAttendancePersonIds(int gigId) async {
    final db = await database;

    final rows = await db.query(
      'gig_attendance',
      where: 'gigId = ?',
      whereArgs: [gigId],
    );

    return rows.map((r) => r['personId'] as int).toSet();
  }

  Future<void> replaceGigAttendance(int gigId, Set<int> personIds) async {
    final db = await database;
    final batch = db.batch();

    batch.delete('gig_attendance', where: 'gigId = ?', whereArgs: [gigId]);

    for (final pid in personIds) {
      batch.insert('gig_attendance', {
        'gigId': gigId,
        'personId': pid,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  Future<Set<int>> fetchGigSongIds(int gigId) async {
    final db = await database;

    final rows = await db.query(
      'gig_songs',
      where: 'gigId = ?',
      whereArgs: [gigId],
    );

    return rows.map((r) => r['songId'] as int).toSet();
  }

  Future<void> replaceGigSongs(int gigId, Set<int> songIds) async {
    final db = await database;

    final batch = db.batch();

    batch.delete('gig_songs', where: 'gigId = ?', whereArgs: [gigId]);

    for (final sid in songIds) {
      batch.insert('gig_songs', {
        'gigId': gigId,
        'songId': sid,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  Future<List<Gig>> fetchGigs() async {
    final db = await database;
    final rows = await db.query('gigs');
    return rows.map((r) => Gig.fromMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchGigsWithStats() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        g.*,
        COUNT(DISTINCT ga.personId) as presentCount
      FROM gigs g
      LEFT JOIN gig_attendance ga ON ga.gigId = g.id
      GROUP BY g.id
      ORDER BY g.date DESC
    ''');
  }

  // ============================================================
  // ZOSTAVY
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchAttendanceReport(int? year) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT 
        p.id,
        p.firstName,
        p.lastName,
        COUNT(DISTINCT ra.rehearsalId) as attended,
        (
          SELECT COUNT(*)
          FROM rehearsals r2
          WHERE (? IS NULL OR strftime('%Y', r2.date) = ?)
          AND (
            (p.fromDate IS NULL OR p.fromDate <= r2.date) AND
            (p.toDate IS NULL OR p.toDate >= r2.date)
          )
        ) as total
      FROM persons p
      LEFT JOIN rehearsal_attendance ra 
        ON ra.personId = p.id
      LEFT JOIN rehearsals r 
        ON r.id = ra.rehearsalId
        AND (? IS NULL OR strftime('%Y', r.date) = ?)
      GROUP BY p.id
      ORDER BY 
        CASE 
          WHEN total = 0 THEN 0 
          ELSE CAST(attended AS REAL) / total 
        END DESC,
        p.lastName ASC,
        p.firstName ASC
    ''',
      [year?.toString(), year?.toString(), year?.toString(), year?.toString()],
    );
  }

  Future<List<Map<String, dynamic>>> fetchGigAttendanceReport(int? year) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT 
        p.id,
        p.firstName,
        p.lastName,
        COUNT(DISTINCT ga.gigId) as attended,
        (
          SELECT COUNT(*)
          FROM gigs g2
          WHERE (? IS NULL OR strftime('%Y', g2.date) = ?)
          AND (
            (p.fromDate IS NULL OR p.fromDate <= g2.date) AND
            (p.toDate IS NULL OR p.toDate >= g2.date)
          )
        ) as total
      FROM persons p
      LEFT JOIN gig_attendance ga 
        ON ga.personId = p.id
      LEFT JOIN gigs g 
        ON g.id = ga.gigId
        AND (? IS NULL OR strftime('%Y', g.date) = ?)
      GROUP BY p.id
      ORDER BY attended DESC
    ''',
      [year?.toString(), year?.toString(), year?.toString(), year?.toString()],
    );
  }
}
