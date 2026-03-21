class Person {
  final int? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final int categoryId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final DateTime? createdAt;

  Person({
    this.id, // 🔥 už nie required
    required this.firstName,
    required this.lastName,
    required this.categoryId,
    this.email,
    this.phone,
    this.fromDate,
    this.toDate,
    this.createdAt,
  });

  Person copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    int? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      categoryId: categoryId ?? this.categoryId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
