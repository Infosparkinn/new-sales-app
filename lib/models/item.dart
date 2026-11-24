import 'dart:convert';

class Item {
  final String id;
  final String firmId;
  final String name;
  final String code; // Barcode or Item SKU
  final String category;
  final String unit; // Pcs, Kg, Box, Ltr, Mtr, etc.
  final double salePrice;
  final double wholesalePrice;
  final double dealerPrice;
  final double purchasePrice;
  final double taxRate; // GST slab: 0, 5, 12, 18, 28
  final String hsnCode;
  final double stockQuantity;
  final double minStockAlert;
  final bool isTaxInclusive;
  final String batchNumber;
  final DateTime? expiryDate;
  final String serialNumber;
  final Map<String, String> customFields;
  final DateTime updatedAt;

  Item({
    required this.id,
    this.firmId = 'default_firm',
    required this.name,
    this.code = '',
    this.category = 'General',
    this.unit = 'Pcs',
    required this.salePrice,
    this.wholesalePrice = 0.0,
    this.dealerPrice = 0.0,
    this.purchasePrice = 0.0,
    this.taxRate = 0.0,
    this.hsnCode = '',
    this.stockQuantity = 0.0,
    this.minStockAlert = 5.0,
    this.isTaxInclusive = true,
    this.batchNumber = '',
    this.expiryDate,
    this.serialNumber = '',
    this.customFields = const {},
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => stockQuantity <= minStockAlert;

  double getPriceForTier(String tier) {
    if (tier == 'wholesale' && wholesalePrice > 0) return wholesalePrice;
    if (tier == 'dealer' && dealerPrice > 0) return dealerPrice;
    return salePrice;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'name': name,
      'code': code,
      'category': category,
      'unit': unit,
      'salePrice': salePrice,
      'wholesalePrice': wholesalePrice,
      'dealerPrice': dealerPrice,
      'purchasePrice': purchasePrice,
      'taxRate': taxRate,
      'hsnCode': hsnCode,
      'stockQuantity': stockQuantity,
      'minStockAlert': minStockAlert,
      'isTaxInclusive': isTaxInclusive ? 1 : 0,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'serialNumber': serialNumber,
      'customFieldsJson': jsonEncode(customFields),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    Map<String, String> parsedCustom = {};
    if (map['customFieldsJson'] != null && map['customFieldsJson'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['customFieldsJson']);
        if (decoded is Map) {
          parsedCustom = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    return Item(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      category: map['category'] ?? 'General',
      unit: map['unit'] ?? 'Pcs',
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      dealerPrice: (map['dealerPrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      hsnCode: map['hsnCode'] ?? '',
      stockQuantity: (map['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      minStockAlert: (map['minStockAlert'] as num?)?.toDouble() ?? 5.0,
      isTaxInclusive: (map['isTaxInclusive'] ?? 1) == 1,
      batchNumber: map['batchNumber'] ?? '',
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate']) : null,
      serialNumber: map['serialNumber'] ?? '',
      customFields: parsedCustom,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  Item copyWith({
    String? id,
    String? firmId,
    String? name,
    String? code,
    String? category,
    String? unit,
    double? salePrice,
    double? wholesalePrice,
    double? dealerPrice,
    double? purchasePrice,
    double? taxRate,
    String? hsnCode,
    double? stockQuantity,
    double? minStockAlert,
    bool? isTaxInclusive,
    String? batchNumber,
    DateTime? expiryDate,
    String? serialNumber,
    Map<String, String>? customFields,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      salePrice: salePrice ?? this.salePrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      dealerPrice: dealerPrice ?? this.dealerPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      taxRate: taxRate ?? this.taxRate,
      hsnCode: hsnCode ?? this.hsnCode,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      serialNumber: serialNumber ?? this.serialNumber,
      customFields: customFields ?? this.customFields,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
