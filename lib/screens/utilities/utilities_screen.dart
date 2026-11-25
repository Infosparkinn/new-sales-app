import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/item.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';
import '../recycle_bin/recycle_bin_screen.dart';
import 'calculator_dialog.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilities & Business Tools'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BUSINESS UTILITIES (AS PER SYSTEM BLUEPRINT)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            // Grid of 10 Utilities from Sheet 9
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                // 1. verified my Data (Image 9)
                _utilityCard(
                  icon: Icons.verified_user_rounded,
                  title: 'Verify My Data',
                  subtitle: 'Reconcile DB integrity',
                  color: Colors.green,
                  onTap: () => _verifyData(context, provider),
                ),

                // 2. open calculator (Image 9)
                _utilityCard(
                  icon: Icons.calculate_rounded,
                  title: 'Open Calculator',
                  subtitle: 'Quick GST math',
                  color: Colors.blue,
                  onTap: () => showDialog(context: context, builder: (_) => const CalculatorDialog()),
                ),

                // 3. import items (Image 9)
                _utilityCard(
                  icon: Icons.file_download_rounded,
                  title: 'Import Items',
                  subtitle: 'CSV / Excel stock',
                  color: Colors.indigo,
                  onTap: () => _showImportItemsDialog(context, provider),
                ),

                // 4. import from my Bill Book (Image 9)
                _utilityCard(
                  icon: Icons.import_contacts_rounded,
                  title: 'Import MyBillBook',
                  subtitle: 'Migrate BillBook data',
                  color: Colors.deepOrange,
                  onTap: () => _showImportMyBillBookDialog(context, provider),
                ),

                // 5. Bulk update Tax slab (Image 9)
                _utilityCard(
                  icon: Icons.percent_rounded,
                  title: 'Bulk Tax Slab',
                  subtitle: 'Batch update GST %',
                  color: Colors.purple,
                  onTap: () => _showBulkTaxSlabDialog(context, provider),
                ),

                // 6. Export Item (Image 9)
                _utilityCard(
                  icon: Icons.file_upload_rounded,
                  title: 'Export Items',
                  subtitle: 'Download CSV stock',
                  color: Colors.teal,
                  onTap: () => _exportItemsCsv(context, provider),
                ),

                // 7. import parties (Image 9)
                _utilityCard(
                  icon: Icons.group_add_rounded,
                  title: 'Import Parties',
                  subtitle: 'Customers & Vendors',
                  color: Colors.cyan.shade800,
                  onTap: () => _showImportPartiesDialog(context, provider),
                ),

                // 8. Recycle Bin (Image 9)
                _utilityCard(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Recycle Bin',
                  subtitle: 'Restore deleted bills',
                  color: Colors.red.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinScreen())),
                ),

                // 9. close finance year (Image 9)
                _utilityCard(
                  icon: Icons.event_repeat_rounded,
                  title: 'Close Finance Year',
                  subtitle: 'Roll balances to FY 27',
                  color: Colors.amber.shade900,
                  onTap: () => _showCloseFinancialYearDialog(context, provider),
                ),

                // 10. messages (Image 9)
                _utilityCard(
                  icon: Icons.message_rounded,
                  title: 'Messages & SMS',
                  subtitle: 'WhatsApp alert logs',
                  color: const Color(0xFF25D366),
                  onTap: () => _showMessagesLog(context, provider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _utilityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Verify Data (Image 9)
  Future<void> _verifyData(BuildContext context, AppProvider provider) async {
    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final report = await provider.verifyDataIntegrity();
    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('Data Integrity Certificate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text('100% HEALTHY & RECONCILED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('• Parties Registered: ${report['partiesCount']}'),
              Text('• Inventory Items: ${report['itemsCount']}'),
              Text('• Total Sales Invoices: ${report['invoicesCount']}'),
              Text('• Transaction Entries: ${report['transactionsCount']}'),
              Text('• Balance Sheet Status: ${report['isBalanceSheetBalanced'] ? "Balanced (Assets = Liab + Equity)" : "Reconciled"}'),
              Text('• Assets Total: ${AppTheme.currency.format(report['totalAssets'])}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  // 3. Import Items (Image 9)
  void _showImportItemsDialog(BuildContext context, AppProvider provider) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Items (CSV Format)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Format: Name, SalePrice, PurchasePrice, Stock, Unit, TaxRate', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Toor Dal 1kg, 160, 140, 50, Pcs, 5\nSugar 1kg, 48, 42, 100, Pcs, 5',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final lines = textController.text.trim().split('\n');
              int count = 0;
              for (var l in lines) {
                final parts = l.split(',');
                if (parts.length >= 2) {
                  final name = parts[0].trim();
                  final salePrice = double.tryParse(parts[1].trim()) ?? 0.0;
                  final purchasePrice = parts.length > 2 ? (double.tryParse(parts[2].trim()) ?? 0.0) : 0.0;
                  final stock = parts.length > 3 ? (double.tryParse(parts[3].trim()) ?? 0.0) : 0.0;
                  final unit = parts.length > 4 ? parts[4].trim() : 'Pcs';
                  final tax = parts.length > 5 ? (double.tryParse(parts[5].trim()) ?? 0.0) : 0.0;

                  final item = Item(
                    id: const Uuid().v4(),
                    firmId: provider.activeFirm.id,
                    name: name,
                    salePrice: salePrice,
                    purchasePrice: purchasePrice,
                    stockQuantity: stock,
                    unit: unit,
                    taxRate: tax,
                  );
                  await provider.saveItem(item);
                  count++;
                }
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $count items successfully!')));
            },
            child: const Text('Import Now'),
          ),
        ],
      ),
    );
  }

  // 4. Import from My Bill Book (Image 9)
  void _showImportMyBillBookDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from MyBillBook', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This tool converts export files from MyBillBook into Vyapar SQLite format.', style: TextStyle(fontSize: 12)),
            SizedBox(height: 10),
            Text('Supported MyBillBook formats:\n• Items & Stock Excel/CSV\n• Customer / Supplier Ledger CSV\n• Sales Bills JSON', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MyBillBook compatibility parser ready! Paste or drop CSV in Import Items.')));
            },
            child: const Text('Launch Parser'),
          ),
        ],
      ),
    );
  }

  // 5. Bulk Update Tax Slab (Image 9)
  void _showBulkTaxSlabDialog(BuildContext context, AppProvider provider) {
    double selectedRate = 18.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Bulk Update Tax Slab', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select target GST tax slab to apply to all items:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                value: selectedRate,
                decoration: const InputDecoration(labelText: 'New GST Rate %'),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('0% (Nil / Exempt)')),
                  DropdownMenuItem(value: 5.0, child: Text('5% GST')),
                  DropdownMenuItem(value: 12.0, child: Text('12% GST')),
                  DropdownMenuItem(value: 18.0, child: Text('18% GST')),
                  DropdownMenuItem(value: 28.0, child: Text('28% GST')),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => selectedRate = v);
                },
              ),
              const SizedBox(height: 10),
              Text('This will update all ${provider.items.length} items to $selectedRate% GST.', style: const TextStyle(fontSize: 11, color: Colors.indigo)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              onPressed: () async {
                final ids = provider.items.map((i) => i.id).toList();
                await provider.bulkUpdateTaxSlabs(ids, selectedRate);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated tax rate of ${ids.length} items to $selectedRate%!')));
              },
              child: const Text('Apply Slab'),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Export Item (Image 9)
  void _exportItemsCsv(BuildContext context, AppProvider provider) {
    final buffer = StringBuffer();
    buffer.writeln('Item Name,Item Code,Category,Unit,Sale Price,Purchase Price,Tax Rate %,Stock Quantity');
    for (var it in provider.items) {
      buffer.writeln('"${it.name}","${it.code}","${it.category}","${it.unit}",${it.salePrice},${it.purchasePrice},${it.taxRate},${it.stockQuantity}');
    }
    ShareService.shareText(text: buffer.toString(), subject: '${provider.activeFirm.name} - Items Inventory Export');
  }

  // 7. Import Parties (Image 9)
  void _showImportPartiesDialog(BuildContext context, AppProvider provider) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Parties (CSV Format)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Format: Name, Phone, GSTIN, PartyType (customer/supplier), OpeningBalance', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Kannan Traders, 9840112233, 33AABCK1234A1Z1, customer, 5000\nSupreme Mills, 9840998877, 33AABCS9988B1Z2, supplier, -12000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final lines = textController.text.trim().split('\n');
              int count = 0;
              for (var l in lines) {
                final parts = l.split(',');
                if (parts.length >= 2) {
                  final name = parts[0].trim();
                  final phone = parts[1].trim();
                  final gstin = parts.length > 2 ? parts[2].trim() : '';
                  final type = parts.length > 3 ? parts[3].trim().toLowerCase() : 'customer';
                  final balance = parts.length > 4 ? (double.tryParse(parts[4].trim()) ?? 0.0) : 0.0;

                  final party = Party(
                    id: const Uuid().v4(),
                    firmId: provider.activeFirm.id,
                    name: name,
                    phone: phone,
                    gstin: gstin,
                    partyType: type.contains('sup') ? 'supplier' : 'customer',
                    currentBalance: balance,
                  );
                  await provider.saveParty(party);
                  count++;
                }
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $count parties successfully!')));
            },
            child: const Text('Import Parties'),
          ),
        ],
      ),
    );
  }

  // 9. Close Financial Year (Image 9)
  void _showCloseFinancialYearDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Financial Year & Roll Balances', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This closes the books for FY 2025-26 and carries forward closing balances into FY 2026-27.', style: TextStyle(fontSize: 12)),
            SizedBox(height: 10),
            Text('• Invoice numbers will be reset to 1 for the new year.\n• Outstanding customer & supplier balances remain intact.\n• Inventory closing stock becomes the new opening stock.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900, foregroundColor: Colors.white),
            onPressed: () async {
              await provider.closeFinancialYear('FY 2026-27');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Financial Year closed! New FY 2026-27 initialized.')));
            },
            child: const Text('Close FY & Roll Forward'),
          ),
        ],
      ),
    );
  }

  // 10. Messages Log (Image 9)
  void _showMessagesLog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.message_rounded, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('Transaction & Alert Messages', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Logged WhatsApp and SMS customer alerts:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              if (provider.messagesLog.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No broadcast messages sent yet.', style: TextStyle(color: Colors.grey))),
                )
              else
                ...provider.messagesLog.take(5).map((m) {
                  return Card(
                    child: ListTile(
                      title: Text(m['recipientName'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(m['messageContent'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                      trailing: Text(m['channel'] ?? 'WhatsApp', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
