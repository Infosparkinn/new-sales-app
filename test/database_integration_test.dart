import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:new_sales_app/services/database_service.dart';
import 'package:new_sales_app/models/invoice.dart';
import 'package:new_sales_app/models/item.dart';
import 'package:new_sales_app/models/party.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService dbService;

  setUpAll(() async {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbService = DatabaseService.instance;
  });

  group('DatabaseService Integration Tests', () {
    test('1. Database initializes with all tables and default seed data', () async {
      final db = await dbService.database;
      expect(db.isOpen, isTrue);

      // Verify firms
      final firms = await dbService.getFirms();
      expect(firms, isNotEmpty);
      expect(firms.first.id, equals('default_firm'));

      // Verify active firm
      final activeFirm = await dbService.getActiveFirm();
      expect(activeFirm.id, equals('default_firm'));

      // Verify parties
      final parties = await dbService.getParties();
      expect(parties, isNotEmpty);
      expect(parties.any((p) => p.isCustomer), isTrue);
      expect(parties.any((p) => p.isSupplier), isTrue);

      // Verify items
      final items = await dbService.getItems();
      expect(items, isNotEmpty);

      // Verify Cash & Bank accounts (Cash in hand, Bank, GPay, Credit card)
      final cashBankAccounts = await dbService.getCashBankAccounts();
      expect(cashBankAccounts.length, greaterThanOrEqualTo(4));

      // Verify Multi-Device App Users (1 Desktop + 3 Mobile)
      final users = await dbService.getAppUsers();
      expect(users.length, equals(4));
      expect(users.where((u) => u.deviceType == 'desktop').length, equals(1));
      expect(users.where((u) => u.deviceType == 'android').length, equals(3));

      // Verify Device Sessions
      final sessions = await dbService.getDeviceSessions();
      expect(sessions.length, equals(4));

      // Verify Sync Company
      final syncInfo = await dbService.getSyncCompanyInfo();
      expect(syncInfo['companyName'], equals('Sivan sports pro'));
    });

    test('2. createInvoice updates stock, customer balance, and records transaction', () async {
      // Create a test item with known stock
      final testItem = Item(
        id: 'test_item_cricket_bat',
        name: 'SG Match Cricket Bat',
        code: 'BAT-SG-01',
        stockQuantity: 20.0,
        salePrice: 1200.0,
        purchasePrice: 800.0,
        taxRate: 18.0,
        unit: 'PCS',
      );
      await dbService.saveItem(testItem);

      // Create a test customer with 0 balance
      final testCustomer = Party(
        id: 'test_cust_sharma',
        name: 'Sharma Sports Club',
        phone: '9840112233',
        partyType: 'customer',
        currentBalance: 0.0,
        creditLimit: 25000.0,
      );
      await dbService.saveParty(testCustomer);

      // Next invoice number
      final nextInvNum = await dbService.getNextInvoiceNumber();
      expect(nextInvNum, isNotEmpty);

      // Build sale of 5 bats (Total = 6000 + 1080 tax = 7080)
      const qtySold = 5.0;
      final invoiceItem = InvoiceItem(
        id: 'test_inv_item_1',
        invoiceId: 'test_inv_001',
        itemId: testItem.id,
        itemName: testItem.name,
        quantity: qtySold,
        unitPrice: testItem.salePrice,
        purchasePrice: testItem.purchasePrice,
        taxRate: testItem.taxRate,
        cgstAmount: 540.0,
        sgstAmount: 540.0,
        igstAmount: 0.0,
        totalAmount: 7080.0,
      );

      final invoice = Invoice(
        id: 'test_inv_001',
        firmId: 'default_firm',
        invoiceNumber: nextInvNum,
        partyId: testCustomer.id,
        partyName: testCustomer.name,
        partyPhone: testCustomer.phone,
        invoiceDate: DateTime.now(),
        paymentMode: 'credit', // Credit sale -> increases customer balance
        subtotal: 6000.0,
        cgstAmount: 540.0,
        sgstAmount: 540.0,
        totalAmount: 7080.0,
        receivedAmount: 0.0,
        balanceAmount: 7080.0,
        profitAmount: (1200.0 - 800.0) * qtySold, // 2000 profit
        status: 'unpaid',
        items: [invoiceItem],
      );

      // Execute invoice creation
      await dbService.createInvoice(invoice);

      // 1. Verify item stock decreased by 5 (20 - 5 = 15)
      final itemsAfter = await dbService.getItems();
      final itemAfter = itemsAfter.firstWhere((i) => i.id == testItem.id);
      expect(itemAfter.stockQuantity, equals(15.0));

      // 2. Verify customer balance increased by 7080
      final partiesAfter = await dbService.getParties();
      final partyAfter = partiesAfter.firstWhere((p) => p.id == testCustomer.id);
      expect(partyAfter.currentBalance, equals(7080.0));

      // 3. Verify transaction was recorded
      final txns = await dbService.getTransactions();
      expect(txns.any((t) => t.referenceId == nextInvNum), isTrue);

      // 4. Verify invoice is retrievable
      final invoices = await dbService.getInvoices();
      expect(invoices.any((i) => i.id == invoice.id), isTrue);
    });

    test('3. Soft-delete and restore invoice functionality', () async {
      final invoicesBefore = await dbService.getInvoices();
      final activeCount = invoicesBefore.length;

      // Soft delete invoice
      await dbService.softDeleteInvoice('test_inv_001');

      final invoicesAfterDelete = await dbService.getInvoices();
      expect(invoicesAfterDelete.length, equals(activeCount - 1));

      final deletedInvoices = await dbService.getDeletedInvoices();
      expect(deletedInvoices.any((i) => i.id == 'test_inv_001'), isTrue);

      // Restore invoice
      await dbService.restoreInvoice('test_inv_001');

      final invoicesAfterRestore = await dbService.getInvoices();
      expect(invoicesAfterRestore.length, equals(activeCount));
    });

    test('4. Multi-Device Authentication & PIN Verification', () async {
      // 1. Desktop Admin login with default PIN (1234)
      final desktopUser = await dbService.authenticateUser('desktop_1', '1234');
      expect(desktopUser, isNotNull);
      expect(desktopUser!.isDesktop, isTrue);
      expect(desktopUser.role, equals('admin'));
      expect(desktopUser.canDeleteBills, isTrue);

      // 2. Wrong PIN returns null
      final failedLogin = await dbService.authenticateUser('desktop_1', '9999');
      expect(failedLogin, isNull);

      // 3. Mobile Android Login 1 (Sales Executive)
      final mobile1 = await dbService.authenticateUser('mobile_1', '1234');
      expect(mobile1, isNotNull);
      expect(mobile1!.isMobileAndroid, isTrue);
      expect(mobile1.role, equals('salesman'));
      expect(mobile1.canDeleteBills, isFalse);

      // 4. Mobile Android Login 2 (Delivery Agent)
      final mobile2 = await dbService.authenticateUser('mobile_2', '1234');
      expect(mobile2, isNotNull);
      expect(mobile2!.role, equals('delivery'));

      // 5. Update PIN and verify new PIN authentication
      await dbService.updateAppUserPin(desktopUser.id, '4321');
      final relogWithOldPin = await dbService.authenticateUser('desktop_1', '1234');
      expect(relogWithOldPin, isNull);

      final relogWithNewPin = await dbService.authenticateUser('desktop_1', '4321');
      expect(relogWithNewPin, isNotNull);

      // Reset back to 1234
      await dbService.updateAppUserPin(desktopUser.id, '1234');
    });

    test('5. Advanced Financial Reports Generation', () async {
      // 1. Balance Sheet: Assets == Liabilities + Equity
      final balanceSheet = await dbService.getBalanceSheetData();
      expect(balanceSheet.containsKey('totalAssets'), isTrue);
      expect(balanceSheet.containsKey('totalLiabilities'), isTrue);
      expect(balanceSheet.containsKey('equity'), isTrue);

      final totalAssets = balanceSheet['totalAssets'] as double;
      final totalLiabilities = balanceSheet['totalLiabilities'] as double;
      final equity = balanceSheet['equity'] as double;

      // Accounting equation: Assets = Liabilities + Equity
      expect(totalAssets, closeTo(totalLiabilities + equity, 0.01));

      // 2. Bill-wise Profit Report
      final profitReport = await dbService.getBillwiseProfitReport();
      expect(profitReport, isNotNull);

      // 3. GSTR-1 Report
      final gstr1 = await dbService.getGstr1Report();
      expect(gstr1.containsKey('b2bInvoicesCount'), isTrue);
      expect(gstr1.containsKey('b2cInvoicesCount'), isTrue);

      // 4. Day Book
      final dayBook = await dbService.getDayBook(DateTime.now());
      expect(dayBook, isNotNull);

      // 5. Data Integrity Verification Utility
      final integrity = await dbService.verifyDataIntegrity();
      expect(integrity['status'], equals('Healthy & Verified'));
    });
  });
}