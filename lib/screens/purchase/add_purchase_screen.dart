import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/party.dart';
import '../../models/transaction_record.dart';
import '../../providers/app_provider.dart';
import '../parties/add_party_screen.dart';

class _PurchaseLine {
  String itemId;
  String itemName;
  double quantity;
  String unit;
  double purchaseRate;
  double taxRate;

  _PurchaseLine({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.purchaseRate,
    required this.taxRate,
  });

  double get subtotal => quantity * purchaseRate;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;
}

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final Uuid _uuid = const Uuid();
  Party? _selectedSupplier;
  final TextEditingController _billNumberController = TextEditingController();
  final List<_PurchaseLine> _lines = [];
  String _paymentMode = 'credit';
  bool _isItcEligible = true;

  @override
  void initState() {
    super.initState();
    _billNumberController.text = 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final suppliers = provider.suppliers;

    double grandSubtotal = _lines.fold(0.0, (sum, l) => sum + l.subtotal);
    double grandTax = _lines.fold(0.0, (sum, l) => sum + l.taxAmount);
    double grandTotal = grandSubtotal + grandTax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Purchase Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save Purchase',
            onPressed: _lines.isEmpty || _selectedSupplier == null ? null : () => _savePurchase(context, provider, grandTotal, grandTax),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SUPPLIER / VENDOR',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                        TextButton.icon(
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text('New Supplier', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPartyScreen(initialType: 'supplier')));
                          },
                        ),
                      ],
                    ),
                    DropdownButtonFormField<Party>(
                      value: _selectedSupplier,
                      decoration: const InputDecoration(hintText: 'Select supplier for purchase...'),
                      items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} ${s.gstin.isNotEmpty ? "(${s.gstin})" : ""}'))).toList(),
                      onChanged: (s) => setState(() => _selectedSupplier = s),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _billNumberController,
                            decoration: const InputDecoration(labelText: 'Supplier Bill / Inv No. *'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentMode,
                            decoration: const InputDecoration(labelText: 'Payment Status'),
                            items: const [
                              DropdownMenuItem(value: 'credit', child: Text('Credit (Pay Later)')),
                              DropdownMenuItem(value: 'bank', child: Text('Paid via Bank')),
                              DropdownMenuItem(value: 'cash', child: Text('Paid via Cash')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _paymentMode = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items in Purchase
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PURCHASE ITEMS & STOCK INWARD',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: () => _showAddItemDialog(context, provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_lines.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No items added to this purchase bill yet.', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text('Tap "+ Add Item" above to choose inventory items', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final line = _lines[i];
                  return Card(
                    child: ListTile(
                      title: Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        '${line.quantity} ${line.unit} × ₹${line.purchaseRate} + GST ${line.taxRate}% (₹${line.taxAmount.toStringAsFixed(2)})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppTheme.currency.format(line.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => setState(() => _lines.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            // Tax & ITC Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Input Tax Credit (ITC) Eligible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Claim GST on this purchase in GSTR-2 and GSTR-3B return', style: TextStyle(fontSize: 11)),
                      value: _isItcEligible,
                      onChanged: (val) => setState(() => _isItcEligible = val),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Taxable Subtotal:'),
                        Text(AppTheme.currency.format(grandSubtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GST Input Tax:'),
                        Text(AppTheme.currency.format(grandTax), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total (Payable):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(AppTheme.currency.format(grandTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lines.isEmpty || _selectedSupplier == null ? Colors.grey : AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _lines.isEmpty || _selectedSupplier == null ? null : () => _savePurchase(context, provider, grandTotal, grandTax),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('SAVE PURCHASE & UPDATE STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, AppProvider provider) {
    if (provider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add inventory items first.')));
      return;
    }

    var selectedItem = provider.items.first;
    final qtyController = TextEditingController(text: '10');
    final rateController = TextEditingController(text: selectedItem.purchasePrice.toString());
    double tax = selectedItem.taxRate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Item to Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<dynamic>(
                value: selectedItem,
                decoration: const InputDecoration(labelText: 'Choose Item *'),
                items: provider.items.map((it) => DropdownMenuItem(value: it, child: Text('${it.name} (Cost: ₹${it.purchasePrice})'))).toList(),
                onChanged: (it) {
                  if (it != null) {
                    setDlgState(() {
                      selectedItem = it;
                      rateController.text = it.purchasePrice.toString();
                      tax = it.taxRate;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Quantity', suffixText: selectedItem.unit),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Purchase Rate', prefixText: '₹ '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<double>(
                value: tax,
                decoration: const InputDecoration(labelText: 'GST Tax Rate %'),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                  DropdownMenuItem(value: 5.0, child: Text('5% GST')),
                  DropdownMenuItem(value: 12.0, child: Text('12% GST')),
                  DropdownMenuItem(value: 18.0, child: Text('18% GST')),
                  DropdownMenuItem(value: 28.0, child: Text('28% GST')),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => tax = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final q = double.tryParse(qtyController.text) ?? 1.0;
                final r = double.tryParse(rateController.text) ?? selectedItem.purchasePrice;
                setState(() {
                  _lines.add(_PurchaseLine(
                    itemId: selectedItem.id,
                    itemName: selectedItem.name,
                    quantity: q,
                    unit: selectedItem.unit,
                    purchaseRate: r,
                    taxRate: tax,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add to Bill'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchase(BuildContext context, AppProvider provider, double grandTotal, double grandTax) async {
    final supplier = _selectedSupplier!;
    final billNo = _billNumberController.text.trim().isNotEmpty ? _billNumberController.text.trim() : 'PUR-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Update stock quantities for each purchased item
      for (var line in _lines) {
        final existingItem = provider.items.firstWhere((i) => i.id == line.itemId);
        final updatedItem = existingItem.copyWith(
          stockQuantity: existingItem.stockQuantity + line.quantity,
          purchasePrice: line.purchaseRate,
        );
        await provider.saveItem(updatedItem);
      }

      // 2. Update supplier balance (if credit, increase payable)
      if (_paymentMode == 'credit') {
        final updatedSupplier = supplier.copyWith(
          currentBalance: supplier.currentBalance - grandTotal,
        );
        await provider.saveParty(updatedSupplier);
      }

      // 3. Record purchase transaction
      final txn = TransactionRecord(
        id: _uuid.v4(),
        firmId: provider.activeFirm.id.isNotEmpty ? provider.activeFirm.id : 'default_firm',
        date: DateTime.now(),
        type: 'purchase',
        partyId: supplier.id,
        partyName: supplier.name,
        amount: grandTotal,
        paymentMode: _paymentMode,
        referenceId: billNo,
        description: 'Inward Purchase Bill from ${supplier.name}',
        isItcEligible: _isItcEligible,
        gstin: supplier.gstin,
        taxRate: _lines.isNotEmpty ? _lines.first.taxRate : 0.0,
        cgstAmount: grandTax / 2,
        sgstAmount: grandTax / 2,
      );
      await provider.addTransaction(txn);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('Purchase Bill $billNo saved! Stock updated for ${_lines.length} items.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving purchase bill: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.dangerRed,
            content: Text('Failed to save purchase bill: $e'),
          ),
        );
      }
    }
  }
}
