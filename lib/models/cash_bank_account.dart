class CashBankAccount {
  final String id;
  final String firmId;
  final String name;
  final String accountType; // 'bank', 'cash', 'gpay', 'credit_card'
  final double balance;
  final String accountNumber;
  final String ifsc;
  final String upiId;
  final String notes;

  CashBankAccount({
    required this.id,
    required this.firmId,
    required this.name,
    required this.accountType,
    required this.balance,
    this.accountNumber = '',
    this.ifsc = '',
    this.upiId = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'name': name,
      'accountType': accountType,
      'balance': balance,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
      'upiId': upiId,
      'notes': notes,
    };
  }

  factory CashBankAccount.fromMap(Map<String, dynamic> map) {
    return CashBankAccount(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      name: map['name'] ?? '',
      accountType: map['accountType'] ?? 'cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      accountNumber: map['accountNumber'] ?? '',
      ifsc: map['ifsc'] ?? '',
      upiId: map['upiId'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  CashBankAccount copyWith({
    String? id,
    String? firmId,
    String? name,
    String? accountType,
    double? balance,
    String? accountNumber,
    String? ifsc,
    String? upiId,
    String? notes,
  }) {
    return CashBankAccount(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      upiId: upiId ?? this.upiId,
      notes: notes ?? this.notes,
    );
  }
}

class BankTransaction {
  final String id;
  final String firmId;
  final String fromAccountId;
  final String fromAccountName;
  final String toAccountId;
  final String toAccountName;
  final double amount;
  final DateTime date;
  final String description;
  final String type; // 'transfer', 'deposit', 'withdrawal'

  BankTransaction({
    required this.id,
    required this.firmId,
    required this.fromAccountId,
    required this.fromAccountName,
    required this.toAccountId,
    required this.toAccountName,
    required this.amount,
    required this.date,
    this.description = '',
    this.type = 'transfer',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'fromAccountId': fromAccountId,
      'fromAccountName': fromAccountName,
      'toAccountId': toAccountId,
      'toAccountName': toAccountName,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'type': type,
    };
  }

  factory BankTransaction.fromMap(Map<String, dynamic> map) {
    return BankTransaction(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      fromAccountId: map['fromAccountId'] ?? '',
      fromAccountName: map['fromAccountName'] ?? '',
      toAccountId: map['toAccountId'] ?? '',
      toAccountName: map['toAccountName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      description: map['description'] ?? '',
      type: map['type'] ?? 'transfer',
    );
  }
}
