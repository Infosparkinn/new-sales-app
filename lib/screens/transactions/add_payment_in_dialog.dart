import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../models/transaction_record.dart';
import '../../providers/app_provider.dart';

class AddPaymentInDialog extends StatefulWidget {
  final Party? defaultParty;

  const AddPaymentInDialog({super.key, this.defaultParty});

  @override
  State<AddPaymentInDialog> createState() => _AddPaymentInDialogState();
}

class _AddPaymentInDialogState extends State<AddPaymentInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  Party? _selectedParty;
  String _paymentMode = 'cash';

  @override
  void initState() {
    super.initState();
    _selectedParty = widget.defaultParty;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final customers = provider.customers;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payments_rounded, color: AppTheme.successGreen),
          SizedBox(width: 8),
          Text('Receive Payment (Payment In)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Party>(
                  value: _selectedParty ?? (customers.isNotEmpty ? customers.first : null),
                  decoration: const InputDecoration(labelText: 'Customer *'),
                  items: customers.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.name} (${AppTheme.shortCurrency.format(c.currentBalance)} Due)'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedParty = val),
                  validator: (val) => val == null ? 'Please select a customer' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount Received (₹) *',
                    prefixText: '₹ ',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter amount';
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'online', child: Text('Online / UPI')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  ],
                  onChanged: (val) => setState(() => _paymentMode = val ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Reference (Optional)',
                    hintText: 'e.g. GPay Ref #123456',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
          onPressed: () async {
            if (_formKey.currentState?.validate() != true) return;
            final amount = double.parse(_amountController.text);
            final party = _selectedParty ?? customers.first;

            final txn = TransactionRecord(
              id: const Uuid().v4(),
              date: DateTime.now(),
              type: 'payment_in',
              partyId: party.id,
              partyName: party.name,
              amount: amount,
              paymentMode: _paymentMode,
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : 'Payment received from ${party.name}',
            );

            await provider.addTransaction(txn);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Received ${AppTheme.currency.format(amount)} from ${party.name}!')),
              );
            }
          },
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
}
