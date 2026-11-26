import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class BulkItemUpdateScreen extends StatefulWidget {
  const BulkItemUpdateScreen({super.key});

  @override
  State<BulkItemUpdateScreen> createState() => _BulkItemUpdateScreenState();
}

class _BulkItemUpdateScreenState extends State<BulkItemUpdateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _stockControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final items = context.read<AppProvider>().items;
    for (var it in items) {
      _priceControllers[it.id] = TextEditingController(text: it.salePrice.toStringAsFixed(2));
      _stockControllers[it.id] = TextEditingController(text: it.stockQuantity.toStringAsFixed(1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _priceControllers.values) {
      c.dispose();
    }
    for (var c in _stockControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Item Updater'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'BULK PRICE UPDATE'),
            Tab(text: 'BULK STOCK UPDATE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Bulk Price Update
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.amber.shade50,
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('Edit prices directly in the fields below and tap "Save All Prices"', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final ctrl = _priceControllers[item.id] ?? TextEditingController(text: item.salePrice.toString());

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('${item.category} • Current: ${AppTheme.currency.format(item.salePrice)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: ctrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'New Price (₹)',
                                  prefixText: '₹ ',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save All Prices'),
                  onPressed: () async {
                    final Map<String, double> updates = {};
                    _priceControllers.forEach((id, ctrl) {
                      final val = double.tryParse(ctrl.text);
                      if (val != null && val >= 0) updates[id] = val;
                    });
                    await provider.bulkUpdatePrices(updates);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All item prices updated in bulk!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          // 2. Bulk Stock Update
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.blue.shade50,
                child: const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(child: Text('Audit and adjust physical stock counts in bulk', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final ctrl = _stockControllers[item.id] ?? TextEditingController(text: item.stockQuantity.toString());

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Code: ${item.code} • In System: ${item.stockQuantity} ${item.unit}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: ctrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Stock (${item.unit})',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save All Stocks'),
                  onPressed: () async {
                    final Map<String, double> updates = {};
                    _stockControllers.forEach((id, ctrl) {
                      final val = double.tryParse(ctrl.text);
                      if (val != null) updates[id] = val;
                    });
                    await provider.bulkUpdateStock(updates);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All stock quantities updated in bulk!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
