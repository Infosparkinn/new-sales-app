import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';
import '../transactions/add_payment_in_dialog.dart';
import '../billing/invoice_preview_screen.dart';
import 'add_party_screen.dart';

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
    final partyInvoices = provider.invoices.where((i) => i.partyId == currentParty.id).toList();
    final partyTxns = provider.transactions.where((t) => t.partyId == currentParty.id).toList();

    final balance = currentParty.currentBalance;
    final bool toReceive = balance > 0;
    final bool settled = balance == 0;

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
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settled ? 'CURRENT BALANCE' : (toReceive ? "YOU'LL RECEIVE" : "YOU'LL PAY"),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: settled ? Colors.grey : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTheme.currency.format(balance.abs()),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: settled ? AppTheme.textPrimary : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                            ),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(currentParty.partyType.toUpperCase()),
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primary),
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

            // 2. Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Receive Payment'),
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
                        balanceAmount: currentParty.currentBalance.abs(),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Ledger Transactions History
            const Text(
              'TRANSACTIONS & INVOICES',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            if (partyInvoices.isEmpty && partyTxns.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text('No transactions recorded for this party.', style: TextStyle(color: Colors.grey)),
              )
            else ...[
              // List Invoices
              ...partyInvoices.map((inv) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(Icons.receipt_long, color: AppTheme.primary),
                    ),
                    title: Text('Invoice ${inv.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${AppTheme.dateFormat.format(inv.invoiceDate)} • ${inv.paymentMode.toUpperCase()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppTheme.currency.format(inv.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          inv.isPaid ? 'PAID' : (inv.isPartial ? 'PARTIAL' : 'UNPAID'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: inv.isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: inv)));
                    },
                  ),
                );
              }),

              // List Payments
              ...partyTxns.where((t) => t.type == 'payment_in').map((txn) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFD1FAE5),
                      child: Icon(Icons.arrow_downward, color: AppTheme.successGreen),
                    ),
                    title: const Text('Payment Received', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${AppTheme.dateFormat.format(txn.date)} • ${txn.paymentMode.toUpperCase()} • ${txn.description}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      '- ${AppTheme.currency.format(txn.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 14),
                    ),
                  ),
                );
              }),
            ],
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
