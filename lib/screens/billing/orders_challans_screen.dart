import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import 'add_sale_screen.dart';

class OrdersChallansScreen extends StatelessWidget {
  const OrdersChallansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final docs = provider.ordersChallans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Orders & Delivery Challans'),
      ),
      body: docs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No orders or delivery challans', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  const Text('Create delivery challans and convert them into final sales', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: doc.type == 'delivery_challan' ? Colors.orange.shade50 : Colors.blue.shade50,
                      child: Icon(
                        doc.type == 'delivery_challan' ? Icons.local_shipping : Icons.assignment,
                        color: doc.type == 'delivery_challan' ? Colors.orange.shade800 : AppTheme.primary,
                      ),
                    ),
                    title: Text('${doc.documentNumber} • ${doc.partyName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${doc.type.replaceAll('_', ' ').toUpperCase()} • ${AppTheme.dateFormat.format(doc.date)} • ${doc.items.length} items'),
                    trailing: doc.isOpen
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                            label: const Text('Convert to Sale', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddSaleScreen(initialChallan: doc),
                                ),
                              );
                            },
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('CONVERTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
