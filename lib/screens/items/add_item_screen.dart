import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/item.dart';
import '../../providers/app_provider.dart';

class AddItemScreen extends StatefulWidget {
  final Item? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _categoryController;
  late TextEditingController _salePriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _dealerPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _hsnController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _batchController;
  late TextEditingController _serialController;

  final Map<String, TextEditingController> _customFieldControllers = {};
  String _unit = 'Pcs';
  double _taxRate = 5.0;

  final List<String> _units = ['Pcs', 'Kg', 'Bag', 'Box', 'Ltr', 'Mtr', 'Bottle', 'Packet', 'Gram'];
  final List<double> _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  void initState() {
    super.initState();
    final it = widget.itemToEdit;
    _nameController = TextEditingController(text: it?.name ?? '');
    _codeController = TextEditingController(text: it?.code ?? '');
    _categoryController = TextEditingController(text: it?.category ?? 'General');
    _salePriceController = TextEditingController(text: it != null ? it.salePrice.toString() : '');
    _wholesalePriceController = TextEditingController(text: it != null && it.wholesalePrice > 0 ? it.wholesalePrice.toString() : '');
    _dealerPriceController = TextEditingController(text: it != null && it.dealerPrice > 0 ? it.dealerPrice.toString() : '');
    _purchasePriceController = TextEditingController(text: it != null && it.purchasePrice > 0 ? it.purchasePrice.toString() : '');
    _hsnController = TextEditingController(text: it?.hsnCode ?? '');
    _stockController = TextEditingController(text: it != null ? it.stockQuantity.toString() : '10');
    _minStockController = TextEditingController(text: it != null ? it.minStockAlert.toString() : '5');
    _batchController = TextEditingController(text: it?.batchNumber ?? '');
    _serialController = TextEditingController(text: it?.serialNumber ?? '');
    _unit = it?.unit ?? 'Pcs';
    if (!_units.contains(_unit)) _units.add(_unit);
    _taxRate = it?.taxRate ?? 5.0;

    if (it != null && it.customFields.isNotEmpty) {
      it.customFields.forEach((k, v) {
        _customFieldControllers[k] = TextEditingController(text: v);
      });
    } else {
      _customFieldControllers['Brand'] = TextEditingController();
      _customFieldControllers['Rack / Location'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _salePriceController.dispose();
    _wholesalePriceController.dispose();
    _dealerPriceController.dispose();
    _purchasePriceController.dispose();
    _hsnController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _batchController.dispose();
    _serialController.dispose();
    for (var c in _customFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Item',
              onPressed: _deleteItem,
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
              // Basic Details
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name *', prefixIcon: Icon(Icons.inventory_2_outlined)),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Item Code / Barcode',
                        hintText: 'e.g. 89010300',
                        prefixIcon: Icon(Icons.qr_code_2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Unit *'),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => setState(() => _unit = val ?? 'Pcs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Groceries, Electronics, Clothing',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Multiple Pricing Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TIERED PRICING (MULTIPLE RATES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _salePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Retail Price (₹) *', prefixText: '₹ '),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter sale price';
                              final num = double.tryParse(val);
                              if (num == null || num < 0) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _wholesalePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Wholesale (₹)', prefixText: '₹ '),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _dealerPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Dealer (₹)', prefixText: '₹ '),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Purchase / Cost Price (₹)', prefixText: '₹ '),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: _taxRate,
                            decoration: const InputDecoration(labelText: 'GST Slab *'),
                            items: _gstRates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toStringAsFixed(0)}% GST'))).toList(),
                            onChanged: (val) => setState(() => _taxRate = val ?? 0.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hsnController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'HSN / SAC Code', hintText: 'e.g. 1006'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Batch, Serial & Stock Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BATCH, SERIAL & STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: 'Stock Qty ($_unit) *'),
                            validator: (val) => val == null || val.isEmpty ? 'Enter stock' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _minStockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: 'Low Stock Alert ($_unit)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _batchController,
                            decoration: const InputDecoration(labelText: 'Batch Number', hintText: 'e.g. B-2026-04'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _serialController,
                            decoration: const InputDecoration(labelText: 'Serial Number', hintText: 'e.g. SN-88291'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Custom Fields for Items
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CUSTOM FIELDS (ADDITIONAL INFO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Field', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            _showAddCustomFieldDialog(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._customFieldControllers.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: entry.key,
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  _customFieldControllers.remove(entry.key);
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveItem,
                child: Text(isEditing ? 'Update Item' : 'Save Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomFieldDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Field'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Field Name (e.g. Color, Size, Warranty)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _customFieldControllers[name] = TextEditingController();
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveItem() async {
    if (_formKey.currentState?.validate() != true) return;

    final Map<String, String> customs = {};
    _customFieldControllers.forEach((k, v) {
      if (v.text.trim().isNotEmpty) customs[k] = v.text.trim();
    });

    final item = Item(
      id: widget.itemToEdit?.id ?? const Uuid().v4(),
      firmId: context.read<AppProvider>().activeFirm.id,
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'General',
      unit: _unit,
      salePrice: double.parse(_salePriceController.text),
      wholesalePrice: double.tryParse(_wholesalePriceController.text) ?? 0.0,
      dealerPrice: double.tryParse(_dealerPriceController.text) ?? 0.0,
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
      taxRate: _taxRate,
      hsnCode: _hsnController.text.trim(),
      stockQuantity: double.parse(_stockController.text),
      minStockAlert: double.tryParse(_minStockController.text) ?? 5.0,
      batchNumber: _batchController.text.trim(),
      serialNumber: _serialController.text.trim(),
      customFields: customs,
    );

    final provider = context.read<AppProvider>();
    await provider.saveItem(item);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item "${item.name}" saved!')),
      );
    }
  }

  void _deleteItem() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${widget.itemToEdit!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () async {
              final provider = context.read<AppProvider>();
              await provider.deleteItem(widget.itemToEdit!.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
