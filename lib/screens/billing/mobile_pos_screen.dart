import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
import '../../widgets/upi_qr_dialog.dart';
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
  double? _tenderedAmount;

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
    final bool isDesktop = kIsWeb ||
        (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ||
        MediaQuery.of(context).size.width >= 800;

    final double changeDue = (_tenderedAmount != null && _tenderedAmount! >= cartGrandTotal)
        ? (_tenderedAmount! - cartGrandTotal)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDesktop ? 'Desktop POS • Quick Counter Billing' : 'Mobile POS • Quick Counter Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Barcode Scanner / Quick Keypad',
            onPressed: () => _showBarcodeScannerDialog(context, provider),
          ),
          if (cartGrandTotal > 0)
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF4ADE80)),
              tooltip: 'Generate UPI QR',
              onPressed: () => _showUpiQr(context, provider, cartGrandTotal),
            ),
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Cart',
              onPressed: () => setState(() {
                _cart.clear();
                _tenderedAmount = null;
              }),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 900;

          if (isWideScreen) {
            // Dual Pane Layout for Desktop POS
            return Row(
              children: [
                // Left Pane: Items Catalog & Categories
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildCategorySelector(categories),
                      _buildSearchBar(),
                      Expanded(child: _buildItemsGrid(items)),
                    ],
                  ),
                ),
                // Divider
                Container(width: 1, color: AppTheme.border),
                // Right Pane: Active Cart Receipt Panel
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        // Cart Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: AppTheme.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, color: AppTheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Bill ($totalItemsCount items)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              if (_cart.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => setState(() => _cart.clear()),
                                  icon: const Icon(Icons.clear_all, size: 16, color: AppTheme.dangerRed),
                                  label: const Text('Clear', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),

                        // Cart Items List
                        Expanded(
                          child: _cart.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_shopping_cart_rounded, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 10),
                                      const Text('Cart is empty', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      const Text('Tap items on the left to add to bill', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _cart.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final itemId = _cart.keys.elementAt(idx);
                                    final qty = _cart[itemId]!;
                                    final it = provider.items.firstWhere((i) => i.id == itemId, orElse: () => provider.items.first);
                                    final lineTotal = (it.salePrice * qty) * (1 + it.taxRate / 100);

                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(it.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text('${AppTheme.currency.format(it.salePrice)} × $qty ${it.unit}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          // Quantity adjuster
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                color: Colors.grey.shade700,
                                                onPressed: () {
                                                  setState(() {
                                                    if (qty > 1) {
                                                      _cart[itemId] = qty - 1;
                                                    } else {
                                                      _cart.remove(itemId);
                                                    }
                                                  });
                                                },
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                color: AppTheme.primary,
                                                onPressed: () {
                                                  setState(() => _cart[itemId] = qty + 1);
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            AppTheme.currency.format(lineTotal),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Bottom Billing Controls
                        _buildBottomBillingStrip(context, provider, cartGrandTotal, cartSubtotal, cartTax, changeDue),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Single Column Layout for Mobile & Narrow Screens
          return Column(
            children: [
              _buildCategorySelector(categories),
              _buildSearchBar(),
              Expanded(child: _buildItemsGrid(items)),
              _buildBottomBillingStrip(context, provider, cartGrandTotal, cartSubtotal, cartTax, changeDue),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(List<String> categories) {
    return Container(
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
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (val) => setState(() => _selectedCategory = cat),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search product or code...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildItemsGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items found.', style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
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
              border: Border.all(
                color: qty > 0 ? AppTheme.primary : AppTheme.border,
                width: qty > 0 ? 1.5 : 1,
              ),
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
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  AppTheme.currency.format(item.salePrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBillingStrip(
    BuildContext context,
    AppProvider provider,
    double cartGrandTotal,
    double cartSubtotal,
    double cartTax,
    double changeDue,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_cart.values.fold<int>(0, (s, q) => s + q)} items in cart',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                'Total: ${AppTheme.currency.format(cartGrandTotal)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Payment Mode Selector
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

          // Cash Tender Quick Calculator
          if (_selectedPaymentMode == 'cash' && cartGrandTotal > 0) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Tender: ', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  _quickTenderChip(cartGrandTotal, 'Exact'),
                  _quickTenderChip(100.0, '₹100'),
                  _quickTenderChip(200.0, '₹200'),
                  _quickTenderChip(500.0, '₹500'),
                  _quickTenderChip(2000.0, '₹2000'),
                  if (_tenderedAmount != null && _tenderedAmount! >= cartGrandTotal)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Change: ${AppTheme.currency.format(changeDue)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Checkout Button & UPI Quick Action
          Row(
            children: [
              if (_selectedPaymentMode == 'gpay') ...[
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                  tooltip: 'Show Customer UPI QR',
                  onPressed: cartGrandTotal > 0 ? () => _showUpiQr(context, provider, cartGrandTotal) : null,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cartGrandTotal > 0 ? AppTheme.accent : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: cartGrandTotal > 0
                        ? () => _checkoutPosBill(context, provider, cartGrandTotal, cartSubtotal, cartTax)
                        : null,
                    icon: const Icon(Icons.print_rounded),
                    label: Text(
                      'CHECKOUT & PRINT ( ${AppTheme.currency.format(cartGrandTotal)} )',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTenderChip(double val, String label) {
    final isSelected = _tenderedAmount == val;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => setState(() => _tenderedAmount = val),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
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

  void _showUpiQr(BuildContext context, AppProvider provider, double amount) {
    showDialog(
      context: context,
      builder: (_) => UpiQrDialog(
        upiId: provider.business.upiId,
        businessName: provider.business.name,
        amount: amount,
        invoiceNumber: 'POS-NEW',
        onPaymentConfirmed: () {
          _checkoutPosBill(context, provider, amount, amount, 0.0);
        },
      ),
    );
  }

  void _showBarcodeScannerDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Quick Barcode / Item Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter or scan product barcode / SKU code:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. RICE01, OIL5L, etc.',
                prefixIcon: Icon(Icons.barcode_reader),
              ),
              onSubmitted: (code) {
                _processBarcode(code, provider, ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _processBarcode(controller.text, provider, ctx),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _processBarcode(String code, AppProvider provider, BuildContext dialogCtx) {
    final clean = code.trim().toLowerCase();
    if (clean.isEmpty) return;

    final match = provider.items.firstWhere(
      (it) => it.code.trim().toLowerCase() == clean || it.name.trim().toLowerCase().contains(clean),
      orElse: () => provider.items.first,
    );

    if (match.code.trim().toLowerCase() == clean || match.name.trim().toLowerCase().contains(clean)) {
      setState(() {
        _cart[match.id] = (_cart[match.id] ?? 0) + 1;
      });
      Navigator.pop(dialogCtx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${match.name}" to cart (Qty: ${_cart[match.id]})'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No item found with code "$code"'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _checkoutPosBill(BuildContext context, AppProvider provider, double grandTotal, double subtotal, double tax) async {
    try {
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
        firmId: provider.activeFirm.id.isNotEmpty ? provider.activeFirm.id : 'default_firm',
        invoiceNumber: invNum.isNotEmpty ? invNum : 'INV-001',
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
      setState(() {
        _cart.clear();
        _tenderedAmount = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('POS Invoice $invNum Generated Successfully!')));
        Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice)));
      }
    } catch (e) {
      debugPrint('Error in POS checkout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('POS Checkout Failed: $e'), backgroundColor: AppTheme.dangerRed));
      }
    }
  }
}
