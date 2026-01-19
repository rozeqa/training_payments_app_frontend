class User {
  final String id;
  final String name;
  final int paidSessions;

  User({
    required this.id,
    required this.name,
    required this.paidSessions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      paidSessions: (json['paidSessions'] ?? 0) as int,
    );
  }
}
