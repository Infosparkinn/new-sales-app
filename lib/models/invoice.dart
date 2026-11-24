class InvoiceItem {
  final String id;
  final String invoiceId;
  final String itemId;
  final String itemName;
  final String hsnCode;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double purchasePrice; // For Profit calculation
  final double discountPercent;
  final double taxRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;
  final String batchNumber;
  final String serialNumber;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.itemId,
    required this.itemName,
    this.hsnCode = '',
    required this.quantity,
    this.unit = 'Pcs',
    required this.unitPrice,
    this.purchasePrice = 0.0,
    this.discountPercent = 0.0,
    this.taxRate = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    required this.totalAmount,
    this.batchNumber = '',
    this.serialNumber = '',
  });

  double get profit => (unitPrice - purchasePrice) * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'itemId': itemId,
      'itemName': itemName,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'purchasePrice': purchasePrice,
      'discountPercent': discountPercent,
      'taxRate': taxRate,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'totalAmount': totalAmount,
      'batchNumber': batchNumber,
      'serialNumber': serialNumber,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] ?? '',
      invoiceId: map['invoiceId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      hsnCode: map['hsnCode'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] ?? 'Pcs',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (map['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (map['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (map['igstAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      batchNumber: map['batchNumber'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
    );
  }
}

class Invoice {
  final String id;
  final String firmId;
  final String invoiceNumber;
  final String? partyId;
  final String partyName;
  final String partyPhone;
  final String partyAddress;
  final String partyState;
  final String partyGstin;
  final DateTime invoiceDate;
  final String paymentMode; // 'cash', 'credit', 'online', 'cheque'
  final double subtotal;
  final double discountAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double tcsRate;
  final double tcsAmount;
  final double tdsRate;
  final double tdsAmount;
  final double totalAmount;
  final double receivedAmount;
  final double balanceAmount;
  final double profitAmount;
  final String status; // 'paid', 'partial', 'unpaid'
  final String notes;
  final String ewayBillNumber;
  final String vehicleNumber;
  final String transporterName;
  final bool isDeleted; // Soft delete / Recycle bin
  final bool hideBranding; // Remove advertisement
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    this.firmId = 'default_firm',
    required this.invoiceNumber,
    this.partyId,
    required this.partyName,
    this.partyPhone = '',
    this.partyAddress = '',
    this.partyState = 'Tamil Nadu',
    this.partyGstin = '',
    required this.invoiceDate,
    this.paymentMode = 'cash',
    required this.subtotal,
    this.discountAmount = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.tcsRate = 0.0,
    this.tcsAmount = 0.0,
    this.tdsRate = 0.0,
    this.tdsAmount = 0.0,
    required this.totalAmount,
    required this.receivedAmount,
    required this.balanceAmount,
    this.profitAmount = 0.0,
    required this.status,
    this.notes = '',
    this.ewayBillNumber = '',
    this.vehicleNumber = '',
    this.transporterName = '',
    this.isDeleted = false,
    this.hideBranding = false,
    this.items = const [],
  });

  bool get isPaid => status == 'paid' || balanceAmount <= 0.0;
  bool get isPartial => status == 'partial';
  bool get isUnpaid => status == 'unpaid';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'invoiceNumber': invoiceNumber,
      'partyId': partyId,
      'partyName': partyName,
      'partyPhone': partyPhone,
      'partyAddress': partyAddress,
      'partyState': partyState,
      'partyGstin': partyGstin,
      'invoiceDate': invoiceDate.toIso8601String(),
      'paymentMode': paymentMode,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'tcsRate': tcsRate,
      'tcsAmount': tcsAmount,
      'tdsRate': tdsRate,
      'tdsAmount': tdsAmount,
      'totalAmount': totalAmount,
      'receivedAmount': receivedAmount,
      'balanceAmount': balanceAmount,
      'profitAmount': profitAmount,
      'status': status,
      'notes': notes,
      'ewayBillNumber': ewayBillNumber,
      'vehicleNumber': vehicleNumber,
      'transporterName': transporterName,
      'isDeleted': isDeleted ? 1 : 0,
      'hideBranding': hideBranding ? 1 : 0,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, [List<InvoiceItem> items = const []]) {
    return Invoice(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      invoiceNumber: map['invoiceNumber'] ?? '',
      partyId: map['partyId'],
      partyName: map['partyName'] ?? 'Cash Customer',
      partyPhone: map['partyPhone'] ?? '',
      partyAddress: map['partyAddress'] ?? '',
      partyState: map['partyState'] ?? 'Tamil Nadu',
      partyGstin: map['partyGstin'] ?? '',
      invoiceDate: map['invoiceDate'] != null ? DateTime.parse(map['invoiceDate']) : DateTime.now(),
      paymentMode: map['paymentMode'] ?? 'cash',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (map['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (map['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (map['igstAmount'] as num?)?.toDouble() ?? 0.0,
      tcsRate: (map['tcsRate'] as num?)?.toDouble() ?? 0.0,
      tcsAmount: (map['tcsAmount'] as num?)?.toDouble() ?? 0.0,
      tdsRate: (map['tdsRate'] as num?)?.toDouble() ?? 0.0,
      tdsAmount: (map['tdsAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      receivedAmount: (map['receivedAmount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      profitAmount: (map['profitAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'paid',
      notes: map['notes'] ?? '',
      ewayBillNumber: map['ewayBillNumber'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      transporterName: map['transporterName'] ?? '',
      isDeleted: (map['isDeleted'] ?? 0) == 1,
      hideBranding: (map['hideBranding'] ?? 0) == 1,
      items: items,
    );
  }

  Invoice copyWith({
    String? id,
    String? firmId,
    String? invoiceNumber,
    String? partyId,
    String? partyName,
    String? partyPhone,
    String? partyAddress,
    String? partyState,
    String? partyGstin,
    DateTime? invoiceDate,
    String? paymentMode,
    double? subtotal,
    double? discountAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? tcsRate,
    double? tcsAmount,
    double? tdsRate,
    double? tdsAmount,
    double? totalAmount,
    double? receivedAmount,
    double? balanceAmount,
    double? profitAmount,
    String? status,
    String? notes,
    String? ewayBillNumber,
    String? vehicleNumber,
    String? transporterName,
    bool? isDeleted,
    bool? hideBranding,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      partyPhone: partyPhone ?? this.partyPhone,
      partyAddress: partyAddress ?? this.partyAddress,
      partyState: partyState ?? this.partyState,
      partyGstin: partyGstin ?? this.partyGstin,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      paymentMode: paymentMode ?? this.paymentMode,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      tcsRate: tcsRate ?? this.tcsRate,
      tcsAmount: tcsAmount ?? this.tcsAmount,
      tdsRate: tdsRate ?? this.tdsRate,
      tdsAmount: tdsAmount ?? this.tdsAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      ewayBillNumber: ewayBillNumber ?? this.ewayBillNumber,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      transporterName: transporterName ?? this.transporterName,
      isDeleted: isDeleted ?? this.isDeleted,
      hideBranding: hideBranding ?? this.hideBranding,
      items: items ?? this.items,
    );
  }
}
