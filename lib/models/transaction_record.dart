class TransactionRecord {
  final String id;
  final String firmId;
  final DateTime date;
  final String type; // 'sale', 'purchase', 'payment_in', 'payment_out', 'expense'
  final String? partyId;
  final String partyName;
  final double amount;
  final String paymentMode;
  final String referenceId;
  final String description;
  final bool isItcEligible; // Input Tax Credit
  final String gstin;
  final double taxRate;
  final double cgstAmount;
  final double sgstAmount;
  final bool isDeleted; // Recycle bin

  TransactionRecord({
    required this.id,
    this.firmId = 'default_firm',
    required this.date,
    required this.type,
    this.partyId,
    required this.partyName,
    required this.amount,
    this.paymentMode = 'cash',
    this.referenceId = '',
    this.description = '',
    this.isItcEligible = false,
    this.gstin = '',
    this.taxRate = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.isDeleted = false,
  });

  bool get isIncome => type == 'sale' || type == 'payment_in';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'date': date.toIso8601String(),
      'type': type,
      'partyId': partyId,
      'partyName': partyName,
      'amount': amount,
      'paymentMode': paymentMode,
      'referenceId': referenceId,
      'description': description,
      'isItcEligible': isItcEligible ? 1 : 0,
      'gstin': gstin,
      'taxRate': taxRate,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      type: map['type'] ?? 'sale',
      partyId: map['partyId'],
      partyName: map['partyName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] ?? 'cash',
      referenceId: map['referenceId'] ?? '',
      description: map['description'] ?? '',
      isItcEligible: (map['isItcEligible'] ?? 0) == 1,
      gstin: map['gstin'] ?? '',
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (map['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (map['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      isDeleted: (map['isDeleted'] ?? 0) == 1,
    );
  }
}
