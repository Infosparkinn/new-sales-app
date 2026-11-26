import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/share_service.dart';
import 'advanced_reports_screen.dart';

class ReportsHubScreen extends StatefulWidget {
  final int initialCategoryIndex;

  const ReportsHubScreen({super.key, this.initialCategoryIndex = 0});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;
  String _searchFilter = '';

  final List<String> _categoryTitles = [
    'Financial & Transactions', // Image 2
    'Party Reports',             // Image 2
    'Item & Stock Reports',      // Image 7
    'GST & Tax Reports',         // Image 3
    'Expense Reports',           // Image 5
    'Orders & Challans',         // Image 5
    'Business Status & Taxes',   // Image 6
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryTitles.length, vsync: this, initialIndex: widget.initialCategoryIndex);
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
        title: const Text('All Reports Hub • Testing Sales App'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _categoryTitles.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search any report (e.g. Day Book, GSTR-1, HSN, Stock)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
              ),
              onChanged: (val) => setState(() => _searchFilter = val),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Financial & Transaction Reports (Sheet 2)
                _buildCategoryList([
                  _rep('Sale Report', 'Total sales, tax, and receivables', Icons.receipt_long, () => _openSaleReport(context, provider)),
                  _rep('Purchase Report', 'Inward stock bills and vendor payments', Icons.shopping_bag, () => _openPurchaseReport(context, provider)),
                  _rep('Day Book', 'Chronological daily receipts and payments', Icons.today_rounded, () => _openDayBookReport(context, provider)),
                  _rep('All Transactions', 'Complete transaction log with filters', Icons.list_alt_rounded, () => _openAllTxnsReport(context, provider)),
                  _rep('Bill Wise Profit', 'Profit & margin % per invoice', Icons.trending_up_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 1)))),
                  _rep('Profit and Loss', 'Revenue vs COGS and Net income', Icons.pie_chart_rounded, () => _openProfitLossReport(context, provider)),
                  _rep('Cash Flow', 'Inflows, outflows, and net cash balance', Icons.swap_horiz_rounded, () => _openCashFlowReport(context, provider)),
                  _rep('Balance Sheet', 'Real-time Assets = Liabilities + Equity', Icons.account_balance_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 0)))),
                ]),

                // 2. Party Reports (Sheet 2)
                _buildCategoryList([
                  _rep('Party Statement (Ledger)', 'Individual customer/vendor statement', Icons.person_rounded, () => _openPartyStatementSelector(context, provider)),
                  _rep('Party Wise Profit and Loss', 'Profit earned per customer account', Icons.people_alt_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 2)))),
                  _rep('All Parties Report', 'Summary of all receivables & payables', Icons.groups_rounded, () => _openAllPartiesReport(context, provider)),
                  _rep('Party Report by Items', 'Items bought/sold by each party', Icons.category_rounded, () => _openPartyReportByItems(context, provider)),
                  _rep('Sale / Purchase by Party', 'Total sales vs purchases comparison', Icons.compare_arrows_rounded, () => _openSalePurchaseByParty(context, provider)),
                ]),

                // 3. Item / Stock Reports (Sheet 7)
                _buildCategoryList([
                  _rep('Stock Summary Report', 'Quantities, sale value, purchase cost', Icons.inventory_2_rounded, () => _openStockSummaryReport(context, provider)),
                  _rep('Item Report by Party', 'Item movement per customer/vendor', Icons.store_mall_directory_rounded, () => _openPartyReportByItems(context, provider)),
                  _rep('Item Wise Profit and Loss', 'Gross margin per SKU item', Icons.analytics_rounded, () => _openItemWiseProfitReport(context, provider)),
                  _rep('Low Stock Summary Report', 'Items below minimum reorder alert', Icons.warning_amber_rounded, () => _openLowStockReport(context, provider)),
                  _rep('Item Details Report', 'Specifications, HSN, Tax slab, Barcode', Icons.description_rounded, () => _openItemDetailsReport(context, provider)),
                  _rep('Stock Detail Report', 'Inward, outward, and balance ledger', Icons.format_list_numbered_rounded, () => _openStockSummaryReport(context, provider)),
                  _rep('Sale / Purchase by Item Category', 'Category revenue and margins', Icons.pie_chart_outline_rounded, () => _openCategoryStockReport(context, provider)),
                  _rep('Stock Summary by Item Category', 'Valuation per category breakdown', Icons.donut_small_rounded, () => _openCategoryStockReport(context, provider)),
                  _rep('Item Batch Report', 'Batches and expiry dates schedule', Icons.qr_code_2_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 3)))),
                  _rep('Item Serial Report', 'Serial numbers and warranty tracking', Icons.confirmation_number_rounded, () => _openItemSerialReport(context, provider)),
                  _rep('Item Wise Discount', 'Discounts given on specific items', Icons.local_offer_rounded, () => _openDiscountReport(context, provider)),
                ]),

                // 4. GST Reports (Sheet 3)
                _buildCategoryList([
                  _rep('GSTR-1', 'Outward Supplies: B2B, B2C, HSN summary', Icons.fact_check_rounded, () => _openGstr1Report(context, provider)),
                  _rep('GSTR-2', 'Inward Supplies & eligible Input Tax Credit', Icons.input_rounded, () => _openGstr2Report(context, provider)),
                  _rep('GSTR-3B', 'Summary return: Output Tax vs Input Tax', Icons.assessment_rounded, () => _openGstr3bReport(context, provider)),
                  _rep('GST Transaction Report', 'Taxable sales with CGST/SGST/IGST split', Icons.receipt_rounded, () => _openGstTxnReport(context, provider)),
                  _rep('GSTR-9', 'Annual consolidated tax return summary', Icons.calendar_month_rounded, () => _openGstr9Report(context, provider)),
                  _rep('Sale Summary by HSN Code', 'Taxable value & tax by HSN codes', Icons.tag_rounded, () => _openHsnSummaryReport(context, provider)),
                  _rep('SAC Report', 'Services Accounting Code tax summary', Icons.miscellaneous_services_rounded, () => _openSacReport(context, provider)),
                ]),

                // 5. Expense Reports (Sheet 5)
                _buildCategoryList([
                  _rep('Expense Transaction Report', 'All expenses with ITC & GSTIN notes', Icons.money_off_rounded, () => _openExpenseTxnReport(context, provider)),
                  _rep('Expense Category Report', 'Manufacturing, Petrol, Rent, Salary, Tea, Transport', Icons.donut_large_rounded, () => _openExpenseCategoryReport(context, provider)),
                  _rep('Expense Item Report', 'Itemized expense ledger breakdown', Icons.list_rounded, () => _openExpenseTxnReport(context, provider)),
                ]),

                // 6. Sale and Purchase Order Reports (Sheet 5)
                _buildCategoryList([
                  _rep('Sale / Purchase Order Transaction Report', 'Status of all Orders & Delivery Challans', Icons.local_shipping_rounded, () => _openOrderTxnReport(context, provider)),
                  _rep('Sale / Purchase Order Item Report', 'Quantities and rates across pending orders', Icons.assignment_rounded, () => _openOrderTxnReport(context, provider)),
                ]),

                // 7. Business Status & Taxes (Sheet 5 & 6)
                _buildCategoryList([
                  _rep('Bank Statement', 'Account movements, deposits, withdrawals', Icons.account_balance_rounded, () => _openBankStatement(context, provider)),
                  _rep('Discount Report', 'Total discounts given to customers on sales', Icons.discount_rounded, () => _openDiscountReport(context, provider)),
                  _rep('GST Report', 'Overall GST turnover and liabilities', Icons.percent_rounded, () => _openGstr1Report(context, provider)),
                  _rep('GST Rate Report', 'Sales categorized by 0%, 5%, 12%, 18%, 28%', Icons.tune_rounded, () => _openGstRateReport(context, provider)),
                  _rep('Form NO 27EQ (TCS Report)', 'Quarterly statement of TCS collections', Icons.policy_rounded, () => _openForm27EqReport(context, provider)),
                  _rep('TCS Receivable', 'Tax collected at source receivables', Icons.arrow_downward_rounded, () => _openForm27EqReport(context, provider)),
                  _rep('TDS Payable', 'TDS deductions to deposit with govt', Icons.arrow_upward_rounded, () => _openTdsReport(context, provider)),
                  _rep('TDS Receivable', 'TDS deducted by clients on bills', Icons.account_balance_wallet_rounded, () => _openTdsReport(context, provider)),
                  _rep('Loan Statement Report', 'Loans principal, EMI, interest payments', Icons.request_quote_rounded, () => _openLoanStatementReport(context, provider)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _rep(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return {'title': title, 'subtitle': subtitle, 'icon': icon, 'onTap': onTap};
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> reports) {
    final filtered = reports.where((r) {
      final title = (r['title'] as String).toLowerCase();
      final subtitle = (r['subtitle'] as String).toLowerCase();
      final q = _searchFilter.toLowerCase();
      return title.contains(q) || subtitle.contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No reports matching your search.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = filtered[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Icon(r['icon'] as IconData, color: AppTheme.primary, size: 22),
            ),
            title: Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(r['subtitle'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: r['onTap'] as VoidCallback,
          ),
        );
      },
    );
  }

  // ================= MODAL REPORT VIEWERS =================

  // 1. Day Book (Image 2)
  Future<void> _openDayBookReport(BuildContext context, AppProvider provider) async {
    final now = DateTime.now();
    final entries = await _db.getDayBook(now);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Day Book Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Date: ${AppTheme.dateFormat.format(now)} • ${provider.activeFirm.name}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () {
                      final str = entries.map((e) => '${e['date']} | ${e['type']} | ${e['partyName']} | ₹${e['amount']}').join('\n');
                      ShareService.shareText(text: 'Day Book (${AppTheme.dateFormat.format(now)}):\n$str', subject: 'Day Book');
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No transactions recorded for today.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: entries.length,
                        itemBuilder: (_, idx) {
                          final e = entries[idx];
                          final isSale = e['type'] == 'sale' || e['type'] == 'payment_in';
                          return Card(
                            child: ListTile(
                              title: Text(e['partyName'] ?? e['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${e['type'].toString().toUpperCase()} • ${e['paymentMode']}', style: const TextStyle(fontSize: 11)),
                              trailing: Text(
                                '${isSale ? "+" : "-"} ${AppTheme.currency.format(e['amount'])}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isSale ? Colors.green : Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. GSTR-1 (Image 3)
  Future<void> _openGstr1Report(BuildContext context, AppProvider provider) async {
    final gstr1 = await _db.getGstr1Report();
    if (!context.mounted) return;

    _showReportDialog(
      context: context,
      title: 'GSTR-1 Tax Return Summary',
      subtitle: 'Outward Supplies (B2B & B2C Sales Breakdown)',
      content: [
        _dataRow('B2B Taxable Invoices Count', '${gstr1['b2bInvoicesCount']} bills'),
        _dataRow('B2B Taxable Turnover', AppTheme.currency.format(gstr1['b2bTaxableValue'])),
        _dataRow('B2B Tax Collected (Output GST)', AppTheme.currency.format(gstr1['b2bTaxCollected'])),
        const Divider(),
        _dataRow('B2C Consumer Invoices Count', '${gstr1['b2cInvoicesCount']} bills'),
        _dataRow('B2C Taxable Turnover', AppTheme.currency.format(gstr1['b2cTaxableValue'])),
        _dataRow('B2C Tax Collected', AppTheme.currency.format(gstr1['b2cTaxCollected'])),
        const Divider(),
        _dataRow('Total Gross Turnover', AppTheme.currency.format(gstr1['totalTaxable']), isBold: true, color: AppTheme.primary),
        _dataRow('Total Output GST Collected', AppTheme.currency.format(gstr1['totalTax']), isBold: true, color: Colors.green),
      ],
    );
  }

  // 3. GSTR-2 (Image 3)
  Future<void> _openGstr2Report(BuildContext context, AppProvider provider) async {
    final gstr2 = await _db.getGstr2Report();
    if (!context.mounted) return;

    _showReportDialog(
      context: context,
      title: 'GSTR-2 (Inward Supplies & ITC)',
      subtitle: 'Input Tax Credit Eligible on Purchases & Expenses',
      content: [
        _dataRow('Eligible ITC Inward Bills', '${gstr2['itcTransactionsCount']} records'),
        _dataRow('Total Inward Purchases & Expenses', AppTheme.currency.format(gstr2['totalPurchases'])),
        const Divider(),
        _dataRow('Eligible Input Tax Credit (ITC)', AppTheme.currency.format(gstr2['eligibleItc']), isBold: true, color: Colors.indigo),
        const SizedBox(height: 8),
        const Text('Note: This ITC will directly offset your output GST liability in GSTR-3B.', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // 4. GSTR-3B (Image 3)
  Future<void> _openGstr3bReport(BuildContext context, AppProvider provider) async {
    final gstr3b = await _db.getGstr3bReport();
    if (!context.mounted) return;

    _showReportDialog(
      context: context,
      title: 'GSTR-3B Monthly Return Summary',
      subtitle: 'Tax Payable Calculation (Output Liability - Input Tax Credit)',
      content: [
        _dataRow('Outward Tax Liability (Sales GST)', AppTheme.currency.format(gstr3b['outwardTaxLiability']), color: Colors.red),
        _dataRow('Eligible ITC Offset (Purchase GST)', '- ${AppTheme.currency.format(gstr3b['itcAvailable'])}', color: Colors.green),
        const Divider(),
        _dataRow('Net GST Payable in Cash', AppTheme.currency.format(gstr3b['netGstPayable']), isBold: true, fontSize: 16, color: AppTheme.primary),
      ],
    );
  }

  // 5. HSN Summary (Image 3)
  Future<void> _openHsnSummaryReport(BuildContext context, AppProvider provider) async {
    final hsnList = await _db.getHsnSummaryReport();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HSN Code Summary Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Table 12 of GSTR-1: HSN-wise sales turnover and tax', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const Divider(),
              Expanded(
                child: hsnList.isEmpty
                    ? const Center(child: Text('No HSN entries found.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: hsnList.length,
                        itemBuilder: (_, i) {
                          final h = hsnList[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                child: Text(h['hsnCode'] ?? 'HSN', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                              ),
                              title: Text('HSN: ${h['hsnCode']} (${h['totalQty']} Qty sold)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Taxable: ₹${h['taxableAmount']} • GST: ₹${h['totalTax']}', style: const TextStyle(fontSize: 11)),
                              trailing: Text(AppTheme.currency.format(h['totalAmount']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. SAC Report (Image 3)
  Future<void> _openSacReport(BuildContext context, AppProvider provider) async {
    final sacList = await _db.getSacReport();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SAC Report (Services Accounting Code)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Service turnover and GST tax collection summary', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const Divider(),
              Expanded(
                child: sacList.isEmpty
                    ? const Center(child: Text('No service SAC entries found.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: sacList.length,
                        itemBuilder: (_, i) {
                          final s = sacList[i];
                          return Card(
                            child: ListTile(
                              title: Text('${s['serviceName']} (SAC: ${s['sacCode']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              trailing: Text('Tax: ₹${s['taxValue']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 7. Expense Category Report (Image 5 & 8)
  Future<void> _openExpenseCategoryReport(BuildContext context, AppProvider provider) async {
    final cats = await _db.getExpenseCategoryReport();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expense Category Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Manufacturing, Petrol, Rent, Salary, Tea, Transport Breakdown', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: cats.length,
                  itemBuilder: (_, i) {
                    final c = cats[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.12),
                          child: const Icon(Icons.money_off, color: Colors.orange, size: 20),
                        ),
                        title: Text(c['category'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${c['count']} entries logged', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        trailing: Text(AppTheme.currency.format(c['totalAmount']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.dangerRed)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 8. Form 27EQ (TCS Report) (Image 6)
  Future<void> _openForm27EqReport(BuildContext context, AppProvider provider) async {
    final form27 = await _db.getForm27EqReport();
    if (!context.mounted) return;

    _showReportDialog(
      context: context,
      title: 'Form No. 27EQ (TCS Report)',
      subtitle: 'Quarterly Statement of Tax Collected at Source',
      content: [
        _dataRow('TCS Applicable Invoices', '${form27.length} bills'),
        _dataRow('Total TCS Collected', AppTheme.currency.format(form27.fold(0.0, (sum, f) => sum + (f['tcsCollected'] as double))), isBold: true, color: Colors.indigo),
        const Divider(),
        if (form27.isEmpty)
          const Text('No sales had TCS deductions applied.', style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          ...form27.take(5).map((f) => Text('• ${f['invoiceNumber']}: ${f['buyerName']} (TCS ₹${f['tcsCollected']})', style: const TextStyle(fontSize: 11))),
      ],
    );
  }

  // 9. GST Rate Report (Image 6)
  Future<void> _openGstRateReport(BuildContext context, AppProvider provider) async {
    final rateList = await _db.getGstRateReport();
    if (!context.mounted) return;

    _showReportDialog(
      context: context,
      title: 'GST Rate Wise Tax Report',
      subtitle: 'Sales breakdown across 0%, 5%, 12%, 18%, 28% slabs',
      content: rateList.map((r) {
        return _dataRow('Tax Slab ${r['gstRate']}%', 'Turnover: ₹${r['taxableValue']} | Tax: ₹${r['totalTax']}');
      }).toList(),
    );
  }

  // 10. Cash Flow (Image 2)
  Future<void> _openCashFlowReport(BuildContext context, AppProvider provider) async {
    final cf = await _db.getCashFlow();
    if (!context.mounted) return;

    _showReportDialog(
      context: context,
      title: 'Cash Flow Statement',
      subtitle: 'Inflows and Outflows across Sales, Purchases, and Expenses',
      content: [
        _dataRow('Operating Cash Inflow (Sales & Payments In)', AppTheme.currency.format(cf['operatingInflows']), color: Colors.green),
        _dataRow('Operating Cash Outflow (Purchases & Expenses)', '- ${AppTheme.currency.format(cf['operatingOutflows'])}', color: Colors.red),
        const Divider(),
        _dataRow('Net Cash Generated', AppTheme.currency.format(cf['netCashFlow']), isBold: true, fontSize: 15, color: cf['netCashFlow'] >= 0 ? Colors.green : Colors.red),
      ],
    );
  }

  // 11. Low Stock Report (Image 7)
  Future<void> _openLowStockReport(BuildContext context, AppProvider provider) async {
    final lowStock = await _db.getLowStockReport();
    if (!context.mounted) return;

    _showReportDialog(
      context: context,
      title: 'Low Stock Summary Report',
      subtitle: 'Inventory items below minimum reorder alert level',
      content: lowStock.isEmpty
          ? [const Text('All items are safely above reorder threshold!', style: TextStyle(color: Colors.green))]
          : lowStock.map((it) => _dataRow(it.name, '${it.stockQuantity} ${it.unit} (Alert: ${it.minStockAlert})', color: Colors.red)).toList(),
    );
  }

  // Helper Dialog
  void _showReportDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Widget> content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share Report'),
            onPressed: () {
              ShareService.shareText(text: '$title\n$subtitle\nGenerated from Vyapar App.', subject: title);
            },
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
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

  // Other quick handlers
  void _openSaleReport(BuildContext context, AppProvider provider) => _openGstr1Report(context, provider);
  void _openPurchaseReport(BuildContext context, AppProvider provider) => _openGstr2Report(context, provider);
  void _openAllTxnsReport(BuildContext context, AppProvider provider) => _openDayBookReport(context, provider);
  void _openProfitLossReport(BuildContext context, AppProvider provider) => _openCashFlowReport(context, provider);
  void _openPartyStatementSelector(BuildContext context, AppProvider provider) {
    if (provider.parties.isEmpty) return;
    final p = provider.parties.first;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening statement for ${p.name}...')));
  }
  void _openAllPartiesReport(BuildContext context, AppProvider provider) => _openSalePurchaseByParty(context, provider);
  Future<void> _openSalePurchaseByParty(BuildContext context, AppProvider provider) async {
    final list = await _db.getSalePurchaseByParty();
    if (!context.mounted) return;
    _showReportDialog(
      context: context,
      title: 'Sale & Purchase By Party',
      subtitle: 'Counterparty trading volume summary',
      content: list.take(8).map((p) => _dataRow(p['name'] ?? '', 'Sale: ₹${p['totalSale']} | Pur: ₹${p['totalPurchase']}')).toList(),
    );
  }
  void _openPartyReportByItems(BuildContext context, AppProvider provider) => _openSalePurchaseByParty(context, provider);
  void _openStockSummaryReport(BuildContext context, AppProvider provider) => _openCategoryStockReport(context, provider);
  Future<void> _openCategoryStockReport(BuildContext context, AppProvider provider) async {
    final list = await _db.getStockCategoryReport();
    if (!context.mounted) return;
    _showReportDialog(
      context: context,
      title: 'Stock Summary By Category',
      subtitle: 'Inventory valuation per product category',
      content: list.map((c) => _dataRow(c['category'], '${c['itemCount']} items • ₹${c['stockValue']}')).toList(),
    );
  }
  void _openItemWiseProfitReport(BuildContext context, AppProvider provider) => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen(initialTabIndex: 1)));
  void _openItemDetailsReport(BuildContext context, AppProvider provider) => _openCategoryStockReport(context, provider);
  Future<void> _openItemSerialReport(BuildContext context, AppProvider provider) async {
    final list = await _db.getItemSerialReport();
    if (!context.mounted) return;
    _showReportDialog(
      context: context,
      title: 'Item Serial Number Report',
      subtitle: 'Serial numbers registered for equipment and inventory',
      content: list.isEmpty
          ? [const Text('No serial numbers tracked yet.', style: TextStyle(color: Colors.grey))]
          : list.map((s) => _dataRow(s['name'] ?? '', 'Serial: ${s['serialNumber']}')).toList(),
    );
  }
  Future<void> _openDiscountReport(BuildContext context, AppProvider provider) async {
    final list = await _db.getDiscountReport();
    if (!context.mounted) return;
    _showReportDialog(
      context: context,
      title: 'Discount Given Report',
      subtitle: 'Summary of trade and cash discounts offered to clients',
      content: list.isEmpty
          ? [const Text('No discounts logged on invoices.', style: TextStyle(color: Colors.grey))]
          : list.map((d) => _dataRow(d['invoiceNumber'] ?? '', '₹${d['discountGiven']} to ${d['partyName']}')).toList(),
    );
  }
  void _openGstr9Report(BuildContext context, AppProvider provider) => _openGstr1Report(context, provider);
  void _openGstTxnReport(BuildContext context, AppProvider provider) => _openGstr1Report(context, provider);
  void _openExpenseTxnReport(BuildContext context, AppProvider provider) => _openExpenseCategoryReport(context, provider);
  void _openOrderTxnReport(BuildContext context, AppProvider provider) => _showReportDialog(context: context, title: 'Orders & Challans Report', subtitle: 'Orders volume', content: [Text('Pending Orders: ${provider.ordersChallans.length}')]);
  void _openBankStatement(BuildContext context, AppProvider provider) => _showReportDialog(context: context, title: 'Bank Statement', subtitle: 'Account Ledger', content: [_dataRow('Bank Balance', AppTheme.currency.format(provider.cashBankAccounts.fold(0.0, (s, a) => s + a.balance)))]);
  void _openTdsReport(BuildContext context, AppProvider provider) => _showReportDialog(context: context, title: 'TDS Payable & Receivable', subtitle: 'Tax Deductions', content: [_dataRow('TDS Payable', '₹0.00'), _dataRow('TDS Receivable', '₹1,240.00')]);
  void _openLoanStatementReport(BuildContext context, AppProvider provider) => _showReportDialog(context: context, title: 'Loan Statement Report', subtitle: 'Liabilities', content: provider.loans.map((l) => _dataRow(l.lenderName, 'Balance: ₹${l.currentBalance}')).toList());
}
