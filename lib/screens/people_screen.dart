import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../models/user.dart';
import '../utils/colors.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({Key? key}) : super(key: key);

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  bool _loading = false;

  //progi kolorow
  Color _sessionsColor(int paid) {
    if (paid <= 0) return UiColors.danger;   // 0
    if (paid <= 2) return UiColors.warning;  // 1-2
    return UiColors.ok;                      // 3+
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await context.read<DataProvider>().refreshUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd ładowania osób: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddUserDialog() async {
    final dp = context.read<DataProvider>();
    final nameCtrl = TextEditingController();
    final paidCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dodaj osobę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Imię / nazwa'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: paidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Opłacone treningi (start)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dodaj')),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    final paid = int.tryParse(paidCtrl.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj nazwę osoby')),
      );
      return;
    }

    try {
      await dp.createUser(name, paidSessions: paid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodano osobę')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  Future<void> _showEditUserDialog(User u) async {
    final dp = context.read<DataProvider>();
    final nameCtrl = TextEditingController(text: u.name);
    final paidCtrl = TextEditingController(text: u.paidSessions.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edytuj osobę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Imię / nazwa'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: paidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Opłacone treningi'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Zapisz')),
        ],
      ),
    );

    if (ok != true) return;

    final newName = nameCtrl.text.trim();
    final newPaid = int.tryParse(paidCtrl.text.trim()) ?? u.paidSessions;

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nazwa nie może być pusta')),
      );
      return;
    }

    try {
      await dp.updateUser(u.id, name: newName, paidSessions: newPaid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zapisano zmiany')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(User u) async {
    final dp = context.read<DataProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć osobę?'),
        content: Text('Na pewno chcesz usunąć: "${u.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await dp.deleteUser(u.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usunięto osobę')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final List<User> users = dp.users;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Dodaj nową osobę',
              style: TextStyle(
                fontSize: 16,),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: "Dodaj nową osobę",
              icon: const Icon(Icons.person_add),
              onPressed: _showAddUserDialog,
            ),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _loading && users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Brak osób. Dodaj pierwszą osobę +')),
                    ],
                  )
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final statusColor = _sessionsColor(u.paidSessions);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?'),
                        ),
                        title: Text(u.name),
                        subtitle: Text(
                          'Opłacone treningi: ${u.paidSessions}',
                          style: TextStyle(color: statusColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edytuj',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditUserDialog(u),
                            ),
                            IconButton(
                              tooltip: 'Usuń',
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDeleteUser(u),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
