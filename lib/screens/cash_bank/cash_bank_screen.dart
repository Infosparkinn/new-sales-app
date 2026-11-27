import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/cash_bank_account.dart';
import '../../providers/app_provider.dart';

class CashBankScreen extends StatefulWidget {
  const CashBankScreen({super.key});

  @override
  State<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends State<CashBankScreen> with SingleTickerProviderStateMixin {
  final Uuid _uuid = const Uuid();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = provider.cashBankAccounts;

    final cashAccounts = accounts.where((a) => a.accountType == 'cash').toList();
    final bankAccounts = accounts.where((a) => a.accountType == 'bank' || a.accountType == 'gpay' || a.accountType == 'credit_card').toList();

    final cashInHand = cashAccounts.fold(0.0, (sum, a) => sum + a.balance);
    final bankTotal = accounts.where((a) => a.accountType == 'bank').fold(0.0, (sum, a) => sum + a.balance);
    final cashInGpay = accounts.where((a) => a.accountType == 'gpay').fold(0.0, (sum, a) => sum + a.balance);
    final totalNetBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash & Bank Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_alt_rounded),
            tooltip: 'Transfer Funds',
            onPressed: () => _showTransferDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Account',
            onPressed: () => _showAddAccountDialog(context, provider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'ALL ACCOUNTS (${accounts.length})'),
            Tab(text: 'BANKS & GPAY (${bankAccounts.length})'),
            Tab(text: 'CASH IN HAND (${cashAccounts.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Overall Balance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppTheme.darkNavyGradient,
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL CASH & BANK BALANCE',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTheme.currency.format(totalNetBalance),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showTransferDialog(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cash: ${AppTheme.shortCurrency.format(cashInHand)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('In Banks: ${AppTheme.shortCurrency.format(bankTotal)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('UPI / GPay: ${AppTheme.shortCurrency.format(cashInGpay)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccountsList(accounts, provider),
                _buildAccountsList(bankAccounts, provider, emptyTitle: 'No bank or UPI accounts registered'),
                _buildAccountsList(cashAccounts, provider, emptyTitle: 'No cash registers registered'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showAddAccountDialog(context, provider),
        ),
      ),
    );
  }

  Widget _buildAccountsList(List<CashBankAccount> list, AppProvider provider, {String emptyTitle = 'No accounts found'}) {
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
                child: const Icon(Icons.account_balance_rounded, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Text(emptyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Account'),
                onPressed: () => _showAddAccountDialog(context, provider),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final acc = list[index];
        final isBank = acc.accountType == 'bank';
        final isCash = acc.accountType == 'cash';

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: AppTheme.border.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isBank
                        ? Colors.indigo.shade50
                        : (isCash ? Colors.green.shade50 : Colors.teal.shade50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isBank ? Icons.account_balance_rounded : (isCash ? Icons.payments_rounded : Icons.qr_code_rounded),
                    color: isBank ? Colors.indigo : (isCash ? Colors.green.shade700 : Colors.teal),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              acc.accountType.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                          ),
                          if (acc.accountNumber.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('A/C: ••••${acc.accountNumber.length > 4 ? acc.accountNumber.substring(acc.accountNumber.length - 4) : acc.accountNumber}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppTheme.currency.format(acc.balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: acc.balance >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      acc.balance >= 0 ? 'Available' : 'Overdrawn',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: acc.balance >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransferDialog(BuildContext context, AppProvider provider) {
    final accounts = provider.cashBankAccounts;
    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 2 accounts required to perform fund transfers.')));
      return;
    }

    String fromId = accounts.first.id;
    String toId = accounts.length > 1 ? accounts[1].id : accounts.first.id;
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Transfer Funds Between Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: fromId,
                  decoration: const InputDecoration(labelText: 'From Account'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (₹${a.balance.toInt()})'))).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => fromId = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toId,
                  decoration: const InputDecoration(labelText: 'To Account'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (₹${a.balance.toInt()})'))).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => toId = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Transfer Amount (₹)', prefixText: '₹ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description / Reference'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt <= 0) return;
                if (fromId == toId) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source and destination accounts must be different.')));
                  return;
                }
                final fromAcc = accounts.firstWhere((a) => a.id == fromId);
                final toAcc = accounts.firstWhere((a) => a.id == toId);

                final txn = BankTransaction(
                  id: _uuid.v4(),
                  firmId: provider.activeFirm.id,
                  fromAccountId: fromId,
                  fromAccountName: fromAcc.name,
                  toAccountId: toId,
                  toAccountName: toAcc.name,
                  amount: amt,
                  date: DateTime.now(),
                  description: descController.text.trim(),
                );
                await provider.transferBankFunds(txn);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transferred ₹$amt from ${fromAcc.name} to ${toAcc.name}!')));
                }
              },
              child: const Text('Transfer Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final accNumController = TextEditingController();
    final ifscController = TextEditingController();
    final upiController = TextEditingController();
    String type = 'bank';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Cash / Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Account Category'),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash in Hand')),
                    DropdownMenuItem(value: 'gpay', child: Text('Cash in GPay / UPI')),
                    DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => type = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Account / Wallet Name *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Opening Balance (₹)', prefixText: '₹ '),
                ),
                if (type == 'bank' || type == 'credit_card') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: accNumController,
                    decoration: InputDecoration(labelText: type == 'bank' ? 'Account Number' : 'Card Number (Last 4 digits)'),
                  ),
                  if (type == 'bank') ...[
                    const SizedBox(height: 10),
                    TextField(controller: ifscController, decoration: const InputDecoration(labelText: 'IFSC Code')),
                  ],
                ],
                if (type == 'gpay' || type == 'bank') ...[
                  const SizedBox(height: 10),
                  TextField(controller: upiController, decoration: const InputDecoration(labelText: 'UPI ID (Optional)')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final acc = CashBankAccount(
                  id: _uuid.v4(),
                  firmId: provider.activeFirm.id,
                  name: nameController.text.trim(),
                  accountType: type,
                  balance: double.tryParse(balanceController.text) ?? 0.0,
                  accountNumber: accNumController.text.trim(),
                  ifsc: ifscController.text.trim(),
                  upiId: upiController.text.trim(),
                );
                await provider.saveCashBankAccount(acc);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Account'),
            ),
          ],
        ),
      ),
    );
  }
}
