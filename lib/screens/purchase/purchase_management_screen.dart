import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../parties/party_detail_screen.dart';
import 'add_purchase_screen.dart';
import 'add_payment_out_dialog.dart';

class PurchaseManagementScreen extends StatefulWidget {
  final int initialTabIndex;

  const PurchaseManagementScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PurchaseManagementScreen> createState() => _PurchaseManagementScreenState();
}

class _PurchaseManagementScreenState extends State<PurchaseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final purchases = provider.transactions.where((t) => t.type == 'purchase').toList();
    final paymentsOut = provider.transactions.where((t) => t.type == 'payment_out').toList();
    final payables = provider.metrics['totalPayables'] ?? 0.0;
    final totalPurchases = purchases.fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase & Vendor Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Purchase Bills'),
            Tab(text: 'Payment Out'),
            Tab(text: 'Debit Notes (Return)'),
            Tab(text: 'Purchase Orders'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PURCHASES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(AppTheme.currency.format(totalPurchases), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppTheme.border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("YOU'LL PAY (SUPPLIERS)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(AppTheme.currency.format(payables), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.dangerRed)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Purchase Bills
                _buildPurchasesList(context, purchases, provider),

                // Tab 2: Payment Out
                _buildPaymentsOutList(context, paymentsOut, provider),

                // Tab 3: Debit Notes
                _buildDebitNotesTab(context, provider),

                // Tab 4: Purchase Orders
                _buildPurchaseOrdersTab(context, provider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_tabController.index == 1) {
            showDialog(context: context, builder: (_) => const AddPaymentOutDialog());
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPurchaseScreen()));
          }
        },
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: Text(_tabController.index == 1 ? '+ Payment Out' : '+ Purchase Bill', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPurchasesList(BuildContext context, List<dynamic> purchases, AppProvider provider) {
    if (purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No purchase bills recorded yet.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPurchaseScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Add Purchase Bill'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: purchases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = purchases[i];
        return Card(
          child: ListTile(
            onTap: () {
              final party = provider.parties.where((pt) => pt.id == p.partyId || (pt.name.toLowerCase() == p.partyName.toLowerCase()));
              if (party.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailScreen(party: party.first)));
              }
            },
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.12),
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.purple, size: 20),
            ),
            title: Text(p.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${AppTheme.dateFormat.format(p.date)} • ${p.referenceId.isNotEmpty ? p.referenceId : "Bill"} • ${p.paymentMode.toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            trailing: Text(AppTheme.currency.format(p.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple)),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsOutList(BuildContext context, List<dynamic> paymentsOut, AppProvider provider) {
    if (paymentsOut.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.outbox_rounded, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No payment out transactions recorded.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
              onPressed: () => showDialog(context: context, builder: (_) => const AddPaymentOutDialog()),
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Record Payment Out'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: paymentsOut.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = paymentsOut[i];
        return Card(
          child: ListTile(
            onTap: () {
              final party = provider.parties.where((pt) => pt.id == p.partyId || (pt.name.toLowerCase() == p.partyName.toLowerCase()));
              if (party.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailScreen(party: party.first)));
              }
            },
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.12),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 20),
            ),
            title: Text(p.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${AppTheme.dateFormat.format(p.date)} • ${p.paymentMode.toUpperCase()}${p.referenceId.isNotEmpty ? " • ${p.referenceId}" : ""}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            trailing: Text('- ${AppTheme.currency.format(p.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.dangerRed)),
          ),
        );
      },
    );
  }

  Widget _buildDebitNotesTab(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_return_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Purchase Return / Debit Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Return damaged or excess inventory goods back to suppliers to reduce payables.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a purchase bill above to issue a debit note!')));
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('+ Issue Debit Note'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOrdersTab(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_rounded, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            const Text('Purchase Orders (PO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Send formal purchase requisitions to suppliers before receiving goods.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPurchaseScreen())),
              icon: const Icon(Icons.post_add_rounded),
              label: const Text('+ Create Purchase Order'),
            ),
          ],
        ),
      ),
    );
  }
}
