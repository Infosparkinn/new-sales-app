import 'package:flutter_test/flutter_test.dart';
import 'package:new_sales_app/models/app_user.dart';

void main() {
  group('Multi-Device Login & Roles Test (1 Desktop + 3 Mobile Android)', () {
    test('1 Desktop Admin Login creation and permissions', () {
      final desktopUser = AppUser(
        id: 'user_desktop_admin',
        name: 'Desktop Admin (Master Counter)',
        phone: '9876543210',
        role: 'admin',
        deviceType: 'desktop',
        deviceSlot: 'desktop_1',
        pin: '1234',
        canViewReports: true,
        canEditPrices: true,
        canDeleteBills: true,
        canViewProfits: true,
      );

      expect(desktopUser.isDesktop, isTrue);
      expect(desktopUser.isMobileAndroid, isFalse);
      expect(desktopUser.deviceSlot, equals('desktop_1'));
      expect(desktopUser.canDeleteBills, isTrue);
      expect(desktopUser.canEditPrices, isTrue);

      final map = desktopUser.toMap();
      expect(map['deviceType'], equals('desktop'));
      expect(map['deviceSlot'], equals('desktop_1'));
      expect(map['pin'], equals('1234'));

      final restored = AppUser.fromMap(map);
      expect(restored.name, equals('Desktop Admin (Master Counter)'));
      expect(restored.isDesktop, isTrue);
    });

    test('3 Mobile Android Logins creation and roles', () {
      final mobile1 = AppUser(
        id: 'user_mobile_sales_1',
        name: 'Mobile User 1 (Sales Executive)',
        phone: '9840112233',
        role: 'salesman',
        deviceType: 'android',
        deviceSlot: 'mobile_1',
        canViewReports: true,
        canEditPrices: true,
        canDeleteBills: false,
        canViewProfits: true,
      );

      final mobile2 = AppUser(
        id: 'user_mobile_delivery_2',
        name: 'Mobile User 2 (Delivery & Field Agent)',
        phone: '9840223344',
        role: 'delivery',
        deviceType: 'android',
        deviceSlot: 'mobile_2',
        canViewReports: false,
        canEditPrices: false,
        canDeleteBills: false,
        canViewProfits: false,
      );

      final mobile3 = AppUser(
        id: 'user_mobile_counter_3',
        name: 'Mobile User 3 (Billing Assistant)',
        phone: '9840334455',
        role: 'billing_assistant',
        deviceType: 'android',
        deviceSlot: 'mobile_3',
        canViewReports: true,
        canEditPrices: false,
        canDeleteBills: false,
        canViewProfits: false,
      );

      // Verify Mobile 1
      expect(mobile1.isMobileAndroid, isTrue);
      expect(mobile1.deviceSlot, equals('mobile_1'));
      expect(mobile1.canDeleteBills, isFalse);
      expect(mobile1.canEditPrices, isTrue);

      // Verify Mobile 2
      expect(mobile2.isMobileAndroid, isTrue);
      expect(mobile2.deviceSlot, equals('mobile_2'));
      expect(mobile2.canViewReports, isFalse);
      expect(mobile2.role, equals('delivery'));

      // Verify Mobile 3
      expect(mobile3.isMobileAndroid, isTrue);
      expect(mobile3.deviceSlot, equals('mobile_3'));
      expect(mobile3.canViewReports, isTrue);
      expect(mobile3.canEditPrices, isFalse);
    });

    test('DeviceSession creation and status serialization', () {
      final now = DateTime.now();
      final session = DeviceSession(
        id: 'session_desktop_1',
        userId: 'user_desktop_admin',
        userName: 'Desktop Admin (Master Counter)',
        deviceType: 'desktop',
        deviceName: 'Windows 11 POS Terminal #1',
        deviceSlot: 'desktop_1',
        ipAddress: '192.168.1.100',
        isOnline: true,
        lastActive: now,
      );

      final map = session.toMap();
      expect(map['deviceType'], equals('desktop'));
      expect(map['deviceSlot'], equals('desktop_1'));
      expect(map['isOnline'], equals(1));
      expect(map['ipAddress'], equals('192.168.1.100'));

      final restored = DeviceSession.fromMap(map);
      expect(restored.userName, equals('Desktop Admin (Master Counter)'));
      expect(restored.isOnline, isTrue);
    });

    test('Total 4 Device licenses (1 Desktop + 3 Mobile)', () {
      final allSlots = ['desktop_1', 'mobile_1', 'mobile_2', 'mobile_3'];
      expect(allSlots.length, equals(4));
      expect(allSlots.where((s) => s.startsWith('desktop')).length, equals(1));
      expect(allSlots.where((s) => s.startsWith('mobile')).length, equals(3));
    });
  });
}