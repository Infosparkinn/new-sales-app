import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/fixed_asset.dart';
import '../../providers/app_provider.dart';

class FixedAssetsScreen extends StatelessWidget {
  const FixedAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final assets = provider.fixedAssets;
    final totalBookValue = assets.fold(0.0, (sum, a) => sum + a.currentBookValue);
    final totalCost = assets.fold(0.0, (sum, a) => sum + a.purchaseAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed Assets Register'),
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryCol('TOTAL ASSETS', '${assets.length} items', AppTheme.primary),
                Container(width: 1, height: 28, color: AppTheme.border),
                _summaryCol('PURCHASE COST', AppTheme.shortCurrency.format(totalCost), Colors.black87),
                Container(width: 1, height: 28, color: AppTheme.border),
                _summaryCol('CURRENT BOOK VALUE', AppTheme.currency.format(totalBookValue), AppTheme.successGreen),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: assets.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No fixed assets recorded yet', style: TextStyle(color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text('Record machinery, computers, and furniture here', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: assets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade50,
                            child: Icon(_getIconForCategory(asset.category), color: Colors.indigo),
                          ),
                          title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${asset.category} • Cost: ${AppTheme.currency.format(asset.purchaseAmount)} • Depr: ${asset.depreciationRatePercent}%'),
                              if (asset.notes.isNotEmpty) Text(asset.notes, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppTheme.currency.format(asset.currentBookValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.successGreen)),
                              const Text('Book Value', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Fixed Asset'),
        onPressed: () => _showAddAssetDialog(context, provider),
      ),
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'it equipment':
        return Icons.computer_rounded;
      case 'vehicles':
        return Icons.local_shipping_rounded;
      case 'machinery':
        return Icons.precision_manufacturing_rounded;
      default:
        return Icons.chair_rounded;
    }
  }

  void _showAddAssetDialog(BuildContext context, AppProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final deprCtrl = TextEditingController(text: '10.0');
    final notesCtrl = TextEditingController();
    String category = 'IT Equipment';

    final categories = ['IT Equipment', 'Machinery', 'Vehicles', 'Furniture', 'Building / Office'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Fixed Asset'),
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
                          decoration: const InputDecoration(labelText: 'Asset Name *', hintText: 'e.g. Delivery Van TN-01'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter asset name' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(labelText: 'Asset Category'),
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => category = v ?? category),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: costCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Cost (₹) *'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                onChanged: (v) {
                                  if (valCtrl.text.isEmpty) valCtrl.text = v;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: valCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Current Book Value (₹) *'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: deprCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Depreciation Rate (% per year)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'Notes / Serial No.'),
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
                    final asset = FixedAsset(
                      id: const Uuid().v4(),
                      firmId: provider.activeFirm.id,
                      name: nameCtrl.text.trim(),
                      category: category,
                      purchaseDate: DateTime.now(),
                      purchaseAmount: double.parse(costCtrl.text),
                      currentBookValue: double.parse(valCtrl.text),
                      depreciationRatePercent: double.tryParse(deprCtrl.text) ?? 10.0,
                      notes: notesCtrl.text.trim(),
                    );
                    await provider.saveFixedAsset(asset);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Asset'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
