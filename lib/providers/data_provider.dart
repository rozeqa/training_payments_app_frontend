import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/training.dart';
import '../services/api_service.dart';

class DataProvider extends ChangeNotifier {
  List<User> _users = [];
  List<Training> _trainings = [];
  bool loading = false;

  List<User> get users => _users;
  List<Training> get trainings => _trainings;

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();

    try {
      print("LOAD users...");
      _users = await ApiService.fetchUsers();
      print("OK users: ${_users.length}");

      print("LOAD trainings...");
      _trainings = await ApiService.fetchTrainings();
      print("OK trainings: ${_trainings.length}");
    } catch (e, st) {
      print("LOAD ERROR: $e");
      print(st);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsers() async {
    _users = await ApiService.fetchUsers();
    notifyListeners();
  }

  Future<void> refreshTrainings() async {
    _trainings = await ApiService.fetchTrainings();
    notifyListeners();
  }

  Future<void> addPayment(
    String userId, {
    required int trainings,
    required int amountPln,
    required DateTime date,
  }) async {
    await ApiService.createPayment(
      userId: userId,
      sessions: trainings,
      amount: amountPln,
      date: date,
    );
    await refreshUsers();
  }

  Future<void> assign(String userId, String trainingId) async {
    await ApiService.assignUserToTraining(userId: userId, trainingId: trainingId);
    await refreshUsers();
    await refreshTrainings();
  }

  Future<void> createTraining(String title, DateTime date, {int? repeatCount, int intervalWeeks = 1}) async {
    await ApiService.createTraining(
      title: title,
      date: date,
      repeatCount: repeatCount,
      intervalWeeks: intervalWeeks,
    );
    await refreshTrainings();
  }

  Future<void> unassign(String userId, String trainingId) async {
    await ApiService.unassignUserFromTraining(userId: userId, trainingId: trainingId);
    await refreshUsers();
    await refreshTrainings();
  }

  Future<void> updateTraining(String id, String title, DateTime date) async {
    await ApiService.updateTraining(trainingId: id, title: title, date: date);
    await refreshTrainings();
  }

  Future<void> deleteTraining(String id) async {
    await ApiService.deleteTraining(trainingId: id);
    await refreshUsers();    
    await refreshTrainings();
  }

  Future<void> createUser(String name, {int paidSessions = 0}) async {
    await ApiService.createUser(name: name, paidSessions: paidSessions);
    await refreshUsers();
    notifyListeners();
  }

  Future<void> updateUser(String id, {required String name, required int paidSessions}) async {
    await ApiService.updateUser(userId: id, name: name, paidSessions: paidSessions);
    await refreshUsers();
  }

  Future<void> deleteUser(String id) async {
    await ApiService.deleteUser(userId: id);
    await refreshUsers();
    await refreshTrainings();
  }
}
