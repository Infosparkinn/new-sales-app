import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/item.dart';
import '../../providers/app_provider.dart';
import 'add_item_screen.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _lowStockOnly = false;
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.items;
    final metrics = provider.metrics;

    final categories = ['All', ...{...items.map((i) => i.category)}];

    final filteredItems = items.where((it) {
      if (_lowStockOnly && !it.isLowStock) return false;
      if (_selectedCategory != 'All' && it.category != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty) {
        return it.name.toLowerCase().contains(_searchQuery) || it.code.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items & Stock Inventory'),
      ),
      body: Column(
        children: [
          // 1. Stock Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCol('TOTAL ITEMS', '${items.length} items', AppTheme.primary),
                Container(width: 1, height: 28, color: AppTheme.border),
                _buildSummaryCol(
                  'LOW STOCK',
                  '${(metrics['lowStockCount'] ?? 0).toInt()} items',
                  (metrics['lowStockCount'] ?? 0) > 0 ? AppTheme.accent : Colors.grey,
                ),
                Container(width: 1, height: 28, color: AppTheme.border),
                _buildSummaryCol(
                  'STOCK VALUE',
                  AppTheme.shortCurrency.format(metrics['totalStockValue'] ?? 0.0),
                  Colors.purple,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search item or barcode...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: _lowStockOnly,
                  selectedColor: AppTheme.accent.withOpacity(0.15),
                  checkmarkColor: AppTheme.accent,
                  labelStyle: TextStyle(
                    color: _lowStockOnly ? AppTheme.accent : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) => setState(() => _lowStockOnly = val),
                ),
              ],
            ),
          ),

          // 3. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Items List
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No items found', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Item'),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemScreen()));
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildItemCard(context, item, provider);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_box_rounded),
          label: const Text('Add Item'),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemScreen()));
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, Item item, AppProvider provider) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddItemScreen(itemToEdit: item)));
        },
        leading: CircleAvatar(
          backgroundColor: item.isLowStock ? AppTheme.accent.withOpacity(0.12) : AppTheme.primary.withOpacity(0.1),
          child: Icon(
            item.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
            color: item.isLowStock ? AppTheme.accent : AppTheme.primary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (item.taxRate > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'GST ${item.taxRate.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${item.category} • Code: ${item.code.isNotEmpty ? item.code : "N/A"}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Sale: ${AppTheme.currency.format(item.salePrice)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                if (item.purchasePrice > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Cost: ${AppTheme.shortCurrency.format(item.purchasePrice)}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.stockQuantity.toStringAsFixed(1)} ${item.unit}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: item.isLowStock ? AppTheme.accent : AppTheme.textPrimary,
              ),
            ),
            Text(
              item.isLowStock ? 'Low Stock!' : 'In Stock',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.isLowStock ? AppTheme.accent : AppTheme.successGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
