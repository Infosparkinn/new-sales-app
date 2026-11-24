class Firm {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String state;
  final String gstin;
  final String upiId;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String termsAndConditions;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final bool isDefault;

  Firm({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.state = 'Tamil Nadu',
    this.gstin = '',
    this.upiId = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifsc = '',
    this.termsAndConditions = 'Thank you for doing business with us!',
    this.invoicePrefix = 'INV-',
    this.nextInvoiceNumber = 1,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'state': state,
      'gstin': gstin,
      'upiId': upiId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
      'termsAndConditions': termsAndConditions,
      'invoicePrefix': invoicePrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory Firm.fromMap(Map<String, dynamic> map) {
    return Firm(
      id: map['id'] ?? '',
      name: map['name'] ?? 'My Firm',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      state: map['state'] ?? 'Tamil Nadu',
      gstin: map['gstin'] ?? '',
      upiId: map['upiId'] ?? '',
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      ifsc: map['ifsc'] ?? '',
      termsAndConditions: map['termsAndConditions'] ?? 'Thank you for your business!',
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      nextInvoiceNumber: map['nextInvoiceNumber'] is int
          ? map['nextInvoiceNumber']
          : int.tryParse(map['nextInvoiceNumber']?.toString() ?? '1') ?? 1,
      isDefault: (map['isDefault'] ?? 0) == 1,
    );
  }

  Firm copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? state,
    String? gstin,
    String? upiId,
    String? bankName,
    String? accountNumber,
    String? ifsc,
    String? termsAndConditions,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    bool? isDefault,
  }) {
    return Firm(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      state: state ?? this.state,
      gstin: gstin ?? this.gstin,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
