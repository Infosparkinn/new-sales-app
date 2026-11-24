import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class AdvancedReportsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdvancedReportsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Business Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'BALANCE SHEET'),
            Tab(text: 'BILLWISE PROFIT'),
            Tab(text: 'PARTYWISE PROFIT'),
            Tab(text: 'BATCH & SERIAL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBalanceSheetTab(provider),
          _buildBillwiseProfitTab(provider),
          _buildPartywiseProfitTab(provider),
          _buildBatchReportTab(provider),
        ],
      ),
    );
  }

  // 1. Balance Sheet
  Widget _buildBalanceSheetTab(AppProvider provider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: provider.getBalanceSheet(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BALANCE SHEET AS OF ${AppTheme.dateFormat.format(DateTime.now()).toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),

              // Assets Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, color: AppTheme.successGreen, size: 20),
                          SizedBox(width: 8),
                          Text('ASSETS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.successGreen)),
                        ],
                      ),
                      const Divider(height: 18),
                      _row('Fixed Assets (Equipment, Vehicles, Furniture):', AppTheme.currency.format(data['fixedAssets'] ?? 0.0)),
                      _row('Trade Debtors (Accounts Receivable):', AppTheme.currency.format(data['debtors'] ?? 0.0)),
                      _row('Inventory Stock Value:', AppTheme.currency.format(data['stockValue'] ?? 0.0)),
                      _row('Cash & Bank Balances:', AppTheme.currency.format(data['cashAndBank'] ?? 0.0)),
                      const Divider(height: 18),
                      _row('TOTAL ASSETS:', AppTheme.currency.format(data['totalAssets'] ?? 0.0), isBold: true, fontSize: 15, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Liabilities & Equity Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gavel_rounded, color: AppTheme.dangerRed, size: 20),
                          SizedBox(width: 8),
                          Text('LIABILITIES & EQUITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.dangerRed)),
                        ],
                      ),
                      const Divider(height: 18),
                      _row('Trade Creditors (Suppliers Payable):', AppTheme.currency.format(data['creditors'] ?? 0.0)),
                      _row('GST & Tax Liabilities:', AppTheme.currency.format(data['taxLiability'] ?? 0.0)),
                      _row('TOTAL LIABILITIES:', AppTheme.currency.format(data['totalLiabilities'] ?? 0.0), isBold: true),
                      const Divider(height: 18),
                      _row("Owner's Equity & Retained Capital:", AppTheme.currency.format(data['equity'] ?? 0.0), isBold: true, color: Colors.purple),
                      const Divider(height: 18),
                      _row('TOTAL LIABILITIES & EQUITY:', AppTheme.currency.format(data['totalAssets'] ?? 0.0), isBold: true, fontSize: 15, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Billwise Profit
  Widget _buildBillwiseProfitTab(AppProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getBillwiseProfitReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No invoice profit records found'));

        final totalProfit = list.fold(0.0, (sum, i) => sum + (i['profit'] as double));

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.green.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Net Invoice Margin:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                  Text(AppTheme.currency.format(totalProfit), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.successGreen)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = list[index];
                  final double profit = row['profit'] as double;
                  final double margin = row['marginPercent'] as double;

                  return Card(
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Invoice ${row['invoiceNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            AppTheme.currency.format(profit),
                            style: TextStyle(fontWeight: FontWeight.bold, color: profit >= 0 ? AppTheme.successGreen : AppTheme.dangerRed),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${row['partyName']} • Sale: ${AppTheme.currency.format(row['saleAmount'])}'),
                          Text('Margin: ${margin.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: profit >= 0 ? AppTheme.successGreen : AppTheme.dangerRed)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 3. Partywise Profit
  Widget _buildPartywiseProfitTab(AppProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getPartywiseProfitReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No party profit data available'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final row = list[index];
            final double profit = row['totalProfit'] as double;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text('${row['billCount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                title: Text(row['partyName'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Total Sales: ${AppTheme.currency.format(row['totalSales'])} • Total Cost: ${AppTheme.currency.format(row['totalCost'])}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppTheme.currency.format(profit),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: profit >= 0 ? AppTheme.successGreen : AppTheme.dangerRed),
                    ),
                    const Text('Total Profit', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4. Batch & Serial Report
  Widget _buildBatchReportTab(AppProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getItemBatchReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) {
          return const Center(
            child: Text('No item batch or serial numbers tracked yet.\nAdd batches or serial numbers when editing items.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final row = list[index];
            final DateTime? exp = row['expiryDate'] as DateTime?;

            return Card(
              child: ListTile(
                title: Text(row['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((row['batchNumber'] as String).isNotEmpty)
                      Text('Batch #: ${row['batchNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    if ((row['serialNumber'] as String).isNotEmpty)
                      Text('Serial #: ${row['serialNumber']}'),
                    if (exp != null)
                      Text('Expiry: ${AppTheme.dateFormat.format(exp)}', style: TextStyle(color: exp.isBefore(DateTime.now()) ? AppTheme.accent : Colors.black87)),
                  ],
                ),
                trailing: Text(
                  '${row['stock']} ${row['unit']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
