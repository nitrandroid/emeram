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
    this.id,
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

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      categoryId: map['categoryId'] as int,
      fromDate: map['fromDate'] != null
          ? DateTime.parse(map['fromDate'] as String)
          : null,
      toDate: map['toDate'] != null
          ? DateTime.parse(map['toDate'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'categoryId': categoryId,
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}