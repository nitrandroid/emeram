class Song {
  final int? id; // nullable autoincrement
  final String title; // názov skladby
  final String? author; // autor hudby
  final String? arranger; // aranžér
  final String? language; // jazyk skladby (SK, EN, LAT, ...)
  final int categoryId; // FK na SongCategory
  final DateTime? firstRehearsalDate; // dátum prvej skúšky
  final DateTime createdAt; // dátum pridania do DB

  Song({
    this.id,
    required this.title,
    this.author,
    this.arranger,
    this.language,
    required this.categoryId,
    this.firstRehearsalDate,
    required this.createdAt,
  });

  Song copyWith({
    int? id,
    String? title,
    String? author,
    String? arranger,
    String? language,
    int? categoryId,
    DateTime? firstRehearsalDate,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      arranger: arranger ?? this.arranger,
      language: language ?? this.language,
      categoryId: categoryId ?? this.categoryId,
      firstRehearsalDate: firstRehearsalDate ?? this.firstRehearsalDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String?,
      arranger: map['arranger'] as String?,
      language: map['language'] as String?,
      categoryId: map['categoryId'] as int,
      firstRehearsalDate: map['firstRehearsalDate'] != null
          ? DateTime.parse(map['firstRehearsalDate'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'author': author,
      'arranger': arranger,
      'language': language,
      'categoryId': categoryId,
      'firstRehearsalDate': firstRehearsalDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };

    final v = id; // kvôli Dart analýze, rovnaký štýl ako pri Category
    if (v != null) {
      map['id'] = v;
    }

    return map;
  }
}
