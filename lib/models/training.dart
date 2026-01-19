import 'user.dart';

class Training {
  final String id;
  final DateTime date;
  final String title;
  final List<User> participants;

  Training({
    required this.id,
    required this.date,
    required this.title,
    this.participants = const [],
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    final rawParticipants = (json['participants'] as List?) ?? [];

    return Training(
      id: json['_id']?.toString() ?? '',
      // KLUCZ: toLocal()
      date: DateTime.parse(json['date'].toString()).toLocal(),
      title: json['title']?.toString() ?? '',
      participants: rawParticipants
          .whereType<Map<String, dynamic>>()
          .map((u) => User.fromJson(u))
          .toList(),
    );
  }
}
