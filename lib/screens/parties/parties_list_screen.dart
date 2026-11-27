import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';
import 'add_party_screen.dart';
import 'party_detail_screen.dart';

class PartiesListScreen extends StatefulWidget {
  const PartiesListScreen({super.key});

  @override
  State<PartiesListScreen> createState() => _PartiesListScreenState();
}

class _PartiesListScreenState extends State<PartiesListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final customers = provider.customers.where(_filterParty).toList();
    final suppliers = provider.suppliers.where(_filterParty).toList();
    final allParties = provider.parties.where(_filterParty).toList();

    final totalReceivables = provider.metrics['totalReceivables'] ?? 0.0;
    final totalPayables = provider.metrics['totalPayables'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties & Ledgers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add New Party',
            onPressed: () => _openAddParty(context),
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
            Tab(text: 'CUSTOMERS (${provider.customers.length})'),
            Tab(text: 'SUPPLIERS (${provider.suppliers.length})'),
            Tab(text: 'ALL PARTIES (${provider.parties.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Advance Metrics Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.8))),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "YOU'LL GET (CUSTOMERS)",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppTheme.currency.format(totalReceivables),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.successGreen),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppTheme.border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "YOU'LL PAY (SUPPLIERS)",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppTheme.currency.format(totalPayables),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.dangerRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.background,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by party name, phone, or GSTIN...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // 3. Tabs Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPartyList(customers, partyType: 'customer', provider: provider),
                _buildPartyList(suppliers, partyType: 'supplier', provider: provider),
                _buildPartyList(allParties, partyType: 'all', provider: provider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Party', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _openAddParty(context),
        ),
      ),
    );
  }

  void _openAddParty(BuildContext context) {
    final defaultType = _tabController.index == 1 ? 'supplier' : 'customer';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPartyScreen(initialType: defaultType)),
    );
  }

  bool _filterParty(Party p) {
    if (_searchQuery.isEmpty) return true;
    return p.name.toLowerCase().contains(_searchQuery) ||
        p.phone.contains(_searchQuery) ||
        p.gstin.toLowerCase().contains(_searchQuery);
  }

  Widget _buildPartyList(List<Party> list, {required String partyType, required AppProvider provider}) {
    if (list.isEmpty) {
      final isCustomer = partyType == 'customer';
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
                child: Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.primary.withOpacity(0.7)),
              ),
              const SizedBox(height: 16),
              Text(
                partyType == 'all'
                    ? 'No parties match your search'
                    : (isCustomer ? 'No customers found' : 'No suppliers found'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add parties to track invoices, credit limits and balances',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(isCustomer ? 'Add Customer' : 'Add Supplier'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPartyScreen(initialType: isCustomer ? 'customer' : 'supplier'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final party = list[index];
        final balance = party.currentBalance;
        final bool toReceive = balance > 0;
        final bool settled = balance == 0;

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: AppTheme.border.withOpacity(0.7),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailScreen(party: party)));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Party Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: party.isCustomer
                            ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                            : [const Color(0xFF9333EA), const Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        party.name.isNotEmpty ? party.name[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Party Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                party.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (party.creditLimit > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.shade200, width: 0.5),
                                ),
                                child: Text(
                                  'Limit: ₹${party.creditLimit.toInt()}',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (party.phone.isNotEmpty) ...[
                              const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(party.phone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(width: 10),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (party.isCustomer ? Colors.blue : Colors.purple).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                party.partyType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: party.isCustomer ? AppTheme.primaryLight : AppTheme.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions: WhatsApp & Call
                  if (party.phone.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                      tooltip: 'WhatsApp Reminder',
                      onPressed: () {
                        ShareService.sharePartyReminder(
                          business: provider.business,
                          partyName: party.name,
                          balanceAmount: balance,
                          partyPhone: party.phone,
                        );
                      },
                    ),
                  ],

                  // Balance Tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppTheme.currency.format(balance.abs()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: settled
                              ? Colors.grey
                              : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (settled
                                  ? Colors.grey
                                  : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          settled ? 'Settled' : (toReceive ? "You'll Get" : "You'll Pay"),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: settled
                                ? Colors.grey
                                : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
