import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/data_provider.dart';
import '../models/training.dart';
import '../models/user.dart';
import '../widgets/more_menu.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  Map<DateTime, List<Training>> events = {};

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    final dp = context.read<DataProvider>();
    await dp.refreshTrainings();

    final Map<DateTime, List<Training>> map = {};
    for (final t in dp.trainings) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(day, () => []).add(t);
    }

    if (mounted) setState(() => events = map);
  }

  List<Training> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  bool _isAlreadyAssigned(Training t, String userId) {
    return t.participants.any((u) => u.id == userId);
  }

  Future<void> _showAddTrainingDialog() async {
    final dp = context.read<DataProvider>();
    final day = _selected ?? _focused;

    final titleCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);

    bool repeatEnabled = false;
    int repeatCount = 4; // domyślnie 4 wystąpienia

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Dodaj trening'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Rodzaj / tytuł treningu',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Godzina: ${selectedTime.format(ctx)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                        child: const Text('Zmień'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Powtarzaj co tydzień'),
                    value: repeatEnabled,
                    onChanged: (v) => setDialogState(() => repeatEnabled = v),
                  ),
                  if (repeatEnabled)
                    Row(
                      children: [
                        const Text('Ile razy:'),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: repeatCount,
                          items: List.generate(20, (i) => i + 2)
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setDialogState(() => repeatCount = v);
                          },
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      final title = titleCtrl.text.trim();
      if (title.isEmpty) return;

      final date = DateTime(
        day.year,
        day.month,
        day.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      try {
        await dp.createTraining(
          title,
          date,
          repeatCount: repeatEnabled ? repeatCount : null,
        );

        await _loadTrainings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dodano trening')),
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
  }

  Future<void> _showEditTrainingDialog(Training t) async {
    final dp = context.read<DataProvider>();
    final titleCtrl = TextEditingController(text: t.title);
    TimeOfDay selectedTime = TimeOfDay(hour: t.date.hour, minute: t.date.minute);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Edytuj trening'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Tytuł'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Godzina: ${selectedTime.format(ctx)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                        child: const Text('Zmień'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      final title = titleCtrl.text.trim();
      if (title.isEmpty) return;

      final newDate = DateTime(
        t.date.year,
        t.date.month,
        t.date.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      try {
        await dp.updateTraining(t.id, title, newDate);
        await _loadTrainings();
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
  }

  Future<void> _deleteTraining(Training t) async {
    final dp = context.read<DataProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć trening?'),
        content: const Text(
          'Osobom zapisanym do treningu wróci 1 opłacony trening do puli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await dp.deleteTraining(t.id);
        await _loadTrainings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usunięto trening')),
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
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final day = _selected ?? _focused;
    final dayEvents = _getEventsForDay(day);

    return Stack(
      children: [
        Column(
          children: [
            TableCalendar(
              focusedDay: _focused,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              locale: 'pl_PL',
              selectedDayPredicate: (d) => isSameDay(_selected, d),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selected = selected;
                  _focused = focused;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
              eventLoader: _getEventsForDay,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTrainings,
                child: ListView.builder(
                  itemCount: dayEvents.length,
                  itemBuilder: (_, i) {
                    final t = dayEvents[i];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(_formatTime(t.date)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  child: const Text('Przypisz'),
                                  onPressed: () async {
                                    if (dp.users.isEmpty) {
                                      try {
                                        await dp.refreshUsers();
                                      } catch (_) {}
                                    }

                                    final chosenUserId = await showDialog<String>(
                                      context: context,
                                      builder: (ctx) {
                                        return SimpleDialog(
                                          title: const Text('Wybierz osobę'),
                                          children: dp.users.map((u) {
                                            final already = _isAlreadyAssigned(t, u.id);
                                            final noPaid = u.paidSessions <= 0;
                                            final disabled = already || noPaid;

                                            String suffix = '';
                                            if (already) suffix = ' ✓';
                                            if (noPaid) suffix = ' (0 opł.)';

                                            return SimpleDialogOption(
                                              onPressed: disabled
                                                  ? null
                                                  : () => Navigator.pop(ctx, u.id),
                                              child: Text('${u.name} (${u.paidSessions})$suffix'),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    );

                                    if (chosenUserId != null) {
                                      try {
                                        await dp.assign(chosenUserId, t.id);
                                        await _loadTrainings();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Przypisano (−1 opł.)')),
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
                                  },
                                ),
                                MoreMenu(
                                  onEdit: () => _showEditTrainingDialog(t),
                                  onDelete: () => _deleteTraining(t),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (t.participants.isEmpty)
                              const Text(
                                'Brak przypisanych osób',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: t.participants.map((User u) {
                                  return InputChip(
                                    label: Text(u.name),
                                    onDeleted: () async {
                                      try {
                                        await dp.unassign(u.id, t.id);
                                        await _loadTrainings();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Usunięto (+1 opł.)')),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Błąd: $e')),
                                          );
                                        }
                                      }
                                    },
                                    deleteIcon: const Icon(Icons.close),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            tooltip: "Dodaj trening",
            onPressed: _showAddTrainingDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
