import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../models/item.dart';
import '../../models/party.dart';
import '../../models/order_challan.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';
import '../parties/add_party_screen.dart';
import 'invoice_preview_screen.dart';

class AddSaleScreen extends StatefulWidget {
  final OrderChallan? initialChallan;

  const AddSaleScreen({super.key, this.initialChallan});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  String _invoiceNumber = '';
  DateTime _invoiceDate = DateTime.now();
  Party? _selectedCustomer; // null = Cash Customer
  String _paymentMode = 'cash'; // 'cash', 'online', 'credit', 'cheque'
  final TextEditingController _receivedAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _ewayBillController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _transporterController = TextEditingController();

  final List<InvoiceItem> _billItems = [];
  bool _isAutoFillReceived = true;
  double _tcsRate = 0.0; // 0%, 0.1%, 1%
  double _tdsRate = 0.0; // 0%, 0.1%, 1%, 2%
  bool _showEWayBillFields = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppProvider>();
      final invNum = await provider.getNextInvoiceNumber();
      setState(() => _invoiceNumber = invNum);

      // Pre-fill from Delivery Challan / Sale Order if converting
      if (widget.initialChallan != null) {
        final doc = widget.initialChallan!;
        final party = provider.parties.firstWhere(
          (p) => p.id == doc.partyId,
          orElse: () => Party(id: doc.partyId, name: doc.partyName, phone: doc.partyPhone),
        );
        setState(() {
          _selectedCustomer = party;
          _notesController.text = 'Converted from ${doc.type.replaceAll('_', ' ').toUpperCase()} #${doc.documentNumber}';
          for (var it in doc.items) {
            _billItems.add(
              InvoiceItem(
                id: const Uuid().v4(),
                invoiceId: '',
                itemId: it.itemId,
                itemName: it.itemName,
                quantity: it.quantity,
                unit: it.unit,
                unitPrice: it.unitPrice,
                taxRate: it.taxRate,
                cgstAmount: it.totalAmount * (it.taxRate / 200.0),
                sgstAmount: it.totalAmount * (it.taxRate / 200.0),
                igstAmount: 0.0,
                totalAmount: it.totalAmount,
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _receivedAmountController.dispose();
    _notesController.dispose();
    _ewayBillController.dispose();
    _vehicleController.dispose();
    _transporterController.dispose();
    super.dispose();
  }

  // Calculations
  double get _subtotal => _billItems.fold(0.0, (sum, it) => sum + (it.quantity * it.unitPrice));

  bool get _isInterState {
    final provider = context.read<AppProvider>();
    final businessState = provider.business.state;
    final customerState = _selectedCustomer?.state ?? businessState;
    return customerState.isNotEmpty && businessState.isNotEmpty && customerState.toLowerCase() != businessState.toLowerCase();
  }

  double get _cgstTotal {
    if (_isInterState) return 0.0;
    return _billItems.fold(0.0, (sum, it) => sum + it.cgstAmount);
  }

  double get _sgstTotal {
    if (_isInterState) return 0.0;
    return _billItems.fold(0.0, (sum, it) => sum + it.sgstAmount);
  }

  double get _igstTotal {
    if (!_isInterState) return 0.0;
    return _billItems.fold(0.0, (sum, it) => sum + it.igstAmount);
  }

  double get _tcsAmount => (_subtotal * (_tcsRate / 100.0));
  double get _tdsAmount => (_subtotal * (_tdsRate / 100.0));

  double get _grandTotal {
    final baseTaxed = _billItems.fold(0.0, (sum, it) => sum + it.totalAmount);
    return baseTaxed + _tcsAmount - _tdsAmount;
  }

  double get _receivedAmount {
    if (_paymentMode == 'credit') return 0.0;
    if (_isAutoFillReceived) return _grandTotal;
    return double.tryParse(_receivedAmountController.text) ?? _grandTotal;
  }

  double get _balanceDue => (_grandTotal - _receivedAmount).clamp(0.0, double.infinity);

  // Live Profit tracking
  double get _totalProfit => _billItems.fold(0.0, (sum, it) => sum + it.profit);
  double get _profitMarginPercent => _subtotal > 0 ? (_totalProfit / _subtotal) * 100 : 0.0;

  bool get _isCreditLimitExceeded {
    if (_selectedCustomer == null || _selectedCustomer!.creditLimit <= 0) return false;
    final newBalance = _selectedCustomer!.currentBalance + _balanceDue;
    return newBalance > _selectedCustomer!.creditLimit;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final customers = provider.customers;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Sale Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Invoice #: $_invoiceNumber • ${provider.activeFirm.name}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Customer Selection
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Party?>(
                          value: _selectedCustomer,
                          decoration: const InputDecoration(
                            labelText: 'Customer *',
                            prefixIcon: Icon(Icons.person_outline),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<Party?>(
                              value: null,
                              child: Text('Cash Customer (Walk-in)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...customers.map((c) => DropdownMenuItem<Party?>(
                                  value: c,
                                  child: Text('${c.name} (${c.priceTier.toUpperCase()} • Bal: ₹${c.currentBalance.toInt()})'),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedCustomer = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primary),
                        tooltip: 'Add New Customer',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddPartyScreen(initialType: 'customer')),
                          );
                        },
                      ),
                    ],
                  ),

                  // Credit limit warning banner
                  if (_isCreditLimitExceeded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Warning: Total balance (₹${(_selectedCustomer!.currentBalance + _balanceDue).toStringAsFixed(0)}) exceeds credit limit of ₹${_selectedCustomer!.creditLimit.toStringAsFixed(0)}!',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Date Picker
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd/MM/yyyy').format(_invoiceDate), style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Payment Mode
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentMode,
                          decoration: const InputDecoration(
                            labelText: 'Payment Mode',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'online', child: Text('Online / UPI')),
                            DropdownMenuItem(value: 'credit', child: Text('Credit (Udhaar)')),
                            DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _paymentMode = val ?? 'cash';
                              if (_paymentMode == 'credit') {
                                _isAutoFillReceived = false;
                                _receivedAmountController.text = '0.00';
                              } else {
                                _isAutoFillReceived = true;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Added Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ITEMS LIST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Items', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showAddItemModal(context, provider.items),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_billItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No items added to bill yet', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Tap "+ Add Items" to add products to this invoice.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              )
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _billItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final it = _billItems[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              Text(it.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                '${it.quantity.toStringAsFixed(1)} ${it.unit} x ${AppTheme.currency.format(it.unitPrice)} • GST ${it.taxRate.toStringAsFixed(0)}%${it.batchNumber.isNotEmpty ? " • Batch: ${it.batchNumber}" : ""}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppTheme.currency.format(it.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.dangerRed, size: 20),
                          onPressed: () => setState(() => _billItems.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Live Profit Indicator
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: AppTheme.successGreen, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Estimated Invoice Profit: ${AppTheme.currency.format(_totalProfit)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.successGreen),
                        ),
                      ],
                    ),
                    Text(
                      'Margin: ${_profitMarginPercent.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.successGreen),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 3. E-Way Bill & Transport Accordion
            InkWell(
              onTap: () => setState(() => _showEWayBillFields = !_showEWayBillFields),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 18, color: Colors.indigo.shade800),
                        const SizedBox(width: 8),
                        const Text('E-Way Bill & Transport Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Icon(_showEWayBillFields ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (_showEWayBillFields) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ewayBillController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'E-Way Bill Number (12 digits)', hintText: 'e.g. 281928391829'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vehicleController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: 'Vehicle Number', hintText: 'TN-01-AB-1234'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _transporterController,
                            decoration: const InputDecoration(labelText: 'Transporter Name', hintText: 'VRL / Safexpress'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 4. Calculations Summary with TCS & TDS
            if (_billItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _calcRow('Subtotal (Taxable):', AppTheme.currency.format(_subtotal)),
                    if (!_isInterState) ...[
                      _calcRow('CGST:', AppTheme.currency.format(_cgstTotal)),
                      _calcRow('SGST:', AppTheme.currency.format(_sgstTotal)),
                    ] else ...[
                      _calcRow('IGST (Inter-State):', AppTheme.currency.format(_igstTotal)),
                    ],

                    // TCS & TDS Controls
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: _tcsRate,
                            decoration: const InputDecoration(labelText: 'TCS Rate', isDense: true),
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text('No TCS')),
                              DropdownMenuItem(value: 0.075, child: Text('0.075% TCS')),
                              DropdownMenuItem(value: 0.1, child: Text('0.1% TCS')),
                              DropdownMenuItem(value: 1.0, child: Text('1.0% TCS')),
                            ],
                            onChanged: (v) => setState(() => _tcsRate = v ?? 0.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: _tdsRate,
                            decoration: const InputDecoration(labelText: 'TDS Rate', isDense: true),
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text('No TDS')),
                              DropdownMenuItem(value: 0.1, child: Text('0.1% TDS')),
                              DropdownMenuItem(value: 1.0, child: Text('1.0% TDS')),
                              DropdownMenuItem(value: 2.0, child: Text('2.0% TDS')),
                            ],
                            onChanged: (v) => setState(() => _tdsRate = v ?? 0.0),
                          ),
                        ),
                      ],
                    ),
                    if (_tcsAmount > 0) _calcRow('TCS Added (+):', '+ ${AppTheme.currency.format(_tcsAmount)}', color: Colors.blue.shade900),
                    if (_tdsAmount > 0) _calcRow('TDS Deducted (-):', '- ${AppTheme.currency.format(_tdsAmount)}', color: Colors.orange.shade900),

                    const Divider(height: 18),
                    _calcRow(
                      'TOTAL AMOUNT:',
                      AppTheme.currency.format(_grandTotal),
                      isBold: true,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _receivedAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Received Amount (₹)',
                              prefixText: '₹ ',
                              hintText: _grandTotal.toStringAsFixed(2),
                            ),
                            onChanged: (val) {
                              setState(() => _isAutoFillReceived = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Balance Due', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            Text(
                              AppTheme.currency.format(_balanceDue),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _balanceDue > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 5. Save & Actions Footer
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save & Preview Bill'),
                    onPressed: _billItems.isEmpty ? null : () => _saveInvoice(context, shareDirect: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Save & WhatsApp'),
                    onPressed: _billItems.isEmpty ? null : () => _saveInvoice(context, shareDirect: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  void _showAddItemModal(BuildContext context, List<Item> availableItems) {
    if (availableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items in the Items catalog first!')),
      );
      return;
    }

    Item selectedItem = availableItems.first;
    double qty = 1.0;

    // Auto-select party price tier or custom special rate
    double resolveInitialPrice(Item it) {
      if (_selectedCustomer != null) {
        if (_selectedCustomer!.customRates.containsKey(it.id)) {
          return _selectedCustomer!.customRates[it.id]!;
        }
        return it.getPriceForTier(_selectedCustomer!.priceTier);
      }
      return it.salePrice;
    }

    double price = resolveInitialPrice(selectedItem);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final double itemTaxRate = selectedItem.taxRate;
            final double baseAmount = qty * price;
            final double taxAmount = baseAmount * (itemTaxRate / 100.0);
            final double totalRow = baseAmount + taxAmount;
            final double itemProfit = (price - selectedItem.purchasePrice) * qty;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Item to Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Item>(
                    value: selectedItem,
                    decoration: const InputDecoration(labelText: 'Product / Item'),
                    items: availableItems.map((it) {
                      return DropdownMenuItem(
                        value: it,
                        child: Text('${it.name} (₹${it.salePrice} • Stock: ${it.stockQuantity} ${it.unit})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedItem = val;
                          price = resolveInitialPrice(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: qty.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Quantity (${selectedItem.unit})'),
                          onChanged: (val) {
                            setModalState(() => qty = double.tryParse(val) ?? 1.0);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: price.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Unit Price (₹)', prefixText: '₹ '),
                          onChanged: (val) {
                            setModalState(() => price = double.tryParse(val) ?? selectedItem.salePrice);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GST (${itemTaxRate.toStringAsFixed(0)}%): ₹${taxAmount.toStringAsFixed(2)}'),
                            Text('Row Total: ₹${totalRow.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cost: ₹${selectedItem.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            Text('Est. Profit: +₹${itemProfit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final cgst = _isInterState ? 0.0 : taxAmount / 2.0;
                      final sgst = _isInterState ? 0.0 : taxAmount / 2.0;
                      final igst = _isInterState ? taxAmount : 0.0;

                      final invItem = InvoiceItem(
                        id: const Uuid().v4(),
                        invoiceId: '',
                        itemId: selectedItem.id,
                        itemName: selectedItem.name,
                        hsnCode: selectedItem.hsnCode,
                        quantity: qty,
                        unit: selectedItem.unit,
                        unitPrice: price,
                        purchasePrice: selectedItem.purchasePrice,
                        taxRate: itemTaxRate,
                        cgstAmount: cgst,
                        sgstAmount: sgst,
                        igstAmount: igst,
                        totalAmount: totalRow,
                        batchNumber: selectedItem.batchNumber,
                        serialNumber: selectedItem.serialNumber,
                      );

                      setState(() {
                        _billItems.add(invItem);
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Center(child: Text('Add to Bill')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveInvoice(BuildContext context, {required bool shareDirect}) async {
    final provider = context.read<AppProvider>();
    final business = provider.business;

    final invoiceId = const Uuid().v4();
    final itemsWithInvId = _billItems.map((it) {
      return InvoiceItem(
        id: it.id,
        invoiceId: invoiceId,
        itemId: it.itemId,
        itemName: it.itemName,
        hsnCode: it.hsnCode,
        quantity: it.quantity,
        unit: it.unit,
        unitPrice: it.unitPrice,
        purchasePrice: it.purchasePrice,
        taxRate: it.taxRate,
        cgstAmount: it.cgstAmount,
        sgstAmount: it.sgstAmount,
        igstAmount: it.igstAmount,
        totalAmount: it.totalAmount,
        batchNumber: it.batchNumber,
        serialNumber: it.serialNumber,
      );
    }).toList();

    final status = _balanceDue <= 0
        ? 'paid'
        : (_receivedAmount > 0 ? 'partial' : 'unpaid');

    final invoice = Invoice(
      id: invoiceId,
      firmId: provider.activeFirm.id,
      invoiceNumber: _invoiceNumber,
      partyId: _selectedCustomer?.id,
      partyName: _selectedCustomer?.name ?? 'Cash Customer',
      partyPhone: _selectedCustomer?.phone ?? '',
      partyAddress: _selectedCustomer?.address ?? '',
      partyState: _selectedCustomer?.state ?? business.state,
      partyGstin: _selectedCustomer?.gstin ?? '',
      invoiceDate: _invoiceDate,
      paymentMode: _paymentMode,
      subtotal: _subtotal,
      cgstAmount: _cgstTotal,
      sgstAmount: _sgstTotal,
      igstAmount: _igstTotal,
      tcsRate: _tcsRate,
      tcsAmount: _tcsAmount,
      tdsRate: _tdsRate,
      tdsAmount: _tdsAmount,
      totalAmount: _grandTotal,
      receivedAmount: _receivedAmount,
      balanceAmount: _balanceDue,
      profitAmount: _totalProfit,
      status: status,
      notes: _notesController.text.trim(),
      ewayBillNumber: _ewayBillController.text.trim(),
      vehicleNumber: _vehicleController.text.trim(),
      transporterName: _transporterController.text.trim(),
      hideBranding: provider.hideBranding,
      items: itemsWithInvId,
    );

    final navigator = Navigator.of(context);
    await provider.createInvoice(invoice);

    // If converted from challan/order, mark it converted
    if (widget.initialChallan != null) {
      await provider.updateOrderChallanStatus(widget.initialChallan!.id, 'converted_to_sale');
    }

    if (shareDirect) {
      await ShareService.shareInvoiceViaWhatsApp(business: business, invoice: invoice);
      if (mounted) {
        navigator.pop();
      }
    } else {
      if (mounted) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice)),
        );
      }
    }
  }
}
