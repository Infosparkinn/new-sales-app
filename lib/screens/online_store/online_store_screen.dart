import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';

class OnlineStoreScreen extends StatefulWidget {
  const OnlineStoreScreen({super.key});

  @override
  State<OnlineStoreScreen> createState() => _OnlineStoreScreenState();
}

class _OnlineStoreScreenState extends State<OnlineStoreScreen> {
  final Set<String> _selectedCategories = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final firm = provider.activeFirm;
    final items = provider.items.where((it) {
      final matchesSearch = it.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          it.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategories.isEmpty || _selectedCategories.contains(it.category);
      return matchesSearch && matchesCategory;
    }).toList();

    final categories = provider.items.map((it) => it.category).where((c) => c.isNotEmpty).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Online Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Store on WhatsApp',
            onPressed: () => _shareCatalog(context, firm, provider.items),
          ),
        ],
      ),
      body: Column(
        children: [
          // Storefront Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: const Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(firm.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade200)),
                                child: const Text('LIVE STORE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Order via WhatsApp: +91 ${firm.phone.isNotEmpty ? firm.phone : "9876543210"}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Text('UPI ID: ${firm.upiId.isNotEmpty ? firm.upiId : "Available on checkout"}', style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _shareCatalog(context, firm, provider.items),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('SHARE CATALOG & ORDER LINK ON WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products in catalog...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Chips
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Items'),
                    selected: _selectedCategories.isEmpty,
                    onSelected: (sel) => setState(() => _selectedCategories.clear()),
                  ),
                  const SizedBox(width: 6),
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(cat),
                          selected: _selectedCategories.contains(cat),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                        ),
                      )),
                ],
              ),
            ),

          // Product Catalog List
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No products match your search.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final inStock = item.stockQuantity > 0;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.category.isNotEmpty ? item.category : "General"} • Unit: ${item.unit}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(AppTheme.currency.format(item.salePrice),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
                                        if (item.wholesalePrice > 0) ...[
                                          const SizedBox(width: 8),
                                          Text('Wholesale: ₹${item.wholesalePrice}',
                                              style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: inStock ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: inStock ? Colors.green.shade200 : Colors.red.shade200),
                                    ),
                                    child: Text(
                                      inStock ? '${item.stockQuantity.toInt()} in stock' : 'Out of stock',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: inStock ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF25D366)),
                                    tooltip: 'Share product on WhatsApp',
                                    onPressed: () {
                                      final msg = '🛒 *${firm.name}*\n'
                                          'Item: *${item.name}*\n'
                                          'Price: *${AppTheme.currency.format(item.salePrice)}* / ${item.unit}\n'
                                          'Order via WhatsApp: +91 ${firm.phone}\n'
                                          'Pay via UPI: ${firm.upiId}';
                                      ShareService.shareText(text: msg, subject: item.name);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _shareCatalog(BuildContext context, dynamic firm, List<dynamic> items) {
    final buffer = StringBuffer();
    buffer.writeln('🛍️ *ONLINE PRODUCT CATALOG - ${firm.name}*');
    if (firm.address.isNotEmpty) buffer.writeln('📍 ${firm.address}');
    buffer.writeln('📞 Contact & Order: +91 ${firm.phone}');
    if (firm.upiId.isNotEmpty) buffer.writeln('💳 UPI Payment ID: ${firm.upiId}');
    buffer.writeln('\n============================');

    for (var it in items) {
      buffer.writeln('• *${it.name}* - ₹${it.salePrice} / ${it.unit} (${it.stockQuantity > 0 ? "In Stock" : "Out of stock"})');
    }
    buffer.writeln('============================');
    buffer.writeln('\nTo place an order, simply reply to this message with item names and quantities!');

    ShareService.shareText(text: buffer.toString(), subject: '${firm.name} - Online Store Catalog');
  }
}
