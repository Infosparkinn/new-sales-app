class Account {
  final String id;
  final String firmId;
  final String code;
  final String name;
  final String category; // 'Asset', 'Liability', 'Equity', 'Income', 'Expense'
  final double balance;

  Account({
    required this.id,
    required this.firmId,
    required this.code,
    required this.name,
    required this.category,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'code': code,
      'name': name,
      'category': category,
      'balance': balance,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Asset',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class JournalEntry {
  final String id;
  final String firmId;
  final DateTime date;
  final String description;
  final String debitAccountId;
  final String debitAccountName;
  final String creditAccountId;
  final String creditAccountName;
  final double amount;
  final String referenceType; // 'sale', 'purchase', 'expense', 'payment', 'manual'
  final String referenceId;

  JournalEntry({
    required this.id,
    required this.firmId,
    required this.date,
    required this.description,
    required this.debitAccountId,
    required this.debitAccountName,
    required this.creditAccountId,
    required this.creditAccountName,
    required this.amount,
    this.referenceType = 'manual',
    this.referenceId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'date': date.toIso8601String(),
      'description': description,
      'debitAccountId': debitAccountId,
      'debitAccountName': debitAccountName,
      'creditAccountId': creditAccountId,
      'creditAccountName': creditAccountName,
      'amount': amount,
      'referenceType': referenceType,
      'referenceId': referenceId,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      description: map['description'] ?? '',
      debitAccountId: map['debitAccountId'] ?? '',
      debitAccountName: map['debitAccountName'] ?? '',
      creditAccountId: map['creditAccountId'] ?? '',
      creditAccountName: map['creditAccountName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      referenceType: map['referenceType'] ?? 'manual',
      referenceId: map['referenceId'] ?? '',
    );
  }
}
