class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role; // 'admin', 'salesman', 'delivery', 'billing_assistant'
  final String deviceType; // 'desktop', 'android'
  final String deviceSlot; // 'desktop_1', 'mobile_1', 'mobile_2', 'mobile_3'
  final String pin;
  final bool isActive;
  final DateTime? lastLoginAt;
  final bool canViewReports;
  final bool canEditPrices;
  final bool canDeleteBills;
  final bool canViewProfits;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.deviceType,
    required this.deviceSlot,
    this.pin = '1234',
    this.isActive = true,
    this.lastLoginAt,
    this.canViewReports = true,
    this.canEditPrices = true,
    this.canDeleteBills = false,
    this.canViewProfits = true,
  });

  bool get isDesktop => deviceType == 'desktop';
  bool get isMobileAndroid => deviceType == 'android';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'deviceType': deviceType,
      'deviceSlot': deviceSlot,
      'pin': pin,
      'isActive': isActive ? 1 : 0,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'canViewReports': canViewReports ? 1 : 0,
      'canEditPrices': canEditPrices ? 1 : 0,
      'canDeleteBills': canDeleteBills ? 1 : 0,
      'canViewProfits': canViewProfits ? 1 : 0,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'salesman',
      deviceType: map['deviceType'] ?? 'android',
      deviceSlot: map['deviceSlot'] ?? 'mobile_1',
      pin: map['pin'] ?? '1234',
      isActive: (map['isActive'] ?? 1) == 1,
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.tryParse(map['lastLoginAt']) : null,
      canViewReports: (map['canViewReports'] ?? 1) == 1,
      canEditPrices: (map['canEditPrices'] ?? 1) == 1,
      canDeleteBills: (map['canDeleteBills'] ?? 0) == 1,
      canViewProfits: (map['canViewProfits'] ?? 1) == 1,
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? deviceType,
    String? deviceSlot,
    String? pin,
    bool? isActive,
    DateTime? lastLoginAt,
    bool? canViewReports,
    bool? canEditPrices,
    bool? canDeleteBills,
    bool? canViewProfits,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      deviceType: deviceType ?? this.deviceType,
      deviceSlot: deviceSlot ?? this.deviceSlot,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      canViewReports: canViewReports ?? this.canViewReports,
      canEditPrices: canEditPrices ?? this.canEditPrices,
      canDeleteBills: canDeleteBills ?? this.canDeleteBills,
      canViewProfits: canViewProfits ?? this.canViewProfits,
    );
  }
}

class DeviceSession {
  final String id;
  final String userId;
  final String userName;
  final String deviceType; // 'desktop', 'android'
  final String deviceName;
  final String deviceSlot; // 'desktop_1', 'mobile_1', 'mobile_2', 'mobile_3'
  final String ipAddress;
  final bool isOnline;
  final DateTime lastActive;

  DeviceSession({
    required this.id,
    required this.userId,
    required this.userName,
    required this.deviceType,
    required this.deviceName,
    required this.deviceSlot,
    this.ipAddress = '192.168.1.100',
    this.isOnline = true,
    required this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'deviceSlot': deviceSlot,
      'ipAddress': ipAddress,
      'isOnline': isOnline ? 1 : 0,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory DeviceSession.fromMap(Map<String, dynamic> map) {
    return DeviceSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      deviceType: map['deviceType'] ?? 'android',
      deviceName: map['deviceName'] ?? '',
      deviceSlot: map['deviceSlot'] ?? 'mobile_1',
      ipAddress: map['ipAddress'] ?? '192.168.1.100',
      isOnline: (map['isOnline'] ?? 1) == 1,
      lastActive: DateTime.tryParse(map['lastActive'] ?? '') ?? DateTime.now(),
    );
  }
}
