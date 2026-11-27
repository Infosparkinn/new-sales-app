import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/fixed_asset.dart';
import '../../providers/app_provider.dart';

class FixedAssetsScreen extends StatefulWidget {
  const FixedAssetsScreen({super.key});

  @override
  State<FixedAssetsScreen> createState() => _FixedAssetsScreenState();
}

class _FixedAssetsScreenState extends State<FixedAssetsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final assets = provider.fixedAssets;
    final totalBookValue = assets.fold(0.0, (sum, a) => sum + a.currentBookValue);
    final totalCost = assets.fold(0.0, (sum, a) => sum + a.purchaseAmount);
    final totalDepreciation = totalCost - totalBookValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed Assets Register'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Asset',
            onPressed: () => _showAddAssetDialog(context, provider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'ACTIVE ASSETS (${assets.length})'),
            Tab(text: 'DEPRECIATION REGISTER'),
            Tab(text: 'ASSET CATEGORIES'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Advance Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.8))),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryCol('TOTAL ASSETS', '${assets.length} items', AppTheme.primary),
                Container(width: 1, height: 28, color: AppTheme.border),
                _summaryCol('ORIGINAL COST', AppTheme.shortCurrency.format(totalCost), Colors.black87),
                Container(width: 1, height: 28, color: AppTheme.border),
                _summaryCol('CURRENT BOOK VALUE', AppTheme.currency.format(totalBookValue), AppTheme.successGreen),
              ],
            ),
          ),

          // 2. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Active Assets List
                _buildAssetsList(assets, provider),

                // Tab 2: Depreciation Register
                _buildDepreciationTab(assets, totalCost, totalDepreciation, totalBookValue),

                // Tab 3: Asset Categories
                _buildCategoriesTab(assets),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Fixed Asset', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showAddAssetDialog(context, provider),
        ),
      ),
    );
  }

  Widget _buildAssetsList(List<FixedAsset> assets, AppProvider provider) {
    if (assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.precision_manufacturing_outlined, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              const Text('No fixed assets recorded yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Record business machinery, vehicles, office electronics, and furniture', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Asset'),
                onPressed: () => _showAddAssetDialog(context, provider),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: AppTheme.border.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Icon(_getIconForCategory(asset.category), color: Colors.indigo, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        '${asset.category} • Cost: ${AppTheme.currency.format(asset.purchaseAmount)} • Depr: ${asset.depreciationRatePercent}%/yr',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      if (asset.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(asset.notes, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppTheme.currency.format(asset.currentBookValue),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.successGreen),
                    ),
                    const SizedBox(height: 2),
                    const Text('Book Value', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepreciationTab(List<FixedAsset> assets, double totalCost, double totalDepr, double totalBookVal) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.modernCardDecoration(
            backgroundColor: Colors.white,
            borderRadius: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ANNUAL DEPRECIATION SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _deprRow('Gross Asset Value (Cost):', AppTheme.currency.format(totalCost), Colors.black87),
              const SizedBox(height: 6),
              _deprRow('Accumulated Depreciation:', AppTheme.currency.format(totalDepr > 0 ? totalDepr : 0.0), AppTheme.dangerRed),
              const Divider(height: 18),
              _deprRow('Net Book Value on Balance Sheet:', AppTheme.currency.format(totalBookVal), AppTheme.successGreen, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('ASSET DEPRECIATION SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...assets.map((a) {
          final deprAmount = a.purchaseAmount * (a.depreciationRatePercent / 100.0);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: AppTheme.modernCardDecoration(borderRadius: 12),
            child: ListTile(
              title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: Text('Rate: ${a.depreciationRatePercent}%/year • Cost: ${AppTheme.currency.format(a.purchaseAmount)}', style: const TextStyle(fontSize: 11)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('- ${AppTheme.currency.format(deprAmount)}/yr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.dangerRed)),
                  const Text('Annual Depreciation', style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoriesTab(List<FixedAsset> assets) {
    final categories = ['IT Equipment', 'Machinery', 'Vehicles', 'Furniture', 'Building / Office'];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: categories.map((cat) {
        final catAssets = assets.where((a) => a.category.toLowerCase() == cat.toLowerCase()).toList();
        final catValue = catAssets.fold(0.0, (sum, a) => sum + a.currentBookValue);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppTheme.modernCardDecoration(borderRadius: 14),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getIconForCategory(cat), color: AppTheme.primary, size: 20),
            ),
            title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${catAssets.length} assets registered', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            trailing: Text(
              AppTheme.currency.format(catValue),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _deprRow(String title, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppTheme.textPrimary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
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
          builder: (ctx, setDialogState) {
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
                          onChanged: (v) => setDialogState(() => category = v ?? category),
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
