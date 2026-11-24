import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../firms/firms_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;
  late TextEditingController _upiController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscController;
  late TextEditingController _termsController;
  late TextEditingController _prefixController;

  String _state = 'Tamil Nadu';

  final List<String> _indianStates = [
    'Tamil Nadu', 'Karnataka', 'Kerala', 'Andhra Pradesh', 'Telangana',
    'Maharashtra', 'Gujarat', 'Delhi', 'Uttar Pradesh', 'West Bengal',
    'Rajasthan', 'Madhya Pradesh', 'Punjab', 'Haryana', 'Bihar', 'Odisha',
  ];

  @override
  void initState() {
    super.initState();
    final b = context.read<AppProvider>().business;
    _nameController = TextEditingController(text: b.name);
    _phoneController = TextEditingController(text: b.phone);
    _emailController = TextEditingController(text: b.email);
    _addressController = TextEditingController(text: b.address);
    _gstinController = TextEditingController(text: b.gstin);
    _upiController = TextEditingController(text: b.upiId);
    _bankNameController = TextEditingController(text: b.bankName);
    _accountNoController = TextEditingController(text: b.accountNumber);
    _ifscController = TextEditingController(text: b.ifsc);
    _termsController = TextEditingController(text: b.termsAndConditions);
    _prefixController = TextEditingController(text: b.invoicePrefix);
    _state = b.state;
    if (!_indianStates.contains(_state)) _indianStates.add(_state);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _upiController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _termsController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Manage Firms',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmsManagementScreen()));
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Firm Switcher Banner
              Card(
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.business_rounded, color: AppTheme.primary),
                  title: Text('Active Firm: ${provider.activeFirm.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tap to switch between multiple companies'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmsManagementScreen()));
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Business Details
              const Text('BUSINESS INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Business / Shop Name *', prefixIcon: Icon(Icons.storefront_rounded)),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter business name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Business Address', prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _state,
                      decoration: const InputDecoration(labelText: 'Home State (GST) *'),
                      items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _state = val ?? _state),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _gstinController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'GSTIN Number', hintText: '33AABCS...'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bank & UPI Details
              const Text('BANK & UPI FOR INVOICES (QR CODE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _upiController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID (For Dynamic Bill QR Code)',
                  hintText: 'e.g. mobile@upi or name@okaxis',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name', prefixIcon: Icon(Icons.account_balance_outlined)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _accountNoController,
                      decoration: const InputDecoration(labelText: 'Bank Account Number'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ifscController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'IFSC Code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Enterprise Notifications & Branding Settings
              const Text('ENTERPRISE PREFERENCES & NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Remove Advertisement on Invoices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Hide "Generated with Vyapar App" watermark on PDF invoices', style: TextStyle(fontSize: 12)),
                      value: provider.hideBranding,
                      onChanged: (val) => provider.toggleHideBranding(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Send Transaction Message to Self', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Trigger notification/share alert when a new bill is created', style: TextStyle(fontSize: 12)),
                      value: provider.sendSelfNotification,
                      onChanged: (val) => provider.toggleSendSelfNotification(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Send Message on Updating Any Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Audit alerts whenever an invoice or payment is edited', style: TextStyle(fontSize: 12)),
                      value: provider.sendUpdateAlert,
                      onChanged: (val) => provider.toggleSendUpdateAlert(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Invoice Format
              const Text('INVOICE FORMAT & TERMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _prefixController,
                decoration: const InputDecoration(labelText: 'Invoice Number Prefix', hintText: 'INV-'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _termsController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Terms & Conditions Printed on Bill'),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Business Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSettings() async {
    if (_formKey.currentState?.validate() != true) return;

    final provider = context.read<AppProvider>();
    final current = provider.business;

    final updated = current.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      state: _state,
      gstin: _gstinController.text.trim().toUpperCase(),
      upiId: _upiController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNoController.text.trim(),
      ifsc: _ifscController.text.trim().toUpperCase(),
      termsAndConditions: _termsController.text.trim(),
      invoicePrefix: _prefixController.text.trim(),
    );

    await provider.updateBusiness(updated);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile updated successfully!')),
      );
    }
  }
}
