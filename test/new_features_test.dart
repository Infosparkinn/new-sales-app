import 'package:flutter_test/flutter_test.dart';
import 'package:new_sales_app/models/cash_bank_account.dart';
import 'package:new_sales_app/models/loyalty_points.dart';
import 'package:new_sales_app/models/loan_account.dart';

void main() {
  group('Cash & Bank Models Test', () {
    test('CashBankAccount serialization & copyWith', () {
      final acc = CashBankAccount(
        id: 'acc_1',
        firmId: 'firm_1',
        name: 'HDFC Current',
        accountType: 'bank',
        balance: 50000.0,
        accountNumber: '1234567890',
        ifsc: 'HDFC0001234',
        upiId: 'hdfc@upi',
      );

      final map = acc.toMap();
      expect(map['name'], 'HDFC Current');
      expect(map['balance'], 50000.0);

      final fromMap = CashBankAccount.fromMap(map);
      expect(fromMap.id, 'acc_1');
      expect(fromMap.accountType, 'bank');

      final updated = acc.copyWith(balance: 75000.0);
      expect(updated.balance, 75000.0);
      expect(updated.name, 'HDFC Current');
    });

    test('BankTransaction serialization', () {
      final now = DateTime.now();
      final txn = BankTransaction(
        id: 'txn_1',
        firmId: 'firm_1',
        fromAccountId: 'acc_cash',
        fromAccountName: 'Cash in Hand',
        toAccountId: 'acc_bank',
        toAccountName: 'HDFC Bank',
        amount: 10000.0,
        date: now,
        description: 'Deposited counter cash to bank',
      );

      final map = txn.toMap();
      expect(map['amount'], 10000.0);
      expect(map['fromAccountName'], 'Cash in Hand');
      expect(map['toAccountName'], 'HDFC Bank');
    });
  });

  group('Loyalty & Loans Models Test', () {
    test('LoyaltyRecord calculation', () {
      final rec = LoyaltyRecord(
        id: 'lr_1',
        firmId: 'firm_1',
        partyId: 'p_1',
        partyName: 'Ramesh Stores',
        points: 150,
        type: 'earned',
        date: DateTime.now(),
      );

      final map = rec.toMap();
      expect(map['points'], 150);
      expect(map['type'], 'earned');

      const config = LoyaltyProgramConfig(earnRate: 100.0, pointValueInRupees: 1.0);
      expect(config.earnRate, 100.0);
      expect(config.pointValueInRupees, 1.0);
    });

    test('LoanAccount & EMI calculations', () {
      final loan = LoanAccount(
        id: 'loan_1',
        firmId: 'firm_1',
        lenderName: 'HDFC MSME Finance',
        principalAmount: 500000.0,
        currentBalance: 320000.0,
        interestRatePercent: 10.5,
        emiAmount: 18500.0,
        tenureMonths: 36,
        startDate: DateTime.now(),
      );

      final map = loan.toMap();
      expect(map['principalAmount'], 500000.0);
      expect(map['currentBalance'], 320000.0);
      expect(map['interestRatePercent'], 10.5);
    });
  });
}
