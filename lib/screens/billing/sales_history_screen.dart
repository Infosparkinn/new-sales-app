import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../providers/app_provider.dart';
import 'add_sale_screen.dart';
import 'invoice_preview_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'paid', 'unpaid'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final invoices = provider.invoices;

    final filtered = invoices.where((inv) {
      if (_statusFilter == 'paid' && !inv.isPaid) return false;
      if (_statusFilter == 'unpaid' && inv.isPaid) return false;
      if (_searchQuery.isNotEmpty) {
        return inv.invoiceNumber.toLowerCase().contains(_searchQuery) ||
               inv.partyName.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoices'),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search invoice # or customer...',
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
                DropdownButton<String>(
                  value: _statusFilter,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid/Due')),
                  ],
                  onChanged: (val) => setState(() => _statusFilter = val ?? 'All'),
                ),
              ],
            ),
          ),

          // Invoices List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No sales invoices found', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Bill'),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleScreen()));
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final inv = filtered[index];
                      return _buildInvoiceTile(context, inv);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Add Sale'),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleScreen()));
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceTile(BuildContext context, Invoice inv) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: inv)));
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Move to Recycle Bin?'),
              content: Text('Delete Invoice ${inv.invoiceNumber}? You can restore it anytime from the Recycle Bin.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                  onPressed: () async {
                    await context.read<AppProvider>().softDeleteInvoice(inv.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Move to Recycle Bin'),
                ),
              ],
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: inv.isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.dangerRed.withOpacity(0.12),
          child: Icon(
            Icons.receipt_long_rounded,
            color: inv.isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: inv.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                inv.isPaid ? 'PAID' : (inv.isPartial ? 'PARTIAL' : 'CREDIT DUE'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: inv.isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'Customer: ${inv.partyName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              '${AppTheme.dateFormat.format(inv.invoiceDate)} • ${inv.paymentMode.toUpperCase()} • ${inv.items.length} items',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppTheme.currency.format(inv.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (inv.balanceAmount > 0)
              Text(
                'Due: ${AppTheme.currency.format(inv.balanceAmount)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
              ),
          ],
        ),
      ),
    );
  }
}
