import 'dart:convert';

class Party {
  final String id;
  final String firmId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String state;
  final String gstin;
  final String partyType; // 'customer' or 'supplier'
  final double openingBalance;
  final double currentBalance; // Positive: To Receive (Receivable), Negative: To Pay (Payable)
  final double creditLimit;
  final String priceTier; // 'retail', 'wholesale', 'dealer'
  final Map<String, double> customRates; // Item ID -> Custom price
  final DateTime createdAt;

  Party({
    required this.id,
    this.firmId = 'default_firm',
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.state = 'Tamil Nadu',
    this.gstin = '',
    this.partyType = 'customer',
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.creditLimit = 0.0,
    this.priceTier = 'retail',
    this.customRates = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCustomer => partyType == 'customer';
  bool get isSupplier => partyType == 'supplier';
  bool get hasExceededCreditLimit => creditLimit > 0 && currentBalance > creditLimit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'state': state,
      'gstin': gstin,
      'partyType': partyType,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'creditLimit': creditLimit,
      'priceTier': priceTier,
      'customRatesJson': jsonEncode(customRates),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    Map<String, double> parsedRates = {};
    if (map['customRatesJson'] != null && map['customRatesJson'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['customRatesJson']);
        if (decoded is Map) {
          parsedRates = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
        }
      } catch (_) {}
    }

    return Party(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      state: map['state'] ?? 'Tamil Nadu',
      gstin: map['gstin'] ?? '',
      partyType: map['partyType'] ?? 'customer',
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0.0,
      priceTier: map['priceTier'] ?? 'retail',
      customRates: parsedRates,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  Party copyWith({
    String? id,
    String? firmId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? state,
    String? gstin,
    String? partyType,
    double? openingBalance,
    double? currentBalance,
    double? creditLimit,
    String? priceTier,
    Map<String, double>? customRates,
    DateTime? createdAt,
  }) {
    return Party(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      state: state ?? this.state,
      gstin: gstin ?? this.gstin,
      partyType: partyType ?? this.partyType,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      priceTier: priceTier ?? this.priceTier,
      customRates: customRates ?? this.customRates,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
