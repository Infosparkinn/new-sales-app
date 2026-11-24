class FixedAsset {
  final String id;
  final String firmId;
  final String name;
  final String category; // 'Furniture', 'Machinery', 'Vehicles', 'IT Equipment', 'Building'
  final DateTime purchaseDate;
  final double purchaseAmount;
  final double currentBookValue;
  final double depreciationRatePercent;
  final String notes;

  FixedAsset({
    required this.id,
    required this.firmId,
    required this.name,
    this.category = 'Furniture',
    required this.purchaseDate,
    required this.purchaseAmount,
    required this.currentBookValue,
    this.depreciationRatePercent = 10.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'name': name,
      'category': category,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchaseAmount': purchaseAmount,
      'currentBookValue': currentBookValue,
      'depreciationRatePercent': depreciationRatePercent,
      'notes': notes,
    };
  }

  factory FixedAsset.fromMap(Map<String, dynamic> map) {
    return FixedAsset(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Furniture',
      purchaseDate: map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate']) : DateTime.now(),
      purchaseAmount: (map['purchaseAmount'] as num?)?.toDouble() ?? 0.0,
      currentBookValue: (map['currentBookValue'] as num?)?.toDouble() ?? 0.0,
      depreciationRatePercent: (map['depreciationRatePercent'] as num?)?.toDouble() ?? 10.0,
      notes: map['notes'] ?? '',
    );
  }

  FixedAsset copyWith({
    String? id,
    String? firmId,
    String? name,
    String? category,
    DateTime? purchaseDate,
    double? purchaseAmount,
    double? currentBookValue,
    double? depreciationRatePercent,
    String? notes,
  }) {
    return FixedAsset(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      currentBookValue: currentBookValue ?? this.currentBookValue,
      depreciationRatePercent: depreciationRatePercent ?? this.depreciationRatePercent,
      notes: notes ?? this.notes,
    );
  }
}
