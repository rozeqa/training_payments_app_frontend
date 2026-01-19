class Assignment {
  final int id;
  final int personId;
  final int trainingId;

  Assignment({
    required this.id,
    required this.personId,
    required this.trainingId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      personId: json['personId'] as int,
      trainingId: json['trainingId'] as int,
    );
  }
}
