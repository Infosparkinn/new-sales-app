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

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> with SingleTickerProviderStateMixin {
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'CUSTOMER BALANCES (${customers.length})'),
            Tab(text: 'POINTS HISTORY (${records.length})'),
            Tab(text: 'REWARD RULES'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Overall Points Hero Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL ACTIVE LOYALTY POINTS',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$activeBalance Pts',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VALUE IN RUPEES (1 Pt = ₹1)',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppTheme.currency.format(activeBalance.toDouble()),
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Customer Balances
                _buildCustomerBalancesList(customers, provider),

                // Tab 2: Points History
                _buildHistoryList(records),

                // Tab 3: Reward Rules
                _buildRulesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.star_rounded),
          label: const Text('Award Points', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showPointsDialog(context, provider),
        ),
      ),
    );
  }

  Widget _buildCustomerBalancesList(List customers, AppProvider provider) {
    if (customers.isEmpty) {
      return const Center(
        child: Text('No customers found to award loyalty points', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = customers[index];
        final partyRecords = provider.loyaltyRecords.where((r) => r.partyId == c.id);
        final earned = partyRecords.where((r) => r.type == 'earned').fold(0, (sum, r) => sum + r.points);
        final redeemed = partyRecords.where((r) => r.type == 'redeemed').fold(0, (sum, r) => sum + r.points);
        final pts = earned - redeemed;

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: AppTheme.border.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.purple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text(c.phone.isNotEmpty ? c.phone : 'No phone', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$pts Pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple)),
                    Text('Save ₹$pts', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                  ],
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.purple, size: 20),
                  tooltip: 'Award / Deduct',
                  onPressed: () => _showPointsDialog(context, provider, preselectedParty: c.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<LoyaltyRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No points transactions recorded yet', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = records[i];
        final isEarned = r.type == 'earned';

        return Container(
          decoration: AppTheme.modernCardDecoration(borderRadius: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isEarned ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(isEarned ? Icons.add_rounded : Icons.remove_rounded, color: isEarned ? Colors.green : Colors.red),
            ),
            title: Text(r.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text(
              '${AppTheme.dateFormat.format(r.date)} • ${r.notes.isNotEmpty ? r.notes : (isEarned ? "Earned from billing" : "Redeemed on bill")}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            trailing: Text(
              '${isEarned ? "+" : "-"} ${r.points} Pts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isEarned ? Colors.green : Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.modernCardDecoration(borderRadius: 14),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LOYALTY PROGRAM CONFIGURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
              SizedBox(height: 12),
              Text('• Earn Rate: 1 Loyalty Point for every ₹100 spent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('• Redemption Value: 1 Point = ₹1.00 direct bill discount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('• Minimum Redemption Threshold: 50 Points', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('• Auto-deduct points upon invoice generation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
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
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Customer *'),
                items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
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
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type $pts points for ${party.name}!')));
                }
              },
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }
}
