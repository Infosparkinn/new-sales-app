class ServiceReminder {
  final String id;
  final String firmId;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status; // 'pending', 'completed'
  final String reminderFrequency; // 'one_time', 'monthly', 'quarterly', 'yearly'

  ServiceReminder({
    required this.id,
    required this.firmId,
    this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.title,
    this.description = '',
    required this.dueDate,
    this.status = 'pending',
    this.reminderFrequency = 'one_time',
  });

  bool get isPending => status == 'pending';
  bool get isOverdue => isPending && dueDate.isBefore(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firmId': firmId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'reminderFrequency': reminderFrequency,
    };
  }

  factory ServiceReminder.fromMap(Map<String, dynamic> map) {
    return ServiceReminder(
      id: map['id'] ?? '',
      firmId: map['firmId'] ?? 'default_firm',
      customerId: map['customerId'],
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      status: map['status'] ?? 'pending',
      reminderFrequency: map['reminderFrequency'] ?? 'one_time',
    );
  }

  ServiceReminder copyWith({
    String? id,
    String? firmId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? reminderFrequency,
  }) {
    return ServiceReminder(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
    );
  }
}
