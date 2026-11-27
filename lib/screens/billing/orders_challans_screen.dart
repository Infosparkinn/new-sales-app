import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/item.dart';
import '../../models/order_challan.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
import 'add_sale_screen.dart';

class OrdersChallansScreen extends StatefulWidget {
  const OrdersChallansScreen({super.key});

  @override
  State<OrdersChallansScreen> createState() => _OrdersChallansScreenState();
}

class _OrdersChallansScreenState extends State<OrdersChallansScreen> with SingleTickerProviderStateMixin {
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
    final docs = provider.ordersChallans;

    final deliveryChallans = docs.where((d) => d.type == 'delivery_challan' && d.isOpen).toList();
    final salesOrders = docs.where((d) => d.type == 'sale_order' && d.isOpen).toList();
    final convertedDocs = docs.where((d) => !d.isOpen).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Orders & Delivery Challans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Create Order or Challan',
            onPressed: () => _openCreateDialog(context, provider),
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
            Tab(text: 'DELIVERY CHALLANS (${deliveryChallans.length})'),
            Tab(text: 'SALES ORDERS (${salesOrders.length})'),
            Tab(text: 'CONVERTED (${convertedDocs.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocsList(deliveryChallans, 'No open delivery challans', 'Create goods dispatch challans and convert them into sales invoices in 1 click.', isDeliveryChallan: true),
          _buildDocsList(salesOrders, 'No open sales orders', 'Record customer orders and fulfill them with delivery challans or invoices.', isSaleOrder: true),
          _buildDocsList(convertedDocs, 'No converted documents', 'Completed orders and fulfilled delivery challans will appear here.'),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Order / Challan', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _openCreateDialog(context, provider),
        ),
      ),
    );
  }

  Widget _buildDocsList(List<OrderChallan> list, String emptyTitle, String emptySubtitle, {bool isDeliveryChallan = false, bool isSaleOrder = false}) {
    if (list.isEmpty) {
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
                child: Icon(
                  isDeliveryChallan ? Icons.local_shipping_outlined : (isSaleOrder ? Icons.assignment_outlined : Icons.check_circle_outline_rounded),
                  size: 48,
                  color: AppTheme.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(emptyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(emptySubtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final doc = list[index];
        final isChallan = doc.type == 'delivery_challan';

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: AppTheme.border.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isChallan ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (isChallan ? Colors.orange : Colors.blue).withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Icon(
                      isChallan ? Icons.local_shipping_rounded : Icons.assignment_rounded,
                      color: isChallan ? Colors.orange.shade800 : AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              doc.partyName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              doc.documentNumber,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${doc.items.length} items • ${AppTheme.dateFormat.format(doc.date)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      if (doc.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(doc.notes, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),

                // Action / Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppTheme.currency.format(doc.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    if (doc.isOpen)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('Convert to Sale', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddSaleScreen(initialChallan: doc),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text(
                          'CONVERTED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCreateDialog(BuildContext context, AppProvider provider) {
    String docType = _tabController.index == 1 ? 'sale_order' : 'delivery_challan';
    Party? selectedParty = provider.parties.isNotEmpty ? provider.parties.first : null;
    Item? selectedItem = provider.items.isNotEmpty ? provider.items.first : null;
    final qtyController = TextEditingController(text: '1');
    final rateController = TextEditingController(text: selectedItem != null ? selectedItem.salePrice.toString() : '0');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text('Create ${docType == 'delivery_challan' ? 'Delivery Challan' : 'Sales Order'}'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Document Type Selector
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'delivery_challan', label: Text('Delivery Challan', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: 'sale_order', label: Text('Sales Order', style: TextStyle(fontSize: 11))),
                        ],
                        selected: {docType},
                        onSelectionChanged: (set) {
                          setDialogState(() => docType = set.first);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Party Dropdown
                      DropdownButtonFormField<Party>(
                        value: selectedParty,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Customer / Party'),
                        items: provider.parties
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (p) => setDialogState(() => selectedParty = p),
                      ),
                      const SizedBox(height: 12),

                      // Item Dropdown
                      DropdownButtonFormField<Item>(
                        value: selectedItem,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Item'),
                        items: provider.items
                            .map((it) => DropdownMenuItem(value: it, child: Text('${it.name} (₹${it.salePrice.toInt()})', overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (it) {
                          setDialogState(() {
                            selectedItem = it;
                            if (it != null) rateController.text = it.salePrice.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Qty and Rate
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Quantity'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: rateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Unit Price (₹)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Notes / Vehicle / Dispatch Ref'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedParty == null || selectedItem == null) {
                      Navigator.pop(ctx);
                      return;
                    }
                    final qty = double.tryParse(qtyController.text) ?? 1.0;
                    final rate = double.tryParse(rateController.text) ?? selectedItem!.salePrice;
                    final total = qty * rate;
                    final docId = const Uuid().v4();
                    final docNum = docType == 'delivery_challan'
                        ? 'DC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                        : 'SO-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                    final item = OrderChallanItem(
                      id: const Uuid().v4(),
                      orderChallanId: docId,
                      itemId: selectedItem!.id,
                      itemName: selectedItem!.name,
                      quantity: qty,
                      unit: selectedItem!.unit,
                      unitPrice: rate,
                      taxRate: selectedItem!.taxRate,
                      totalAmount: total,
                    );

                    final doc = OrderChallan(
                      id: docId,
                      firmId: provider.activeFirm.id,
                      type: docType,
                      documentNumber: docNum,
                      partyId: selectedParty!.id,
                      partyName: selectedParty!.name,
                      partyPhone: selectedParty!.phone,
                      date: DateTime.now(),
                      totalAmount: total,
                      status: 'open',
                      notes: notesController.text.trim(),
                      items: [item],
                    );

                    await provider.saveOrderChallan(doc);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Created ${doc.documentNumber} successfully!')),
                      );
                    }
                  },
                  child: const Text('Save Document'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
