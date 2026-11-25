class LoyaltyRecord {
  final String id;
  final String firmId;
  final String partyId;
  final String partyName;
  final int points;
  final String type; // 'earned', 'redeemed'
  final String invoiceId;
  final DateTime date;
  final String notes;

  LoyaltyRecord({
    required this.id,
    required this.firmId,
    required this.partyId,
    required this.partyName,
    required this.points,
    required this.type,
    this.invoiceId = '',
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'partyId': partyId,
      'partyName': partyName,
      'points': points,
      'type': type,
      'invoiceId': invoiceId,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory LoyaltyRecord.fromMap(Map<String, dynamic> map) {
    return LoyaltyRecord(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      partyId: map['partyId'] ?? '',
      partyName: map['partyName'] ?? '',
      points: (map['points'] as num?)?.toInt() ?? 0,
      type: map['type'] ?? 'earned',
      invoiceId: map['invoiceId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
}

class LoyaltyProgramConfig {
  final double earnRate; // Earn 1 point per X rupees spent (e.g. 100)
  final double pointValueInRupees; // 1 point = X rupees discount (e.g. 1.0)
  final bool isEnabled;

  const LoyaltyProgramConfig({
    this.earnRate = 100.0,
    this.pointValueInRupees = 1.0,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'earnRate': earnRate,
      'pointValueInRupees': pointValueInRupees,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory LoyaltyProgramConfig.fromMap(Map<String, dynamic> map) {
    return LoyaltyProgramConfig(
      earnRate: (map['earnRate'] as num?)?.toDouble() ?? 100.0,
      pointValueInRupees: (map['pointValueInRupees'] as num?)?.toDouble() ?? 1.0,
      isEnabled: (map['isEnabled'] ?? 1) == 1,
    );
  }
}
