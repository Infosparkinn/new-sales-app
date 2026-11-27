import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';
import 'add_sale_screen.dart';
import 'invoice_preview_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final invoices = provider.invoices;

    final paidInvoices = invoices.where((i) => i.isPaid).toList();
    final unpaidInvoices = invoices.where((i) => !i.isPaid).toList();
    final ewayInvoices = invoices.where((i) => i.ewayBillNumber.isNotEmpty).toList();

    final totalSales = invoices.fold(0.0, (sum, i) => sum + i.totalAmount);
    final totalDue = invoices.fold(0.0, (sum, i) => sum + i.balanceAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Invoicing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Create New Bill',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleScreen()));
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
            Tab(text: 'ALL SALES (${invoices.length})'),
            Tab(text: 'PAID (${paidInvoices.length})'),
            Tab(text: 'UNPAID / DUE (${unpaidInvoices.length})'),
            Tab(text: 'E-WAY BILLS (${ewayInvoices.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Turnover & Receivables Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.8))),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL TURNOVER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 3),
                      Text(AppTheme.currency.format(totalSales), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppTheme.border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BALANCE DUE (UNPAID)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 3),
                      Text(AppTheme.currency.format(totalDue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.dangerRed)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.background,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by invoice #, party name, or phone...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

          // 3. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesList(invoices.where(_filterInvoice).toList(), provider),
                _buildInvoicesList(paidInvoices.where(_filterInvoice).toList(), provider),
                _buildInvoicesList(unpaidInvoices.where(_filterInvoice).toList(), provider),
                _buildInvoicesList(ewayInvoices.where(_filterInvoice).toList(), provider, isEwayTab: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Add Sale', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleScreen()));
          },
        ),
      ),
    );
  }

  bool _filterInvoice(Invoice inv) {
    if (_searchQuery.isEmpty) return true;
    return inv.invoiceNumber.toLowerCase().contains(_searchQuery) ||
        inv.partyName.toLowerCase().contains(_searchQuery) ||
        inv.partyPhone.contains(_searchQuery);
  }

  Widget _buildInvoicesList(List<Invoice> list, AppProvider provider, {bool isEwayTab = false}) {
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
                child: Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.primary.withOpacity(0.7)),
              ),
              const SizedBox(height: 16),
              const Text(
                'No sales invoices match this view',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create GST compliant bills with WhatsApp sharing and instant PDF previews',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Sale Bill'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleScreen()));
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
        final inv = list[index];
        final isPaid = inv.isPaid;

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: AppTheme.border.withOpacity(0.7),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: inv)));
            },
            onLongPress: () => _confirmDelete(context, inv, provider),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (isPaid ? AppTheme.successGreen : AppTheme.dangerRed).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                          color: isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Party & Invoice Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.partyName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    inv.invoiceNumber,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppTheme.dateFormat.format(inv.invoiceDate),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Amount & Due
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppTheme.currency.format(inv.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isPaid ? AppTheme.successGreen : AppTheme.dangerRed).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPaid ? 'PAID' : 'DUE: ${AppTheme.shortCurrency.format(inv.balanceAmount)}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // E-Way Bill Bar if present
                  if (inv.ewayBillNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'E-Way Bill: ${inv.ewayBillNumber}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                          if (inv.vehicleNumber.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('• Vehicle: ${inv.vehicleNumber}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Quick Action Buttons
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: const Text('Preview / PDF', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: inv)));
                        },
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          ShareService.shareInvoiceViaWhatsApp(
                            invoice: inv,
                            business: provider.business,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                        tooltip: 'Recycle Bin',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDelete(context, inv, provider),
                      ),
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

  void _confirmDelete(BuildContext context, Invoice inv, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Recycle Bin?'),
        content: Text('Are you sure you want to move invoice ${inv.invoiceNumber} to the Recycle Bin? It can be restored anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.softDeleteInvoice(inv.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice ${inv.invoiceNumber} moved to Recycle Bin'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => provider.restoreInvoice(inv.id),
                    ),
                  ),
                );
              }
            },
            child: const Text('Move to Recycle Bin'),
          ),
        ],
      ),
    );
  }
}
