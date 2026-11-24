import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/transaction_record.dart';
import '../../providers/app_provider.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _gstinController = TextEditingController();
  String _category = 'Electricity / Utilities';
  String _paymentMode = 'online';
  bool _isItcEligible = false;
  double _taxRate = 18.0;

  final List<String> _categories = [
    'Electricity / Utilities',
    'Shop Rent',
    'Tea & Refreshments',
    'Transportation & Fuel',
    'Staff Salary',
    'Packaging & Stationary',
    'Maintenance & Repairs',
    'Marketing & Ads',
    'Other Expense',
  ];

  final List<double> _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.money_off_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          const Text('Record Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Expense Category *'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _category = val ?? _category),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total Expense Amount (₹) *',
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
                  decoration: const InputDecoration(labelText: 'Paid Via'),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online / Bank / UPI')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash in Hand')),
                  ],
                  onChanged: (val) => setState(() => _paymentMode = val ?? 'online'),
                ),
                const SizedBox(height: 12),

                // Input Tax Credit (ITC) Toggle
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Input Tax Credit (ITC) Claimable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Claim GST back on this business expense in GSTR-2', style: TextStyle(fontSize: 11)),
                  value: _isItcEligible,
                  onChanged: (v) => setState(() => _isItcEligible = v ?? false),
                ),

                if (_isItcEligible) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gstinController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'Vendor GSTIN *', hintText: '33AAACT...'),
                          validator: (v) {
                            if (_isItcEligible && (v == null || v.isEmpty)) return 'GSTIN required for ITC';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          value: _taxRate,
                          decoration: const InputDecoration(labelText: 'GST Slab'),
                          items: _gstRates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}% GST'))).toList(),
                          onChanged: (v) => setState(() => _taxRate = v ?? 18.0),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes (Optional)',
                    hintText: 'e.g. Monthly commercial power tariff',
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
          onPressed: () async {
            if (_formKey.currentState?.validate() != true) return;
            final amount = double.parse(_amountController.text);

            double cgst = 0.0;
            double sgst = 0.0;
            if (_isItcEligible && _taxRate > 0) {
              final taxPart = amount - (amount / (1 + (_taxRate / 100.0)));
              cgst = taxPart / 2.0;
              sgst = taxPart / 2.0;
            }

            final txn = TransactionRecord(
              id: const Uuid().v4(),
              firmId: provider.activeFirm.id,
              date: DateTime.now(),
              type: 'expense',
              partyName: _category,
              amount: amount,
              paymentMode: _paymentMode,
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : 'Expense: $_category',
              isItcEligible: _isItcEligible,
              gstin: _gstinController.text.trim().toUpperCase(),
              taxRate: _taxRate,
              cgstAmount: cgst,
              sgstAmount: sgst,
            );

            await provider.addTransaction(txn);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Expense of ${AppTheme.currency.format(amount)} recorded${_isItcEligible ? " with ITC!" : "!"}')),
              );
            }
          },
          child: const Text('Save Expense'),
        ),
      ],
    );
  }
}
