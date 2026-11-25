import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/loyalty_points.dart';
import '../../providers/app_provider.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final records = provider.loyaltyRecords;
    final customers = provider.customers;

    final totalEarned = records.where((r) => r.type == 'earned').fold(0, (sum, r) => sum + r.points);
    final totalRedeemed = records.where((r) => r.type == 'redeemed').fold(0, (sum, r) => sum + r.points);
    final activeBalance = totalEarned - totalRedeemed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Loyalty Points'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Award / Adjust Points',
            onPressed: () => _showPointsDialog(context, provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loyalty Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Color(0xFF4A148C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('REWARD PROGRAM OVERVIEW',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Outstanding Points', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$activeBalance Pts', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Discount Value', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(AppTheme.currency.format(activeBalance.toDouble()), style: const TextStyle(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rate: 1 Pt per ₹100 spent', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('Redemption: 1 Pt = ₹1.00', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Balances Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CUSTOMER POINTS REGISTER',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                Text('${customers.length} Customers', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),

            if (customers.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No customers found.')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = customers[i];
                  final pts = records.where((r) => r.partyId == c.id).fold(0, (sum, r) => r.type == 'earned' ? sum + r.points : sum - r.points);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.12),
                        child: Text(c.name.isNotEmpty ? c.name[0] : 'C', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(c.phone.isNotEmpty ? c.phone : 'No phone', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$pts Pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                              Text('Save ₹$pts', style: const TextStyle(fontSize: 10, color: AppTheme.successGreen)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.purple, size: 22),
                            tooltip: 'Adjust Points',
                            onPressed: () => _showPointsDialog(context, provider, preselectedParty: c.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Points Activity Ledger
            const Text('RECENT POINTS ACTIVITY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),

            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: const Text('No loyalty points transactions recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length.clamp(0, 8),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = records[i];
                  final isEarned = r.type == 'earned';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isEarned ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                        child: Icon(isEarned ? Icons.add_rounded : Icons.remove_rounded, color: isEarned ? Colors.green : Colors.red),
                      ),
                      title: Text(r.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${AppTheme.dateFormat.format(r.date)} • ${r.notes.isNotEmpty ? r.notes : (isEarned ? "Earned from billing" : "Redeemed for discount")}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      trailing: Text(
                        '${isEarned ? "+" : "-"} ${r.points} Pts',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isEarned ? Colors.green : Colors.red),
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

  void _showPointsDialog(BuildContext context, AppProvider provider, {String? preselectedParty}) {
    final customers = provider.customers;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one customer first.')));
      return;
    }

    String partyId = preselectedParty ?? customers.first.id;
    final pointsController = TextEditingController();
    final noteController = TextEditingController();
    String type = 'earned';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Award or Redeem Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: partyId,
                decoration: const InputDecoration(labelText: 'Customer *'),
                items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => partyId = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Action Type'),
                items: const [
                  DropdownMenuItem(value: 'earned', child: Text('+ Award / Earn Points')),
                  DropdownMenuItem(value: 'redeemed', child: Text('- Redeem / Deduct Points')),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => type = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Points Count', suffixText: 'Pts'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Reason / Bill No (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              onPressed: () async {
                final pts = int.tryParse(pointsController.text) ?? 0;
                if (pts <= 0) return;
                final party = customers.firstWhere((c) => c.id == partyId);
                final rec = LoyaltyRecord(
                  id: _uuid.v4(),
                  firmId: provider.activeFirm.id,
                  partyId: partyId,
                  partyName: party.name,
                  points: pts,
                  type: type,
                  date: DateTime.now(),
                  notes: noteController.text.trim(),
                );
                await provider.addLoyaltyRecord(rec);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type $pts points for ${party.name}!')));
              },
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }
}
