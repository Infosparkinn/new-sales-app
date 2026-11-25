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

class _CashBankScreenState extends State<CashBankScreen> {
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = provider.cashBankAccounts;

    final cashInHand = accounts.where((a) => a.accountType == 'cash').fold(0.0, (sum, a) => sum + a.balance);
    final cashInGpay = accounts.where((a) => a.accountType == 'gpay').fold(0.0, (sum, a) => sum + a.balance);
    final bankTotal = accounts.where((a) => a.accountType == 'bank').fold(0.0, (sum, a) => sum + a.balance);
    final creditCardTotal = accounts.where((a) => a.accountType == 'credit_card').fold(0.0, (sum, a) => sum + a.balance);

    final totalNetBalance = cashInHand + cashInGpay + bankTotal + creditCardTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash & Bank Management'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Balance Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL CASH & BANK BALANCE',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(AppTheme.currency.format(totalNetBalance),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _heroMiniStat('Cash in Hand', AppTheme.currency.format(cashInHand)),
                      _heroMiniStat('Cash in GPay', AppTheme.currency.format(cashInGpay)),
                      _heroMiniStat('In Banks', AppTheme.currency.format(bankTotal)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Transfer CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTransferDialog(context, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('TRANSFER MONEY BETWEEN ACCOUNTS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // 1. Cash in Hand Section (Image 1)
            _sectionHeader('CASH IN HAND', Icons.account_balance_wallet_rounded, Colors.green),
            ...accounts.where((a) => a.accountType == 'cash').map((a) => _accountCard(context, a, provider)),
            const SizedBox(height: 16),

            // 2. Cash in GPay / UPI Section (Image 1)
            _sectionHeader('CASH IN G PAY / UPI', Icons.qr_code_2_rounded, Colors.blue),
            ...accounts.where((a) => a.accountType == 'gpay').map((a) => _accountCard(context, a, provider)),
            const SizedBox(height: 16),

            // 3. Bank Accounts Section (Image 1)
            _sectionHeader('BANK ACCOUNTS', Icons.account_balance_rounded, Colors.indigo),
            ...accounts.where((a) => a.accountType == 'bank').map((a) => _accountCard(context, a, provider)),
            const SizedBox(height: 16),

            // 4. Credit Card Section (Image 1)
            _sectionHeader('CREDIT CARDS', Icons.credit_card_rounded, Colors.deepOrange),
            ...accounts.where((a) => a.accountType == 'credit_card').map((a) => _accountCard(context, a, provider)),
            const SizedBox(height: 24),

            // Recent Bank Transfers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RECENT TRANSFERS & LOGS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                TextButton(
                  onPressed: () => _showTransferDialog(context, provider),
                  child: const Text('+ Transfer', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            FutureBuilder<List<BankTransaction>>(
              future: provider.getBankTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                final txns = snapshot.data ?? [];
                if (txns.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                    child: const Text('No recent transfers between accounts.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txns.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.12),
                          child: const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
                        ),
                        title: Text('${t.fromAccountName} ➔ ${t.toAccountName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(AppTheme.dateFormat.format(t.date), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        trailing: Text(AppTheme.currency.format(t.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _accountCard(BuildContext context, CashBankAccount acc, AppProvider provider) {
    final isNegative = acc.balance < 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isNegative ? Colors.red.withOpacity(0.12) : AppTheme.primary.withOpacity(0.12),
          child: Icon(
            acc.accountType == 'bank'
                ? Icons.account_balance_rounded
                : acc.accountType == 'gpay'
                    ? Icons.qr_code_2_rounded
                    : acc.accountType == 'credit_card'
                        ? Icons.credit_card_rounded
                        : Icons.wallet_rounded,
            color: isNegative ? Colors.red : AppTheme.primary,
          ),
        ),
        title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          acc.upiId.isNotEmpty
              ? 'UPI: ${acc.upiId}'
              : acc.accountNumber.isNotEmpty
                  ? 'A/c: ${acc.accountNumber}${acc.ifsc.isNotEmpty ? " • IFSC: ${acc.ifsc}" : ""}'
                  : acc.notes.isNotEmpty
                      ? acc.notes
                      : 'Active Account',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: Text(
          AppTheme.currency.format(acc.balance),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isNegative ? AppTheme.dangerRed : AppTheme.successGreen,
          ),
        ),
      ),
    );
  }

  void _showTransferDialog(BuildContext context, AppProvider provider) {
    final accounts = provider.cashBankAccounts;
    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 2 accounts are required to transfer.')));
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: fromId,
                decoration: const InputDecoration(labelText: 'Transfer From (Source)'),
                items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${AppTheme.currency.format(a.balance)})'))).toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => fromId = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: toId,
                decoration: const InputDecoration(labelText: 'Transfer To (Destination)'),
                items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${AppTheme.currency.format(a.balance)})'))).toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => toId = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Transfer Amount (₹)', prefixText: '₹ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Note / Reference (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid transfer amount.')));
                  return;
                }
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
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transferred ₹$amt from ${fromAcc.name} to ${toAcc.name}!')));
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
                Navigator.pop(ctx);
              },
              child: const Text('Save Account'),
            ),
          ],
        ),
      ),
    );
  }
}
