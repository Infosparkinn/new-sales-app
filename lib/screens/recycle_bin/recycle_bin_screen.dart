import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class RecycleBinScreen extends StatelessWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final deletedInvoices = provider.deletedInvoices;
    final deletedTransactions = provider.deletedTransactions;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recycle Bin & Trash'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'DELETED INVOICES (${deletedInvoices.length})'),
              Tab(text: 'DELETED TRANSACTIONS (${deletedTransactions.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Deleted Invoices
            deletedInvoices.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No deleted invoices in recycle bin', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: deletedInvoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final inv = deletedInvoices[index];
                      return Card(
                        child: ListTile(
                          title: Text('Invoice ${inv.invoiceNumber} • ${inv.partyName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${AppTheme.dateFormat.format(inv.invoiceDate)} • Total: ${AppTheme.currency.format(inv.totalAmount)}'),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: const Text('Restore'),
                            onPressed: () async {
                              await provider.restoreInvoice(inv.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invoice ${inv.invoiceNumber} restored!')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),

            // Deleted Transactions
            deletedTransactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No deleted transactions in recycle bin', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: deletedTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final txn = deletedTransactions[index];
                      return Card(
                        child: ListTile(
                          title: Text(txn.partyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${txn.type.toUpperCase()} • ${AppTheme.currency.format(txn.amount)} • ${AppTheme.dateFormat.format(txn.date)}'),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: const Text('Restore'),
                            onPressed: () async {
                              await provider.restoreTransaction(txn.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction restored!')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
