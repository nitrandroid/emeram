class Category {
  final int? id; // nullable for autoincrement
  final String name;
  final int color;
  final bool isDefault;
  final int singersCount;

  Category({
    this.id,
    required this.name,
    required this.color,
    required this.isDefault,
    required this.singersCount,
  });

  Category copyWith({
    int? id,
    String? name,
    int? color,
    bool? isDefault,
    int? singersCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      singersCount: singersCount ?? this.singersCount,
    );
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'],
      color: map['color'],
      isDefault: map['isDefault'] == 1,
      singersCount: map['singersCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'color': color,
      'is_default': isDefault ? 1 : 0,
      'singersCount': singersCount,
    };

    final v = id; // LOCAL VARIABLE REQUIRED BY DART
    if (v != null) {
      map['id'] = v;
    }

    return map;
  }
}
