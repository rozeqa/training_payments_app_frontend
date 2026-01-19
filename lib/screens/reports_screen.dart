import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

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
      final data = await ApiService.fetchMonthlyReportPayments(selectedYear, selectedMonth);
      setState(() => payments = data);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              DropdownButton<int>(
                value: selectedYear,
                items: [
                  for (var y = DateTime.now().year - 2; y <= DateTime.now().year; y++)
                    DropdownMenuItem(value: y, child: Text('$y'))
                ],
                onChanged: (v) => setState(() => selectedYear = v!),
              ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _loadReport, child: const Text('Pobierz raport')),
            ],
          ),
          const SizedBox(height: 12),

          if (loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!loading && error != null)
            Expanded(child: Center(child: Text('Błąd: $error'))),

          if (!loading && error == null)
            Expanded(
              child: payments.isEmpty
                  ? const Center(child: Text('Brak danych'))
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
            ),
        ],
      ),
    );
  }
}
