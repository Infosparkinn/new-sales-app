class LoanAccount {
  final String id;
  final String firmId;
  final String lenderName;
  final String loanType; // 'Term Loan', 'Overdraft/CC', 'Vehicle Loan', 'Personal/Partner'
  final double principalAmount;
  final double currentBalance;
  final double interestRatePercent;
  final double emiAmount;
  final int tenureMonths;
  final DateTime startDate;
  final String bankAccountRef;
  final String notes;

  LoanAccount({
    required this.id,
    required this.firmId,
    required this.lenderName,
    this.loanType = 'Term Loan',
    required this.principalAmount,
    required this.currentBalance,
    required this.interestRatePercent,
    required this.emiAmount,
    required this.tenureMonths,
    required this.startDate,
    this.bankAccountRef = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'lenderName': lenderName,
      'loanType': loanType,
      'principalAmount': principalAmount,
      'currentBalance': currentBalance,
      'interestRatePercent': interestRatePercent,
      'emiAmount': emiAmount,
      'tenureMonths': tenureMonths,
      'startDate': startDate.toIso8601String(),
      'bankAccountRef': bankAccountRef,
      'notes': notes,
    };
  }

  factory LoanAccount.fromMap(Map<String, dynamic> map) {
    return LoanAccount(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      lenderName: map['lenderName'] ?? '',
      loanType: map['loanType'] ?? 'Term Loan',
      principalAmount: (map['principalAmount'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      interestRatePercent: (map['interestRatePercent'] as num?)?.toDouble() ?? 0.0,
      emiAmount: (map['emiAmount'] as num?)?.toDouble() ?? 0.0,
      tenureMonths: (map['tenureMonths'] as num?)?.toInt() ?? 12,
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      bankAccountRef: map['bankAccountRef'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  LoanAccount copyWith({
    String? id,
    String? firmId,
    String? lenderName,
    String? loanType,
    double? principalAmount,
    double? currentBalance,
    double? interestRatePercent,
    double? emiAmount,
    int? tenureMonths,
    DateTime? startDate,
    String? bankAccountRef,
    String? notes,
  }) {
    return LoanAccount(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      lenderName: lenderName ?? this.lenderName,
      loanType: loanType ?? this.loanType,
      principalAmount: principalAmount ?? this.principalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      emiAmount: emiAmount ?? this.emiAmount,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      startDate: startDate ?? this.startDate,
      bankAccountRef: bankAccountRef ?? this.bankAccountRef,
      notes: notes ?? this.notes,
    );
  }
}

class LoanPayment {
  final String id;
  final String loanId;
  final DateTime date;
  final double amount;
  final double principalPart;
  final double interestPart;
  final String paymentMode;
  final String notes;

  LoanPayment({
    required this.id,
    required this.loanId,
    required this.date,
    required this.amount,
    required this.principalPart,
    required this.interestPart,
    this.paymentMode = 'bank',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanId': loanId,
      'date': date.toIso8601String(),
      'amount': amount,
      'principalPart': principalPart,
      'interestPart': interestPart,
      'paymentMode': paymentMode,
      'notes': notes,
    };
  }

  factory LoanPayment.fromMap(Map<String, dynamic> map) {
    return LoanPayment(
      id: map['id'] ?? '',
      loanId: map['loanId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      principalPart: (map['principalPart'] as num?)?.toDouble() ?? 0.0,
      interestPart: (map['interestPart'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] ?? 'bank',
      notes: map['notes'] ?? '',
    );
  }
}
