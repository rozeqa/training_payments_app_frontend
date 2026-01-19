import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/user.dart';

class PersonDetailScreen extends StatelessWidget {
  final String userId;
  const PersonDetailScreen({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final User? user = dp.users.where((u) => u.id == userId).cast<User?>().firstOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Szczegóły')),
        body: const Center(child: Text('Nie znaleziono użytkownika')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opłacone treningi: ${user.paidSessions}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),

            if (user.paidSessions <= 1)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.orange[100],
                child: Text(
                  user.paidSessions == 0
                      ? 'Uwaga: brak opłaconych treningów'
                      : 'Ostatni opłacony trening — przypomnij o wpłacie',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
