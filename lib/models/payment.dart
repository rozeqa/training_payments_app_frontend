class Payment {
  final int id;
  final int personId;
  final int count;
  final DateTime date;

  Payment({
    required this.id,
    required this.personId,
    required this.count,
    required this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      personId: json['personId'],
      count: json['count'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'count': count,
        'date': date.toIso8601String(),
      };
}
