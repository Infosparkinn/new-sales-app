class OrderChallanItem {
  final String id;
  final String orderChallanId;
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double taxRate;
  final double totalAmount;

  OrderChallanItem({
    required this.id,
    required this.orderChallanId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    this.unit = 'Pcs',
    required this.unitPrice,
    this.taxRate = 0.0,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderChallanId': orderChallanId,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'totalAmount': totalAmount,
    };
  }

  factory OrderChallanItem.fromMap(Map<String, dynamic> map) {
    return OrderChallanItem(
      id: map['id'] ?? '',
      orderChallanId: map['orderChallanId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] ?? 'Pcs',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderChallan {
  final String id;
  final String firmId;
  final String type; // 'sale_order', 'delivery_challan'
  final String documentNumber;
  final String partyId;
  final String partyName;
  final String partyPhone;
  final DateTime date;
  final double totalAmount;
  final String status; // 'open', 'converted_to_sale', 'cancelled'
  final String notes;
  final List<OrderChallanItem> items;

  OrderChallan({
    required this.id,
    required this.firmId,
    required this.type,
    required this.documentNumber,
    required this.partyId,
    required this.partyName,
    this.partyPhone = '',
    required this.date,
    required this.totalAmount,
    this.status = 'open',
    this.notes = '',
    this.items = const [],
  });

  bool get isOpen => status == 'open';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'type': type,
      'documentNumber': documentNumber,
      'partyId': partyId,
      'partyName': partyName,
      'partyPhone': partyPhone,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'notes': notes,
    };
  }

  factory OrderChallan.fromMap(Map<String, dynamic> map, [List<OrderChallanItem> items = const []]) {
    return OrderChallan(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      type: map['type'] ?? 'sale_order',
      documentNumber: map['documentNumber'] ?? '',
      partyId: map['partyId'] ?? '',
      partyName: map['partyName'] ?? '',
      partyPhone: map['partyPhone'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'open',
      notes: map['notes'] ?? '',
      items: items,
    );
  }
}
