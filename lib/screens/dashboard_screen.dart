import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/transaction_record.dart';
import '../providers/app_provider.dart';
import 'auth/device_management_screen.dart';
import 'auth/login_screen.dart';
import 'billing/add_sale_screen.dart';
import 'billing/invoice_preview_screen.dart';
import 'billing/mobile_pos_screen.dart';
import 'cash_bank/cash_bank_screen.dart';
import 'firms/firms_management_screen.dart';
import 'items/add_item_screen.dart';
import 'parties/party_detail_screen.dart';
import 'purchase/purchase_management_screen.dart';
import 'reports/reports_hub_screen.dart';
import 'transactions/add_expense_dialog.dart';
import 'transactions/add_payment_in_dialog.dart';
import '../widgets/vyapar_drawer.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToParties;
  final VoidCallback onNavigateToItems;

  const DashboardScreen({
    super.key,
    required this.onNavigateToParties,
    required this.onNavigateToItems,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final business = provider.business;
    final metrics = provider.metrics;
    final bool isDesktop = kIsWeb ||
        (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ||
        MediaQuery.of(context).size.width >= 800;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      drawer: const VyaparDrawer(),
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmsManagementScreen()));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      business.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
                ],
              ),
              const Text('FY 2026-27 • Tap to switch firm', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          // Multi-Device Profile Pill
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(isSwitchingUser: true),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.currentUser?.isDesktop == true
                        ? Icons.desktop_windows
                        : Icons.phone_android,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.currentUser != null
                        ? provider.currentUser!.name.split(' ').first
                        : 'Login',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.devices_other),
            tooltip: 'Connected Terminals (4 Devices)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeviceManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => provider.loadAllData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. You'll Get & You'll Pay Cards (Vyapar Signature)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "YOU'LL GET",
                      subtitle: "From Customers",
                      amount: metrics['totalReceivables'] ?? 0.0,
                      color: AppTheme.successGreen,
                      icon: Icons.arrow_downward_rounded,
                      onTap: onNavigateToParties,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: "YOU'LL PAY",
                      subtitle: "To Suppliers",
                      amount: metrics['totalPayables'] ?? 0.0,
                      color: AppTheme.dangerRed,
                      icon: Icons.arrow_upward_rounded,
                      onTap: onNavigateToParties,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Secondary Quick Stats Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppTheme.modernCardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      label: "Today's Sale",
                      value: AppTheme.shortCurrency.format(metrics['todaySale'] ?? 0.0),
                      icon: Icons.today_rounded,
                      iconColor: AppTheme.primaryLight,
                    ),
                    Container(width: 1, height: 30, color: AppTheme.border),
                    _buildMiniStat(
                      label: "Stock Value",
                      value: AppTheme.shortCurrency.format(metrics['totalStockValue'] ?? 0.0),
                      icon: Icons.inventory_2_outlined,
                      iconColor: Colors.purple,
                      onTap: onNavigateToItems,
                    ),
                    Container(width: 1, height: 30, color: AppTheme.border),
                    _buildMiniStat(
                      label: "Low Stock",
                      value: "${(metrics['lowStockCount'] ?? 0).toInt()} items",
                      icon: Icons.warning_amber_rounded,
                      iconColor: (metrics['lowStockCount'] ?? 0) > 0 ? AppTheme.accent : Colors.grey,
                      onTap: onNavigateToItems,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Quick Action Buttons Grid
              const Text(
                "QUICK ACTIONS",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "+ Sale Bill",
                      color: AppTheme.primary,
                      icon: Icons.receipt_long_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "+ Payment In",
                      color: AppTheme.successGreen,
                      icon: Icons.payments_rounded,
                      onTap: () => showDialog(context: context, builder: (_) => const AddPaymentInDialog()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "+ Expense",
                      color: Colors.orange.shade800,
                      icon: Icons.money_off_rounded,
                      onTap: () => showDialog(context: context, builder: (_) => const AddExpenseDialog()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "+ Item",
                      color: Colors.indigo,
                      icon: Icons.add_box_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemScreen()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: isDesktop ? "Desktop POS" : "Mobile POS",
                      color: Colors.teal.shade700,
                      icon: Icons.point_of_sale_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePosScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "+ Purchase",
                      color: Colors.purple.shade700,
                      icon: Icons.shopping_bag_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseManagementScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "Cash & Bank",
                      color: Colors.blue.shade900,
                      icon: Icons.account_balance_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CashBankScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "All Reports",
                      color: Colors.indigo.shade900,
                      icon: Icons.bar_chart_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 4. Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECENT TRANSACTIONS",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                  ),
                  Text("${provider.transactions.length} records", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),

              if (provider.transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: AppTheme.modernCardDecoration(borderRadius: 14),
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("No transactions yet", style: TextStyle(color: AppTheme.textSecondary)),
                      SizedBox(height: 4),
                      Text("Create your first Sale Bill using the button above!", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.transactions.length.clamp(0, 10),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final txn = provider.transactions[index];
                    return _buildTransactionTile(context, txn, provider);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.modernCardDecoration(
          borderRadius: 14,
          borderColor: color.withOpacity(0.25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppTheme.currency.format(amount),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionRecord txn, AppProvider provider) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    bool isCredit = txn.isIncome;

    switch (txn.type) {
      case 'sale':
        typeColor = AppTheme.primary;
        typeIcon = Icons.receipt_long_rounded;
        typeLabel = 'SALE';
        break;
      case 'payment_in':
        typeColor = AppTheme.successGreen;
        typeIcon = Icons.arrow_downward_rounded;
        typeLabel = 'PAYMENT IN';
        break;
      case 'expense':
        typeColor = Colors.orange.shade800;
        typeIcon = Icons.money_off_rounded;
        typeLabel = 'EXPENSE';
        break;
      case 'purchase':
        typeColor = Colors.purple;
        typeIcon = Icons.shopping_bag_rounded;
        typeLabel = 'PURCHASE';
        break;
      case 'payment_out':
        typeColor = AppTheme.dangerRed;
        typeIcon = Icons.arrow_upward_rounded;
        typeLabel = 'PAYMENT OUT';
        break;
      default:
        typeColor = Colors.blueGrey;
        typeIcon = Icons.swap_horiz_rounded;
        typeLabel = 'TXN';
    }

    return Container(
      decoration: AppTheme.modernCardDecoration(
        borderRadius: 12,
        borderColor: AppTheme.border.withOpacity(0.7),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          if (txn.type == 'sale' && txn.referenceId.isNotEmpty) {
            final invMatches = provider.invoices.where((i) => i.invoiceNumber.toLowerCase() == txn.referenceId.toLowerCase());
            if (invMatches.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invMatches.first)));
              return;
            }
          }
          if (txn.partyId != null) {
            final partyMatches = provider.parties.where((p) => p.id == txn.partyId);
            if (partyMatches.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailScreen(party: partyMatches.first)));
              return;
            }
          }
          if (txn.partyName.isNotEmpty) {
            final nameMatches = provider.parties.where((p) => p.name.toLowerCase() == txn.partyName.toLowerCase());
            if (nameMatches.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailScreen(party: nameMatches.first)));
              return;
            }
          }
        },
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        title: Text(
          txn.partyName.isNotEmpty ? txn.partyName : typeLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        subtitle: Text(
          '${AppTheme.dateFormat.format(txn.date)} • ${txn.paymentMode.toUpperCase()}${txn.referenceId.isNotEmpty ? " • ${txn.referenceId}" : ""}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: Text(
          '${isCredit ? "+" : "-"} ${AppTheme.currency.format(txn.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isCredit ? AppTheme.successGreen : AppTheme.dangerRed,
          ),
        ),
      ),
    );
  }
}
