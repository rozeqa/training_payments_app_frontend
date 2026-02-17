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
  static const int _defaultPrice = 80;
  static const int _discountPrice = 60;

  String? _selectedUserId;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  DateTime _paymentDate = DateTime.now();

  int get _pricePerTraining =>
      (_selectedUserId == _discountUserId) ? _discountPrice : _defaultPrice;

  int get _amountPln => int.tryParse(_amountController.text.trim()) ?? 0;
  int get _trainings => _amountPln ~/ _pricePerTraining;
  int get _remainder => _amountPln % _pricePerTraining;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      // żeby pokazać/ukryć pasek "Anuluj/OK"
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _resetPerson() {
    setState(() => _selectedUserId = null);
  }

  void _cancelAmountEntry() {
    _amountController.clear();
    _amountFocusNode.unfocus(); // schowaj klawiaturę
    _resetPerson(); // wymaganie: anuluj = wyzeruj osobę
    setState(() {});
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
            focusNode: _amountFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Kwota wpłaty (zł)',
              hintText: 'np. 280',
              suffixIcon: _amountController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _cancelAmountEntry, // szybki "anuluj" też z pola
                    ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _amountFocusNode.unfocus(), // "Done" na klawiaturze
          ),

          // Pasek sterujący widoczny tylko gdy klawiatura jest otwarta (fokus na kwocie)
          if (_amountFocusNode.hasFocus) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: _cancelAmountEntry,
                  child: const Text('Anuluj'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _amountFocusNode.unfocus(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],

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

                      // wymaganie: po dodaniu wpłaty reset osoby + wyczyszczenie kwoty
                      _amountController.clear();
                      _resetPerson();
                      _amountFocusNode.unfocus();
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
