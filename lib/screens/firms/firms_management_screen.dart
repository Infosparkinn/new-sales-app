import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/firm.dart';
import '../../providers/app_provider.dart';

class FirmsManagementScreen extends StatelessWidget {
  const FirmsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final firms = provider.firms;
    final activeFirmId = provider.activeFirm.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Multiple Companies / Firms'),
      ),
      body: firms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: firms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final firm = firms[index];
                final isActive = firm.id == activeFirmId;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isActive ? AppTheme.primary : AppTheme.border,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isActive ? AppTheme.primary : Colors.grey.shade200,
                      foregroundColor: isActive ? Colors.white : Colors.black87,
                      child: Text(firm.name.isNotEmpty ? firm.name[0] : 'F', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            firm.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? AppTheme.primary : Colors.black87),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                            child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (firm.gstin.isNotEmpty) Text('GSTIN: ${firm.gstin}', style: const TextStyle(fontSize: 12)),
                        Text('${firm.state} • Invoice Prefix: ${firm.invoicePrefix}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 28)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () async {
                              await provider.switchFirm(firm.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Switched to "${firm.name}"')),
                                );
                              }
                            },
                            child: const Text('Switch', style: TextStyle(fontSize: 12)),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Create New Firm'),
        onPressed: () => _showAddFirmDialog(context, provider),
      ),
    );
  }

  void _showAddFirmDialog(BuildContext context, AppProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final prefixCtrl = TextEditingController(text: 'INV-');
    String state = 'Tamil Nadu';

    final states = [
      'Tamil Nadu', 'Karnataka', 'Kerala', 'Andhra Pradesh', 'Telangana',
      'Maharashtra', 'Gujarat', 'Delhi', 'Uttar Pradesh', 'West Bengal',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add New Company / Firm'),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Firm / Business Name *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter firm name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Contact Phone'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: gstinCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'GSTIN (Optional)'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: state,
                          decoration: const InputDecoration(labelText: 'State (Place of Supply)'),
                          items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => state = v ?? state),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: prefixCtrl,
                          decoration: const InputDecoration(labelText: 'Invoice Prefix (e.g. BILL-)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    final newFirm = Firm(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      gstin: gstinCtrl.text.trim().toUpperCase(),
                      state: state,
                      invoicePrefix: prefixCtrl.text.trim().isNotEmpty ? prefixCtrl.text.trim() : 'INV-',
                      nextInvoiceNumber: 1,
                    );
                    await provider.saveFirm(newFirm);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create Firm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
