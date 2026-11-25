import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../settings/settings_screen.dart';
import '../firms/firms_management_screen.dart';
import '../assets/fixed_assets_screen.dart';
import '../reminders/service_reminders_screen.dart';
import '../recycle_bin/recycle_bin_screen.dart';
import '../items/bulk_item_update_screen.dart';
import '../billing/orders_challans_screen.dart';
import 'advanced_reports_screen.dart';
import 'reports_hub_screen.dart';
import '../../widgets/vyapar_drawer.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final invoices = provider.invoices;
    final transactions = provider.transactions;

    final totalSales = invoices.fold(0.0, (sum, i) => sum + i.totalAmount);
    final totalExpenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final netIncome = totalSales - totalExpenses;

    final totalCgst = invoices.fold(0.0, (sum, i) => sum + i.cgstAmount);
    final totalSgst = invoices.fold(0.0, (sum, i) => sum + i.sgstAmount);
    final totalIgst = invoices.fold(0.0, (sum, i) => sum + i.igstAmount);
    final totalTax = totalCgst + totalSgst + totalIgst;

    return Scaffold(
      drawer: const VyaparDrawer(),
      appBar: AppBar(
        title: const Text('Reports & Accounting Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 7-Category Comprehensive Reports Hub Link Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen())),
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('EXPLORE 40+ REPORTS (7 CATEGORIES HUB)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 14),

            // Active Firm Card
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmsManagementScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Text(
                        provider.activeFirm.name.isNotEmpty ? provider.activeFirm.name[0] : 'B',
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(provider.activeFirm.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 6),
                              const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                          if (provider.activeFirm.gstin.isNotEmpty)
                            Text('GSTIN: ${provider.activeFirm.gstin}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('${provider.activeFirm.state} • ${provider.firms.length} Companies Available', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Enterprise Quick Modules Grid
            const Text(
              'ENTERPRISE TOOLS & MODULES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _toolCard(
                  icon: Icons.account_balance_rounded,
                  title: 'Balance Sheet',
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 0))),
                ),
                _toolCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Billwise Profit',
                  color: AppTheme.successGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 1))),
                ),
                _toolCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Partywise Profit',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 2))),
                ),
                _toolCard(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Batch & Serial',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 3))),
                ),
                _toolCard(
                  icon: Icons.precision_manufacturing_rounded,
                  title: 'Fixed Assets',
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FixedAssetsScreen())),
                ),
                _toolCard(
                  icon: Icons.local_shipping_rounded,
                  title: 'Orders / Challans',
                  color: Colors.orange.shade800,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersChallansScreen())),
                ),
                _toolCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Bulk Item Update',
                  color: Colors.blueGrey,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkItemUpdateScreen())),
                ),
                _toolCard(
                  icon: Icons.alarm_rounded,
                  title: 'Service Reminders',
                  color: Colors.deepOrange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceRemindersScreen())),
                ),
                _toolCard(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Recycle Bin',
                  color: Colors.red.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinScreen())),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Financial Summary
            const Text(
              'PROFIT & LOSS OVERVIEW',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _reportRow('Total Sales Invoiced:', AppTheme.currency.format(totalSales), isBold: true, color: AppTheme.primary),
                  _reportRow('Total Expenses Logged:', '- ${AppTheme.currency.format(totalExpenses)}', color: AppTheme.dangerRed),
                  const Divider(height: 20),
                  _reportRow(
                    'Net Gross Margin:',
                    AppTheme.currency.format(netIncome),
                    isBold: true,
                    fontSize: 16,
                    color: netIncome >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GST Breakdown
            const Text(
              'GST TAX BREAKUP (GSTR-1 READY)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _reportRow('Central Tax (CGST):', AppTheme.currency.format(totalCgst)),
                  _reportRow('State Tax (SGST):', AppTheme.currency.format(totalSgst)),
                  _reportRow('Integrated Tax (IGST):', AppTheme.currency.format(totalIgst)),
                  const Divider(height: 20),
                  _reportRow('Total GST Collected:', AppTheme.currency.format(totalTax), isBold: true, fontSize: 15, color: Colors.indigo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
