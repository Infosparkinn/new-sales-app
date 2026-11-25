import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/party.dart';
import '../../models/transaction_record.dart';
import '../../providers/app_provider.dart';

class AddPaymentOutDialog extends StatefulWidget {
  final Party? preselectedSupplier;

  const AddPaymentOutDialog({super.key, this.preselectedSupplier});

  @override
  State<AddPaymentOutDialog> createState() => _AddPaymentOutDialogState();
}

class _AddPaymentOutDialogState extends State<AddPaymentOutDialog> {
  final Uuid _uuid = const Uuid();
  Party? _selectedParty;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _paymentMode = 'bank';
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedParty = widget.preselectedSupplier;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final suppliers = provider.suppliers;

    if (_selectedParty == null && suppliers.isNotEmpty) {
      _selectedParty = suppliers.first;
    }

    return AlertDialog(
      title: const Text('Record Payment Out (To Supplier)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Party>(
              value: _selectedParty,
              decoration: const InputDecoration(labelText: 'Select Supplier *', prefixIcon: Icon(Icons.business_rounded)),
              items: suppliers.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.name} (Payable: ${AppTheme.currency.format(p.currentBalance.abs())})'),
                );
              }).toList(),
              onChanged: (p) => setState(() => _selectedParty = p),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount Paid (₹) *', prefixText: '₹ ', prefixIcon: Icon(Icons.payments_rounded)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Bank Transfer / NEFT / RTGS')),
                DropdownMenuItem(value: 'gpay', child: Text('Google Pay / UPI')),
                DropdownMenuItem(value: 'cash', child: Text('Cash in Hand')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _paymentMode = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refController,
              decoration: const InputDecoration(labelText: 'Cheque / UTR / Reference No.', prefixIcon: Icon(Icons.tag_rounded)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Remarks / Bill Reference', prefixIcon: Icon(Icons.notes_rounded)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
          onPressed: () async {
            final amt = double.tryParse(_amountController.text) ?? 0.0;
            if (_selectedParty == null || amt <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier and valid payment amount.')));
              return;
            }

            final txn = TransactionRecord(
              id: _uuid.v4(),
              firmId: provider.activeFirm.id,
              date: _paymentDate,
              type: 'payment_out',
              partyId: _selectedParty!.id,
              partyName: _selectedParty!.name,
              amount: amt,
              paymentMode: _paymentMode,
              referenceId: _refController.text.trim(),
              description: _descController.text.trim(),
            );

            // Update supplier balance (reducing payable)
            final updatedSupplier = _selectedParty!.copyWith(
              currentBalance: _selectedParty!.currentBalance + amt,
            );
            await provider.saveParty(updatedSupplier);
            await provider.addTransaction(txn);

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recorded Payment Out of ₹$amt to ${_selectedParty!.name}!')));
            }
          },
          child: const Text('Save Payment Out'),
        ),
      ],
    );
  }
}
