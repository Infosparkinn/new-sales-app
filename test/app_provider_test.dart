import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:new_sales_app/providers/app_provider.dart';
import 'package:new_sales_app/models/firm.dart';
import 'package:new_sales_app/models/party.dart';
import 'package:new_sales_app/models/item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppProvider State Management Tests', () {
    test('1. AppProvider loads initial business state, firms, parties, and metrics', () async {
      final provider = AppProvider();
      await provider.loadAllData();

      expect(provider.isLoading, isFalse);
      expect(provider.firms, isNotEmpty);
      expect(provider.activeFirm.name, isNotEmpty);
      expect(provider.parties, isNotEmpty);
      expect(provider.items, isNotEmpty);
      expect(provider.cashBankAccounts, isNotEmpty);
      expect(provider.appUsers.length, equals(4));
      expect(provider.deviceSessions.length, equals(4));

      // Metrics map
      expect(provider.metrics.containsKey('totalReceivables'), isTrue);
      expect(provider.metrics.containsKey('totalPayables'), isTrue);
      expect(provider.metrics.containsKey('todaySale'), isTrue);
      expect(provider.metrics.containsKey('totalStockValue'), isTrue);
    });

    test('2. Multi-Firm management: add new firm and switch active firm', () async {
      final provider = AppProvider();
      await provider.loadAllData();

      final newFirm = Firm(
        id: 'branch_bangalore_firm',
        name: 'Testing Sales Bangalore Branch',
        phone: '9840998877',
        state: 'Karnataka',
        gstin: '29AABCS1429B1Z8',
      );

      await provider.saveFirm(newFirm);
      expect(provider.firms.any((f) => f.id == 'branch_bangalore_firm'), isTrue);

      // Switch active firm to Bangalore Branch
      await provider.switchFirm('branch_bangalore_firm');
      expect(provider.activeFirm.id, equals('branch_bangalore_firm'));
      expect(provider.activeFirm.name, equals('Testing Sales Bangalore Branch'));

      // Switch back to default firm
      await provider.switchFirm('default_firm');
      expect(provider.activeFirm.id, equals('default_firm'));
    });

    test('3. Multi-Device Authentication flow through provider', () async {
      final provider = AppProvider();
      await provider.loadAllData();

      // 1. Initial user pre-selected
      expect(provider.currentUser, isNotNull);

      // 2. Login as Mobile User 1 (Sales Executive) with PIN 1234
      final loginSuccess = await provider.loginUser('mobile_1', '1234');
      expect(loginSuccess, isTrue);
      expect(provider.currentUser?.deviceSlot, equals('mobile_1'));
      expect(provider.currentUser?.role, equals('salesman'));

      // 3. Login with invalid PIN fails
      final wrongPin = await provider.loginUser('mobile_1', '0000');
      expect(wrongPin, isFalse);

      // 4. Login as Desktop Admin
      final adminLogin = await provider.loginUser('desktop_1', '1234');
      expect(adminLogin, isTrue);
      expect(provider.currentUser?.isDesktop, isTrue);
      expect(provider.currentUser?.role, equals('admin'));

      // 5. Update PIN
      final pinUpdated = await provider.updatePin(provider.currentUser!.id, '1234', '9876');
      expect(pinUpdated, isTrue);
      expect(provider.currentUser?.pin, equals('9876'));

      // Reset PIN back to 1234
      await provider.updatePin(provider.currentUser!.id, '9876', '1234');
    });

    test('4. Party and Item CRUD with automated metrics recalculation', () async {
      final provider = AppProvider();
      await provider.loadAllData();

      final initialPartyCount = provider.parties.length;

      // Add new customer
      final newCustomer = Party(
        id: 'cust_auto_test_1',
        name: 'Auto Test Retailer',
        phone: '9988776655',
        partyType: 'customer',
        currentBalance: 5000.0,
      );
      await provider.saveParty(newCustomer);

      expect(provider.parties.length, equals(initialPartyCount + 1));
      expect(provider.parties.any((p) => p.id == 'cust_auto_test_1'), isTrue);

      // Delete the test party
      await provider.deleteParty('cust_auto_test_1');
      expect(provider.parties.length, equals(initialPartyCount));

      // Add new item and verify stock value update
      final initialItemsCount = provider.items.length;
      final newItem = Item(
        id: 'item_auto_test_1',
        name: 'Auto Test Cricket Pads',
        salePrice: 1500.0,
        stockQuantity: 10.0,
      );
      await provider.saveItem(newItem);

      expect(provider.items.length, equals(initialItemsCount + 1));

      // Clean up test item
      await provider.deleteItem('item_auto_test_1');
      expect(provider.items.length, equals(initialItemsCount));
    });
  });
}