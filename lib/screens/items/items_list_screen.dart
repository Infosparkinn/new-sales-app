import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/item.dart';
import '../../providers/app_provider.dart';
import '../purchase/add_purchase_screen.dart';
import 'add_item_screen.dart';
import 'bulk_item_update_screen.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.items;
    final metrics = provider.metrics;

    final lowStockItems = items.where((i) => i.isLowStock).toList();
    final serviceItems = items.where((i) => i.category.toLowerCase().contains('service')).toList();
    final categories = {...items.map((i) => i.category)}.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items & Stock Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Bulk Update Items',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkItemUpdateScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Add New Item',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'ALL ITEMS (${items.length})'),
            Tab(text: 'LOW STOCK (${lowStockItems.length})'),
            Tab(text: 'SERVICES (${serviceItems.length})'),
            Tab(text: 'CATEGORIES (${categories.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Advance Stock Valuation Banner
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
                  AppTheme.purple,
                ),
              ],
            ),
          ),

          // 2. Search & Category Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.background,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items, barcodes, SKU...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
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
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.filter_list_rounded, size: 20, color: AppTheme.primary),
                  ),
                  tooltip: 'Filter Category',
                  initialValue: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                  itemBuilder: (context) {
                    final allCats = ['All', ...categories];
                    return allCats
                        .map((c) => PopupMenuItem(value: c, child: Text(c)))
                        .toList();
                  },
                ),
              ],
            ),
          ),

          // 3. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All Items
                _buildItemsList(
                  items.where(_filterItem).toList(),
                  emptyMessage: 'No items found',
                ),

                // Tab 2: Low Stock
                _buildItemsList(
                  lowStockItems.where(_filterItem).toList(),
                  emptyMessage: 'All items are well stocked!',
                  isLowStockTab: true,
                ),

                // Tab 3: Services
                _buildItemsList(
                  serviceItems.where(_filterItem).toList(),
                  emptyMessage: 'No service items registered',
                ),

                // Tab 4: Categories & Bulk Management
                _buildCategoriesView(categories, items),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddItemScreen()),
            );
          },
        ),
      ),
    );
  }

  bool _filterItem(Item it) {
    if (_selectedCategory != 'All' && it.category != _selectedCategory) return false;
    if (_searchQuery.isEmpty) return true;
    return it.name.toLowerCase().contains(_searchQuery) ||
        it.code.toLowerCase().contains(_searchQuery) ||
        it.hsnCode.toLowerCase().contains(_searchQuery);
  }

  Widget _buildSummaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildItemsList(List<Item> list, {required String emptyMessage, bool isLowStockTab = false}) {
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
                child: Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.primary.withOpacity(0.7)),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Track unit prices, GST rates, stock alerts, and barcodes',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemScreen()));
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        final bool isLowStock = item.isLowStock;

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: isLowStock ? AppTheme.accent.withOpacity(0.4) : AppTheme.border.withOpacity(0.7),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddItemScreen(itemToEdit: item)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.red.shade50 : AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLowStock ? Colors.red.shade200 : AppTheme.primary.withOpacity(0.15),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
                        color: isLowStock ? AppTheme.accent : AppTheme.primary,
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
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.category.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (item.code.isNotEmpty) ...[
                              Text('Code: ${item.code}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              const SizedBox(width: 8),
                            ],
                            Text('Buy: ${AppTheme.shortCurrency.format(item.purchasePrice)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            const SizedBox(width: 8),
                            Text('GST: ${item.taxRate.toInt()}%', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Stock & Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppTheme.currency.format(item.salePrice),
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isLowStock ? AppTheme.accent : AppTheme.successGreen).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.stockQuantity.toStringAsFixed(0)} ${item.unit}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLowStock ? AppTheme.accent : AppTheme.successGreen,
                          ),
                        ),
                      ),
                      if (isLowStockTab) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPurchaseScreen()));
                          },
                          child: const Text('+ Purchase', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesView(List<String> categories, List<Item> items) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Bulk Action Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bulk Item & Price Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Adjust pricing, tax rates, and stock across multiple items at once', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkItemUpdateScreen()));
                },
                child: const Text('Open Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Text('CATEGORIES BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),

        ...categories.map((cat) {
          final catItems = items.where((i) => i.category == cat).toList();
          final catValuation = catItems.fold(0.0, (sum, i) => sum + (i.stockQuantity * i.purchasePrice));

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: AppTheme.modernCardDecoration(
              borderRadius: 12,
              borderColor: AppTheme.border.withOpacity(0.7),
            ),
            child: ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_outlined, color: AppTheme.primary, size: 20),
              ),
              title: Text(cat.isNotEmpty ? cat : 'General', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${catItems.length} items registered', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppTheme.shortCurrency.format(catValuation), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.purple)),
                  const Text('Inventory Value', style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
                ],
              ),
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _tabController.animateTo(0);
                });
              },
            ),
          );
        }),
      ],
    );
  }
}
