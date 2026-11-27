import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/loan_account.dart';
import '../../providers/app_provider.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
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
    final loans = provider.loans;

    final activeLoans = loans.where((l) => l.currentBalance > 0).toList();
    final paidOffLoans = loans.where((l) => l.currentBalance <= 0).toList();

    final totalOutstanding = loans.fold(0.0, (sum, l) => sum + l.currentBalance);
    final totalMonthlyEmi = activeLoans.fold(0.0, (sum, l) => sum + l.emiAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans & EMI Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Loan Account',
            onPressed: () => _showAddLoanDialog(context, provider),
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
            Tab(text: 'ACTIVE LOANS (${activeLoans.length})'),
            Tab(text: 'PAID OFF (${paidOffLoans.length})'),
            Tab(text: 'EMI SUMMARY'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Overall Liabilities Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.darkNavyGradient,
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL LOAN OUTSTANDING',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppTheme.currency.format(totalOutstanding),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                        'TOTAL MONTHLY EMI',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppTheme.currency.format(totalMonthlyEmi),
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
                _buildLoansList(activeLoans, provider, 'No active loan liabilities', 'Business loans, machinery financing, and credit facilities will show here.'),
                _buildLoansList(paidOffLoans, provider, 'No fully repaid loans', 'Loans with zero balance will be tracked here.'),
                _buildEmiSummaryTab(activeLoans, totalMonthlyEmi, totalOutstanding),
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
          label: const Text('Add Loan', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showAddLoanDialog(context, provider),
        ),
      ),
    );
  }

  Widget _buildLoansList(List<LoanAccount> list, AppProvider provider, String emptyTitle, String emptySubtitle) {
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
                child: const Icon(Icons.account_balance_outlined, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Text(emptyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(emptySubtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Loan Account'),
                onPressed: () => _showAddLoanDialog(context, provider),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final loan = list[index];
        final paidPct = loan.principalAmount > 0
            ? ((loan.principalAmount - loan.currentBalance) / loan.principalAmount).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: AppTheme.border.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loan.lenderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${loan.interestRatePercent}% p.a.',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Sanctioned: ${AppTheme.currency.format(loan.principalAmount)} • EMI: ${AppTheme.currency.format(loan.emiAmount)}/mo',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: paidPct,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successGreen),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outstanding: ${AppTheme.currency.format(loan.currentBalance)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.payment_rounded, size: 14),
                      label: const Text('Pay EMI', style: TextStyle(fontSize: 11)),
                      onPressed: () => _showRecordPaymentDialog(context, provider, loan),
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

  Widget _buildEmiSummaryTab(List<LoanAccount> activeLoans, double monthlyEmi, double totalOutstanding) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.modernCardDecoration(
            backgroundColor: Colors.white,
            borderRadius: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MONTHLY EMI OUTFLOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(AppTheme.currency.format(monthlyEmi), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 4),
              Text('Recurring commitment across ${activeLoans.length} active business loans', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('ACTIVE COMMITMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...activeLoans.map((l) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.modernCardDecoration(borderRadius: 12),
              child: ListTile(
                title: Text(l.lenderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Tenure: ${l.tenureMonths} months • Rate: ${l.interestRatePercent}%', style: const TextStyle(fontSize: 11)),
                trailing: Text(AppTheme.currency.format(l.emiAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.dangerRed)),
              ),
            )),
      ],
    );
  }

  void _showAddLoanDialog(BuildContext context, AppProvider provider) {
    final lenderController = TextEditingController();
    final principalController = TextEditingController();
    final balanceController = TextEditingController();
    final interestController = TextEditingController(text: '10.5');
    final emiController = TextEditingController();
    final tenureController = TextEditingController(text: '36');
    String type = 'term_loan';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Business Loan Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: lenderController, decoration: const InputDecoration(labelText: 'Lender Name (Bank / NBFC) *')),
              const SizedBox(height: 10),
              TextField(controller: principalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sanctioned Loan Amount (₹)')),
              const SizedBox(height: 10),
              TextField(controller: balanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Outstanding Balance (₹)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: interestController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Interest Rate %'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: emiController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly EMI (₹)'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: tenureController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tenure (Months)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (lenderController.text.trim().isEmpty) return;
              final principal = double.tryParse(principalController.text) ?? 0.0;
              final balance = double.tryParse(balanceController.text) ?? principal;
              final interest = double.tryParse(interestController.text) ?? 10.0;
              final emi = double.tryParse(emiController.text) ?? 0.0;
              final tenure = int.tryParse(tenureController.text) ?? 12;

              final loan = LoanAccount(
                id: _uuid.v4(),
                firmId: provider.activeFirm.id,
                lenderName: lenderController.text.trim(),
                loanType: type,
                principalAmount: principal,
                currentBalance: balance,
                interestRatePercent: interest,
                emiAmount: emi,
                tenureMonths: tenure,
                startDate: DateTime.now(),
              );
              await provider.saveLoan(loan);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Loan'),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, AppProvider provider, LoanAccount loan) {
    final amountController = TextEditingController(text: loan.emiAmount > 0 ? loan.emiAmount.toString() : '');
    final principalController = TextEditingController();
    final interestController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record Payment - ${loan.lenderName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total EMI / Repayment Paid (₹)')),
            const SizedBox(height: 10),
            TextField(controller: principalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Principal Reduction Part (₹)')),
            const SizedBox(height: 10),
            TextField(controller: interestController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Interest Component (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              if (amt <= 0) return;
              final prin = double.tryParse(principalController.text) ?? (amt * 0.7);
              final interest = double.tryParse(interestController.text) ?? (amt - prin);

              final payment = LoanPayment(
                id: _uuid.v4(),
                loanId: loan.id,
                date: DateTime.now(),
                amount: amt,
                principalPart: prin,
                interestPart: interest,
              );
              await provider.recordLoanPayment(payment);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recorded EMI of ₹$amt! Balance updated.')));
              }
            },
            child: const Text('Record EMI'),
          ),
        ],
      ),
    );
  }
}
