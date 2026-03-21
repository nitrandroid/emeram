class SongCategory {
  final int? id;
  final String name;
  final int color;
  final int songsCount;

  /// 🔥 Musí existovať!
  final bool isDefault;

  SongCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.songsCount,
    required this.isDefault,
  });

  SongCategory copyWith({
    int? id,
    String? name,
    int? color,
    int? songsCount,
    bool? isDefault,
  }) {
    return SongCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      songsCount: songsCount ?? this.songsCount,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory SongCategory.fromMap(Map<String, dynamic> map) {
    return SongCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as int,
      songsCount: map['songsCount'] as int,
      isDefault: (map['isDefault'] as int? ?? 0) == 1, // 🔥 tu sa to načíta
    );
  }
}
