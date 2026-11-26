import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../providers/app_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties (Ledger / Khata)'),
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
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by party name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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

          // Tabs Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPartyList(customers, isCustomerTab: true),
                _buildPartyList(suppliers, isCustomerTab: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Party'),
          onPressed: () {
            final defaultType = _tabController.index == 0 ? 'customer' : 'supplier';
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddPartyScreen(initialType: defaultType)),
            );
          },
        ),
      ),
    );
  }

  bool _filterParty(Party p) {
    if (_searchQuery.isEmpty) return true;
    return p.name.toLowerCase().contains(_searchQuery) || p.phone.contains(_searchQuery);
  }

  Widget _buildPartyList(List<Party> list, {required bool isCustomerTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isCustomerTab ? 'No customers found' : 'No suppliers found',
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(isCustomerTab ? 'Add Customer' : 'Add Supplier'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPartyScreen(initialType: isCustomerTab ? 'customer' : 'supplier'),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final party = list[index];
        final balance = party.currentBalance;
        final bool toReceive = balance > 0;
        final bool settled = balance == 0;

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailScreen(party: party)));
            },
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              foregroundColor: AppTheme.primary,
              child: Text(
                party.name.isNotEmpty ? party.name[0].toUpperCase() : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (party.phone.isNotEmpty) Text(party.phone, style: const TextStyle(fontSize: 12)),
                if (party.gstin.isNotEmpty)
                  Text('GST: ${party.gstin}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppTheme.currency.format(balance.abs()),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: settled
                        ? Colors.grey
                        : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                  ),
                ),
                Text(
                  settled
                      ? 'Settled'
                      : (toReceive ? "You'll Get" : "You'll Pay"),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: settled
                        ? Colors.grey
                        : (toReceive ? AppTheme.successGreen : AppTheme.dangerRed),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
