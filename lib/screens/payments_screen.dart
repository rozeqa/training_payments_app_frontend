import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  // cena dla Kasi B.
  static const String _discountUserId = '66b000000000000000000001';

  // ceny
  static const int _defaultPrice = 70;
  static const int _discountPrice = 50;

  int get _pricePerTraining =>
      (_selectedUserId == _discountUserId) ? _discountPrice : _defaultPrice;


  String? _selectedUserId;
  final TextEditingController _amountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  int get _amountPln => int.tryParse(_amountController.text.trim()) ?? 0;
  int get _trainings => _amountPln ~/ _pricePerTraining;
  int get _remainder => _amountPln % _pricePerTraining;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final canSubmit = _selectedUserId != null && _trainings >= 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedUserId,
            decoration: const InputDecoration(labelText: 'Wybierz osobę'),
            items: dp.users
                .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedUserId = v),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Kwota wpłaty (zł)',
              hintText: 'np. 280',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'To daje: $_trainings treningów'
              '${_remainder > 0 ? ' (pozostało $_remainder zł)' : ''}',
            ),
          ),

          const SizedBox(height: 12),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data wpłaty'),
            subtitle: Text(_fmt(_paymentDate)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _paymentDate = picked);
            },
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: canSubmit
                ? () async {
                    try {
                      await context.read<DataProvider>().addPayment(
                            _selectedUserId!,
                            trainings: _trainings,
                            amountPln: _amountPln,
                            date: _paymentDate,
                          );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Wpłata dodana')),
                      );
                      _amountController.clear();
                      setState(() {});
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Błąd: $e')),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Dodaj wpłatę'),
          ),
        ],
      ),
    );
  }
}
