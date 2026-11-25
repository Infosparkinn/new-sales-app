import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
import 'invoice_preview_screen.dart';

class MobilePosScreen extends StatefulWidget {
  const MobilePosScreen({super.key});

  @override
  State<MobilePosScreen> createState() => _MobilePosScreenState();
}

class _MobilePosScreenState extends State<MobilePosScreen> {
  final Uuid _uuid = const Uuid();
  final Map<String, int> _cart = {}; // itemId -> quantity
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _selectedPaymentMode = 'cash';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.items.where((it) {
      final matchesSearch = it.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          it.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || it.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    final categories = ['All', ...provider.items.map((i) => i.category).where((c) => c.isNotEmpty).toSet()];

    // Calculate cart totals
    double cartSubtotal = 0.0;
    double cartTax = 0.0;
    int totalItemsCount = 0;

    _cart.forEach((itemId, qty) {
      final it = provider.items.firstWhere((i) => i.id == itemId, orElse: () => provider.items.first);
      final lineSubtotal = it.salePrice * qty;
      final lineTax = lineSubtotal * (it.taxRate / 100);
      cartSubtotal += lineSubtotal;
      cartTax += lineTax;
      totalItemsCount += qty;
    });

    final cartGrandTotal = cartSubtotal + cartTax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile POS • Quick Counter Billing'),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Cart',
              onPressed: () => setState(() => _cart.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category horizontal selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                      onSelected: (val) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search or scan barcode...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Items Grid
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No items found.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final qty = _cart[item.id] ?? 0;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _cart[item.id] = qty + 1;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: qty > 0 ? AppTheme.primary.withOpacity(0.06) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: qty > 0 ? AppTheme.primary : AppTheme.border, width: qty > 0 ? 1.5 : 1),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                                    child: const Icon(Icons.inventory_2_rounded, size: 14, color: AppTheme.primary),
                                  ),
                                  if (qty > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                                      child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(AppTheme.currency.format(item.salePrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom POS Billing Strip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$totalItemsCount items in cart', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                    Text('Total: ${AppTheme.currency.format(cartGrandTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 10),

                // Fast Payment Mode Selector
                Row(
                  children: [
                    _paymentChip('cash', 'CASH', Icons.payments_rounded, Colors.green),
                    const SizedBox(width: 6),
                    _paymentChip('gpay', 'G PAY / UPI', Icons.qr_code_2_rounded, Colors.blue),
                    const SizedBox(width: 6),
                    _paymentChip('card', 'CARD', Icons.credit_card_rounded, Colors.deepOrange),
                    const SizedBox(width: 6),
                    _paymentChip('credit', 'CREDIT', Icons.account_circle_rounded, Colors.purple),
                  ],
                ),
                const SizedBox(height: 10),

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cartGrandTotal > 0 ? AppTheme.accent : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: cartGrandTotal > 0 ? () => _checkoutPosBill(context, provider, cartGrandTotal, cartSubtotal, cartTax) : null,
                    icon: const Icon(Icons.print_rounded),
                    label: Text(
                      'CHECKOUT & PRINT ( ${AppTheme.currency.format(cartGrandTotal)} )',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentChip(String key, String label, IconData icon, Color color) {
    final isSelected = _selectedPaymentMode == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMode = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkoutPosBill(BuildContext context, AppProvider provider, double grandTotal, double subtotal, double tax) async {
    final invNum = await provider.getNextInvoiceNumber();
    final defaultParty = provider.customers.isNotEmpty ? provider.customers.first : Party(id: 'walk_in', name: 'Walk-in Retail Customer', partyType: 'customer');

    final invoiceItems = <InvoiceItem>[];
    _cart.forEach((itemId, qty) {
      final it = provider.items.firstWhere((i) => i.id == itemId, orElse: () => provider.items.first);
      invoiceItems.add(InvoiceItem(
        id: _uuid.v4(),
        invoiceId: '',
        itemId: it.id,
        itemName: it.name,
        quantity: qty.toDouble(),
        unit: it.unit,
        unitPrice: it.salePrice,
        purchasePrice: it.purchasePrice,
        taxRate: it.taxRate,
        cgstAmount: (it.salePrice * qty * (it.taxRate / 200)),
        sgstAmount: (it.salePrice * qty * (it.taxRate / 200)),
        totalAmount: (it.salePrice * qty) * (1 + it.taxRate / 100),
      ));
    });

    final invoice = Invoice(
      id: _uuid.v4(),
      firmId: provider.activeFirm.id,
      invoiceNumber: invNum,
      partyId: defaultParty.id,
      partyName: defaultParty.name,
      partyPhone: defaultParty.phone,
      invoiceDate: DateTime.now(),
      paymentMode: _selectedPaymentMode,
      subtotal: subtotal,
      cgstAmount: tax / 2,
      sgstAmount: tax / 2,
      totalAmount: grandTotal,
      receivedAmount: grandTotal,
      balanceAmount: 0.0,
      status: 'paid',
      notes: 'Quick POS Counter Sale',
      items: invoiceItems,
    );

    await provider.createInvoice(invoice);
    setState(() => _cart.clear());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('POS Invoice $invNum Generated Successfully!')));
      Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice)));
    }
  }
}
