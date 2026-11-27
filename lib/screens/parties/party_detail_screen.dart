import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';
import '../billing/add_sale_screen.dart';
import '../billing/invoice_preview_screen.dart';
import '../purchase/add_payment_out_dialog.dart';
import '../purchase/add_purchase_screen.dart';
import '../transactions/add_payment_in_dialog.dart';
import 'add_party_screen.dart';

class _LedgerEntryItem {
  final DateTime date;
  final Widget widget;

  _LedgerEntryItem({required this.date, required this.widget});
}

class PartyDetailScreen extends StatelessWidget {
  final Party party;

  const PartyDetailScreen({super.key, required this.party});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // Get live updated party from provider
    final currentParty = provider.parties.firstWhere(
      (p) => p.id == party.id,
      orElse: () => party,
    );

    // Filter invoices and transactions belonging to this party
    final partyInvoices = provider.invoices.where((i) {
      if (i.partyId == currentParty.id) return true;
      if (i.partyName.trim().isNotEmpty &&
          i.partyName.trim().toLowerCase() == currentParty.name.trim().toLowerCase()) {
        return true;
      }
      return false;
    }).toList();

    // Prevent duplicate entries between invoices and transactions of type 'sale'
    final invoiceNumbers = partyInvoices.map((i) => i.invoiceNumber.toLowerCase()).toSet();

    final partyTxns = provider.transactions.where((t) {
      if (t.isDeleted) return false;
      final matchesParty = t.partyId == currentParty.id ||
          (t.partyName.trim().isNotEmpty &&
              t.partyName.trim().toLowerCase() == currentParty.name.trim().toLowerCase());
      if (!matchesParty) return false;
      if (t.type == 'sale' && invoiceNumbers.contains(t.referenceId.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final balance = currentParty.currentBalance;
    final bool toReceive = balance > 0;
    final bool settled = balance == 0;
    final bool isSupplier = currentParty.isSupplier;

    // Check opening balance
    final double openingBal = currentParty.openingBalance != 0.0
        ? currentParty.openingBalance
        : (partyInvoices.isEmpty && partyTxns.isEmpty && currentParty.currentBalance != 0.0
            ? currentParty.currentBalance
            : 0.0);

    // Construct unified sorted ledger timeline entries
    final List<_LedgerEntryItem> entries = [];

    // 1. Invoices (Sales)
    for (final inv in partyInvoices) {
      entries.add(
        _LedgerEntryItem(
          date: inv.invoiceDate,
          widget: Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDBEAFE),
                child: Icon(Icons.receipt_long, color: AppTheme.primary),
              ),
              title: Text('Sale Invoice #${inv.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '${AppTheme.dateFormat.format(inv.invoiceDate)} • Mode: ${inv.paymentMode.toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppTheme.currency.format(inv.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (inv.isPaid ? AppTheme.successGreen : AppTheme.dangerRed).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      inv.isPaid ? 'PAID' : (inv.isPartial ? 'PARTIAL' : 'UNPAID'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: inv.isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: inv)));
              },
            ),
          ),
        ),
      );
    }

