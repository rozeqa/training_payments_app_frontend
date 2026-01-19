class Person {
  final int id;
  final String firstName;
  final String lastName;
  int paidTrainings; // ile opłaconych treningów "na przód"

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.paidTrainings,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      paidTrainings: json['paidTrainings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'paidTrainings': paidTrainings,
      };

  String get fullName => '$firstName $lastName';
}
