import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:new_sales_app/models/party.dart';
import 'package:new_sales_app/providers/app_provider.dart';
import 'package:new_sales_app/screens/parties/party_detail_screen.dart';

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

  Widget buildTestableWidget(Widget child, AppProvider provider) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        title: 'Testing Sales App',
        home: child,
      ),
    );
  }

  testWidgets('PartyDetailScreen renders supplier actions and ledger records correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();
    await tester.runAsync(() async {
      await provider.loadAllData();
    });

    final supplier = Party(
      id: 'test_supplier_1',
      name: 'Murugan Wholesalers',
      partyType: 'supplier',
      phone: '9840987654',
      openingBalance: -12500.0,
      currentBalance: -12500.0,
      gstin: '33AAAFM5678B1Z2',
      address: '15 Gandhi Nagar, Madurai',
      state: 'Tamil Nadu',
    );

    await tester.runAsync(() async {
      await provider.saveParty(supplier);
    });

    await tester.pumpWidget(buildTestableWidget(PartyDetailScreen(party: supplier), provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify header and balance
    expect(find.text('Murugan Wholesalers'), findsWidgets);
    expect(find.text("YOU'LL PAY"), findsWidgets);

    // Verify supplier-specific buttons are present
    expect(find.text('Pay Out / Make Payment'), findsOneWidget);
    expect(find.text('+ Purchase Bill'), findsOneWidget);
    expect(find.text('WhatsApp Statement'), findsOneWidget);

    // Verify customer-specific buttons are NOT present
    expect(find.text('Receive Payment'), findsNothing);
    expect(find.text('+ Sale Bill'), findsNothing);
    expect(find.text('WhatsApp Reminder'), findsNothing);

    // Verify opening balance ledger item is shown
    expect(find.text('Opening / Brought Forward Balance'), findsOneWidget);
  });

  testWidgets('PartyDetailScreen renders customer actions correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();
    await tester.runAsync(() async {
      await provider.loadAllData();
    });

    final customer = Party(
      id: 'test_customer_1',
      name: 'Ramesh Stores',
      partyType: 'customer',
      phone: '9876543210',
      openingBalance: 4500.0,
      currentBalance: 4500.0,
    );

    await tester.runAsync(() async {
      await provider.saveParty(customer);
    });

    await tester.pumpWidget(buildTestableWidget(PartyDetailScreen(party: customer), provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify customer actions
    expect(find.text('Receive Payment'), findsOneWidget);
    expect(find.text('+ Sale Bill'), findsOneWidget);
    expect(find.text('WhatsApp Reminder'), findsOneWidget);

    // Verify supplier actions are NOT present
    expect(find.text('Pay Out / Make Payment'), findsNothing);
    expect(find.text('+ Purchase Bill'), findsNothing);
    expect(find.text('WhatsApp Statement'), findsNothing);
  });
}