    // 2. Transactions (Purchase bills, payments in, payments out, expenses)
    for (final txn in partyTxns) {
      Widget cardContent;

      if (txn.type == 'purchase') {
        cardContent = Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(Icons.shopping_bag_outlined, color: Colors.deepPurple),
            ),
            title: Text(
              txn.referenceId.isNotEmpty ? 'Purchase Bill #${txn.referenceId}' : 'Purchase Bill',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${AppTheme.dateFormat.format(txn.date)} • Mode: ${txn.paymentMode.toUpperCase()} ${txn.description.isNotEmpty ? '• ${txn.description}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ${AppTheme.currency.format(txn.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PURCHASE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (txn.type == 'payment_out') {
        cardContent = Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.arrow_upward_rounded, color: AppTheme.dangerRed),
            ),
            title: const Text('Payment Out (Paid to Supplier)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${AppTheme.dateFormat.format(txn.date)} • ${txn.paymentMode.toUpperCase()} ${txn.referenceId.isNotEmpty ? '• Ref: ${txn.referenceId}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ ${AppTheme.currency.format(txn.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PAID OUT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (txn.type == 'payment_in') {
        cardContent = Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFD1FAE5),
              child: Icon(Icons.arrow_downward_rounded, color: AppTheme.successGreen),
            ),
            title: const Text('Payment Received (Payment In)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${AppTheme.dateFormat.format(txn.date)} • ${txn.paymentMode.toUpperCase()} ${txn.referenceId.isNotEmpty ? '• Ref: ${txn.referenceId}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ${AppTheme.currency.format(txn.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RECEIVED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Generic / Expense / Other transaction
        cardContent = Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEF3C7),
              child: Icon(Icons.receipt_outlined, color: Colors.amber),
            ),
            title: Text(txn.description.isNotEmpty ? txn.description : 'Transaction (${txn.type.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${AppTheme.dateFormat.format(txn.date)} • ${txn.paymentMode.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Text(
              AppTheme.currency.format(txn.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      }

      entries.add(_LedgerEntryItem(date: txn.date, widget: cardContent));
    }

    // 3. Opening Balance Entry (if non-zero)
    if (openingBal != 0.0) {
      final isPayable = openingBal < 0;
      entries.add(
        _LedgerEntryItem(
          date: currentParty.createdAt.subtract(const Duration(minutes: 1)),
          widget: Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.border.withOpacity(0.8)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: isPayable ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: isPayable ? AppTheme.dangerRed : AppTheme.successGreen,
                ),
              ),
              title: const Text('Opening / Brought Forward Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '${AppTheme.dateFormat.format(currentParty.createdAt)} • Initial Ledger Balance',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppTheme.currency.format(openingBal.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPayable ? AppTheme.dangerRed : AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPayable ? AppTheme.dangerRed : AppTheme.successGreen).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPayable ? "YOU'LL PAY" : "YOU'LL RECEIVE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPayable ? AppTheme.dangerRed : AppTheme.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Sort entries descending by date
    entries.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(currentParty.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Party',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddPartyScreen(partyToEdit: currentParty)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Party',
            onPressed: () => _confirmDelete(context, provider, currentParty),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Balance Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: settled ? AppTheme.border : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                settled
                                    ? Icons.check_circle_outline_rounded
                                    : (toReceive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
                                size: 16,
                                color: settled
                                    ? Colors.grey
                                    : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                settled ? 'CURRENT BALANCE (SETTLED)' : (toReceive ? "YOU'LL RECEIVE" : "YOU'LL PAY"),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: settled ? Colors.grey : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppTheme.currency.format(balance.abs()),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: settled ? AppTheme.textPrimary : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isSupplier ? AppTheme.purple : AppTheme.primary).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isSupplier ? AppTheme.purple : AppTheme.primary).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          currentParty.partyType.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSupplier ? AppTheme.purple : AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      if (currentParty.phone.isNotEmpty) ...[
                        const Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(currentParty.phone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const Spacer(),
                      ],
                      if (currentParty.gstin.isNotEmpty) ...[
                        const Icon(Icons.receipt, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('GSTIN: ${currentParty.gstin}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                  if (currentParty.address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${currentParty.address}, ${currentParty.state}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Action Buttons (Dynamically tuned for Supplier vs Customer)
            if (isSupplier) ...[
              // Supplier Actions: Pay Out + Purchase Bill
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 20),
                      label: const Text('Pay Out / Make Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddPaymentOutDialog(preselectedSupplier: currentParty),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                      label: const Text('+ Purchase Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPurchaseScreen(preselectedSupplier: currentParty),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366), // WhatsApp Green
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('WhatsApp Statement', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ShareService.sharePartyReminder(
                      business: provider.business,
                      partyName: currentParty.name,
                      partyPhone: currentParty.phone,
                      balanceAmount: currentParty.currentBalance.abs(),
                      isSupplier: true,
                    );
                  },
                ),
              ),
            ] else ...[
              // Customer Actions: Receive Payment + Sale Bill
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 20),
                      label: const Text('Receive Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddPaymentInDialog(defaultParty: currentParty),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 20),
                      label: const Text('+ Sale Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddSaleScreen(initialParty: currentParty),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366), // WhatsApp Green
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('WhatsApp Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ShareService.sharePartyReminder(
                      business: provider.business,
                      partyName: currentParty.name,
                      partyPhone: currentParty.phone,
                      balanceAmount: currentParty.currentBalance.abs(),
                      isSupplier: false,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 3. Unified Ledger History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LEDGER & TRANSACTIONS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                ),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'Record' : 'Records'}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (entries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No transactions recorded for this party.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            else
              ...entries.map((e) => e.widget),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, Party party) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Party?'),
        content: Text('Are you sure you want to delete "${party.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () async {
              await provider.deleteParty(party.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
