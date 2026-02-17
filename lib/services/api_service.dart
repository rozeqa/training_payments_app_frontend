import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/training.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://training-payment-app.onrender.com',
  );

  // USERS
  static Future<List<User>> fetchUsers() async {

    final res = await http.get(Uri.parse('$baseUrl/users'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load users: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  // TRAININGS
  static Future<List<Training>> fetchTrainings() async {
    final res = await http.get(Uri.parse('$baseUrl/trainings'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load trainings: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Training.fromJson(e as Map<String, dynamic>)).toList();
  }

  // PAYMENTS (POST /payments)
  static Future<void> createPayment({
    required String userId,
    required int sessions,
    num amount = 0,
    DateTime? date,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user': userId,
        'sessions': sessions,
        'amount': amount,
        'date': '${(date ?? DateTime.now()).year.toString().padLeft(4,'0')}-'
          '${(date ?? DateTime.now()).month.toString().padLeft(2,'0')}-'
          '${(date ?? DateTime.now()).day.toString().padLeft(2,'0')}',
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create payment: ${res.statusCode} ${res.body}');
    }
  }


  // ASSIGN (POST /trainings/:id/assign)
  static Future<void> assignUserToTraining({
    required String trainingId,
    required String userId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trainings/$trainingId/assign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to assign user: ${res.statusCode} ${res.body}');
    }
  }

  // REPORT (GET /payments/report?year=Y&month=M) - backend zwraca JSON listę płatności
  static Future<String> fetchMonthlyReportCsv(int year, int month) async {
    final res = await http.get(Uri.parse('$baseUrl/payments/report?year=$year&month=$month'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load report: ${res.statusCode} ${res.body}');
    }

    final List data = jsonDecode(res.body) as List;

    final buffer = StringBuffer();
    buffer.writeln('date,userName,sessions,amount');

    for (final item in data) {
      final m = item as Map<String, dynamic>;
      final user = (m['user'] as Map<String, dynamic>?);
      final date = (m['date'] ?? '').toString();
      final name = (user?['name'] ?? '').toString();
      final sessions = (m['sessions'] ?? 0).toString();
      final amount = (m['amount'] ?? 0).toString();

      buffer.writeln('$date,$name,$sessions,$amount');
    }

    return buffer.toString();
  }

  // POST /trainings/:id/unassign
  static Future<void> unassignUserFromTraining({
    required String trainingId,
    required String userId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trainings/$trainingId/unassign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to unassign user: ${res.statusCode} ${res.body}');
    }
  }

  // POST /trainings
  static Future<void> createTraining({
    required String title,
    required DateTime date,
    int? repeatCount,      
    int intervalWeeks = 1, 
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trainings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'date': date.toUtc().toIso8601String(),
        'participants': [],
        'repeat': {
          'enabled': repeatCount != null && repeatCount > 1,
          'count': repeatCount ?? 1,
          'intervalWeeks': intervalWeeks,
        }
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create training: ${res.statusCode} ${res.body}');
    }
  }


  // PUT /trainings/:id
  static Future<void> updateTraining({
    required String trainingId,
    required String title,
    required DateTime date,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/trainings/$trainingId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'date': date.toUtc().toIso8601String(),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update training: ${res.statusCode} ${res.body}');
    }
  }

  // DELETE /trainings/:id
  static Future<void> deleteTraining({
    required String trainingId,
  }) async {
    final res = await http.delete(Uri.parse('$baseUrl/trainings/$trainingId'));

    if (res.statusCode != 200) {
      throw Exception('Failed to delete training: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> createUser({
    required String name,
    int paidSessions = 0,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'paidSessions': paidSessions,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create user: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> updateUser({
    required String userId,
    required String name,
    required int paidSessions,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'paidSessions': paidSessions,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update user: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> deleteUser({
    required String userId,
  }) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete user: ${res.statusCode} ${res.body}');
    }
  }

  // REPORT (JSON) - lista płatności do tabeli
  static Future<List<Map<String, dynamic>>> fetchMonthlyReportPayments(int year, int month) async {
    final res = await http.get(Uri.parse('$baseUrl/payments/report?year=$year&month=$month'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load report: ${res.statusCode} ${res.body}');
    }

    final List data = jsonDecode(res.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

}


