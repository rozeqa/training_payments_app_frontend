import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../reports/hours_register_pdf.dart';
import '../models/training.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> payments = [];

  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadReport() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data =
          await ApiService.fetchMonthlyReportPayments(selectedYear, selectedMonth);
      setState(() => payments = data);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  /// Liczenie godzin wg Twojej reguły:
  /// - czas treningu: osoby/2 (2 osoby = 1h)
  /// - + 1h dojazdu, jeśli w danym dniu był trening
  /// Przykład: 4 osoby => 4/2 + 1 = 3h
  Future<void> _generateHoursRegisterPdf() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final List<Training> trainings = await ApiService.fetchTrainings();

      final Map<int, int> peopleByDay = {}; // dzień -> suma osób (z treningów tego dnia)

      for (final t in trainings) {
        final dt = t.date.toLocal();
        if (dt.year != selectedYear || dt.month != selectedMonth) continue;

        final day = dt.day;

        final int peopleCount = (t.participants).length;
        if (peopleCount <= 0) continue;

        peopleByDay[day] = (peopleByDay[day] ?? 0) + peopleCount;
      }

      // dzień -> godziny
      final Map<int, num> hoursByDay = {};
      for (final entry in peopleByDay.entries) {
        final day = entry.key;
        final people = entry.value;

        final num trainingHours = people / 2.0;
        final num travelHours = people > 0 ? 1 : 0;

        hoursByDay[day] = trainingHours + travelHours;
      }

      await HoursRegisterPdf.generateAndShare(
        year: selectedYear,
        month: selectedMonth,
        hoursByDay: hoursByDay,
      );

    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<int>(
              value: selectedYear,
              items: [
                for (var y = DateTime.now().year - 2; y <= DateTime.now().year; y++)
                  DropdownMenuItem(value: y, child: Text('$y'))
              ],
              onChanged: (v) => setState(() => selectedYear = v!),
            ),
            DropdownButton<int>(
              value: selectedMonth,
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    child: Text(DateFormat.MMMM('pl').format(DateTime(0, m))),
                  )
              ],
              onChanged: (v) => setState(() => selectedMonth = v!),
            ),
            ElevatedButton(
              onPressed: _loadReport,
              child: const Text('Pobierz raport'),
            ),
            OutlinedButton.icon(
              onPressed: _generateHoursRegisterPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Rejestr godzin (PDF)'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),

        if (!loading && error != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(child: Text('Błąd: $error')),
          ),

        if (!loading && error == null)
          payments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: Text('Brak danych')),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Data wpłaty')),
                      DataColumn(label: Text('Osoba')),
                      DataColumn(numeric: true, label: Text('Kwota wpłaty (zł)')),
                    ],
                    rows: payments.map((m) {
                      final user = (m['user'] as Map<String, dynamic>?);
                      final name = (user?['name'] ?? '-').toString();

                      final dateStr = (m['date'] ?? '').toString();
                      final date = DateTime.tryParse(dateStr);

                      final amount = (m['amount'] ?? 0);
                      final dateText = date == null ? '-' : ymd(date);

                      return DataRow(
                        cells: [
                          DataCell(Text(dateText)),
                          DataCell(Text(name)),
                          DataCell(Text(amount.toString())),
                        ],
                      );
                    }).toList(),
                  ),
                ),
      ],
    );
  }
}
