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

class _LoansScreenState extends State<LoansScreen> {
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final loans = provider.loans;

    final totalOutstanding = loans.fold(0.0, (sum, l) => sum + l.currentBalance);
    final totalMonthlyEmi = loans.fold(0.0, (sum, l) => sum + l.emiAmount);

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loans Overview Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueGrey, Color(0xFF263238)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BUSINESS LIABILITIES • LOANS',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Outstanding', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(AppTheme.currency.format(totalOutstanding),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Monthly EMI', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(AppTheme.currency.format(totalMonthlyEmi),
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ACTIVE LOAN ACCOUNTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                Text('${loans.length} Accounts', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),

            if (loans.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: const Text('No business loans recorded.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: loans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final loan = loans[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(loan.lenderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text(loan.loanType, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Principal: ${AppTheme.currency.format(loan.principalAmount)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              Text('Interest: ${loan.interestRatePercent}% p.a.', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Balance: ${AppTheme.currency.format(loan.currentBalance)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                              Text('EMI: ${AppTheme.currency.format(loan.emiAmount)} / mo', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.payment_rounded, size: 16),
                                label: const Text('Record EMI / Payment'),
                                onPressed: () => _showRecordPaymentDialog(context, provider, loan),
                              ),
                            ],
                          ),
                        ],
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

  void _showAddLoanDialog(BuildContext context, AppProvider provider) {
    final lenderController = TextEditingController();
    final principalController = TextEditingController();
    final balanceController = TextEditingController();
    final interestController = TextEditingController(text: '10.5');
    final emiController = TextEditingController();
    final tenureController = TextEditingController(text: '36');
    String type = 'Term Loan';

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
              Navigator.pop(ctx);
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
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recorded EMI of ₹$amt! Balance updated.')));
            },
            child: const Text('Record EMI'),
          ),
        ],
      ),
    );
  }
}
