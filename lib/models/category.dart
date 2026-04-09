class Category {
  final int? id;
  final String name;
  final int color;
  final bool isDefault;
  final int singersCount;

  // runtime-only (nie sú v DB)
  final int activeCount;
  final int inactiveCount;

  Category({
    this.id,
    required this.name,
    required this.color,
    required this.isDefault,
    required this.singersCount,
    this.activeCount = 0,
    this.inactiveCount = 0,
  });

  Category copyWith({
    int? id,
    String? name,
    int? color,
    bool? isDefault,
    int? singersCount,
    int? activeCount,
    int? inactiveCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      singersCount: singersCount ?? this.singersCount,
      activeCount: activeCount ?? this.activeCount,
      inactiveCount: inactiveCount ?? this.inactiveCount,
    );
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      isDefault: (map['isDefault'] as int) == 1,
      singersCount: map['singersCount'] as int,
      activeCount: 0,
      inactiveCount: 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'color': color,
      'isDefault': isDefault ? 1 : 0,
      'singersCount': singersCount,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}