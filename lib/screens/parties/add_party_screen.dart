import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';

class AddPartyScreen extends StatefulWidget {
  final Party? partyToEdit;
  final String initialType;

  const AddPartyScreen({super.key, this.partyToEdit, this.initialType = 'customer'});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;
  late TextEditingController _openingBalanceController;
  late TextEditingController _creditLimitController;

  late String _partyType;
  String _state = 'Tamil Nadu';
  bool _toReceive = true; // true = To Receive, false = To Pay

  final List<String> _indianStates = [
    'Tamil Nadu', 'Karnataka', 'Kerala', 'Andhra Pradesh', 'Telangana',
    'Maharashtra', 'Gujarat', 'Delhi', 'Uttar Pradesh', 'West Bengal',
    'Rajasthan', 'Madhya Pradesh', 'Punjab', 'Haryana', 'Bihar', 'Odisha',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.partyToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _gstinController = TextEditingController(text: p?.gstin ?? '');
    _openingBalanceController = TextEditingController(
      text: p != null && p.openingBalance != 0 ? p.openingBalance.abs().toString() : '',
    );
    _creditLimitController = TextEditingController(
      text: p != null && p.creditLimit != 0 ? p.creditLimit.toString() : '',
    );
    _partyType = p?.partyType ?? widget.initialType;
    _state = p?.state ?? 'Tamil Nadu';
    if (!_indianStates.contains(_state)) {
      _indianStates.add(_state);
    }
    if (p != null) {
      _toReceive = p.openingBalance >= 0;
    } else {
      _toReceive = _partyType != 'supplier';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _openingBalanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.partyToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Party' : 'Add Party'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Party Type Selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Customer')),
                    selected: _partyType == 'customer',
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: _partyType == 'customer' ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _partyType = 'customer';
                          if (widget.partyToEdit == null) _toReceive = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Supplier')),
                    selected: _partyType == 'supplier',
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: _partyType == 'supplier' ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _partyType = 'supplier';
                          if (widget.partyToEdit == null) _toReceive = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Basic Info
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Party / Business Name *', prefixIcon: Icon(Icons.person_outline)),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter party name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Billing Address', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _state,
              decoration: const InputDecoration(labelText: 'State (Place of Supply) *', prefixIcon: Icon(Icons.map_outlined)),
              items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _state = val ?? _state),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gstinController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'GSTIN (Optional)',
                hintText: 'e.g. 33AAAAA0000A1Z5',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Balance Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OPENING BALANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _openingBalanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          ChoiceChip(
                            label: const Text("To Receive"),
                            selected: _toReceive,
                            selectedColor: AppTheme.successGreen.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _toReceive ? AppTheme.successGreen : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) => setState(() => _toReceive = true),
                          ),
                          ChoiceChip(
                            label: const Text("To Pay"),
                            selected: !_toReceive,
                            selectedColor: AppTheme.dangerRed.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: !_toReceive ? AppTheme.dangerRed : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) => setState(() => _toReceive = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveParty,
              child: Text(isEditing ? 'Update Party' : 'Save Party'),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _saveParty() async {
    if (_formKey.currentState?.validate() != true) return;

    final openAmt = double.tryParse(_openingBalanceController.text) ?? 0.0;
    final balance = _toReceive ? openAmt : -openAmt;
    final creditLimit = double.tryParse(_creditLimitController.text) ?? 0.0;

    final party = Party(
      id: widget.partyToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      state: _state,
      gstin: _gstinController.text.trim().toUpperCase(),
      partyType: _partyType,
      openingBalance: balance,
      currentBalance: widget.partyToEdit != null ? widget.partyToEdit!.currentBalance : balance,
      creditLimit: creditLimit,
    );

    final provider = context.read<AppProvider>();
    await provider.saveParty(party);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Party "${party.name}" saved successfully!')),
      );
    }
  }
}
