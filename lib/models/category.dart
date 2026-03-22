class Category {
  final int? id;
  final String name;
  final int color;
  final bool isDefault;
  final int singersCount;

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
      name: map['name'],
      color: map['color'],
      isDefault: map['isDefault'] == 1,
      singersCount: map['singersCount'] as int,
      activeCount: 0,
      inactiveCount: 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'color': color,
      'is_default': isDefault ? 1 : 0,
      'singersCount': singersCount,
    };

    final v = id;
    if (v != null) {
      map['id'] = v;
    }

    return map;
  }
}