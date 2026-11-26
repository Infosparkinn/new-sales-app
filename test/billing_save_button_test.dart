import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:new_sales_app/providers/app_provider.dart';
import 'package:new_sales_app/screens/billing/add_sale_screen.dart';

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

  testWidgets('Test clicking Save & Preview Bill and Save & WhatsApp in AddSaleScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();
    await tester.runAsync(() async {
      await provider.loadAllData();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: AddSaleScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 'Add Items'
    final addItemFinder = find.text('Add Items');
    expect(addItemFinder, findsOneWidget);
    await tester.tap(addItemFinder);
    await tester.pumpAndSettle();

    // In modal, find 'Add to Bill' button
    final addToBillFinder = find.text('Add to Bill');
    expect(addToBillFinder, findsOneWidget);
    await tester.tap(addToBillFinder);
    await tester.pumpAndSettle();

    // Now find Save & Preview Bill button
    final saveButtonFinder = find.text('Save & Preview Bill');
    expect(saveButtonFinder, findsOneWidget);

    print('Tapping Save & Preview Bill...');
    await tester.runAsync(() async {
      await tester.tap(saveButtonFinder);
      await Future.delayed(const Duration(seconds: 1));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    print('Tap Save & Preview Bill completed successfully!');
  });

  testWidgets('Test clicking Save & WhatsApp in AddSaleScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();
    await tester.runAsync(() async {
      await provider.loadAllData();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: AddSaleScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 'Add Items'
    final addItemFinder = find.text('Add Items');
    expect(addItemFinder, findsOneWidget);
    await tester.tap(addItemFinder);
    await tester.pumpAndSettle();

    // In modal, find 'Add to Bill' button
    final addToBillFinder = find.text('Add to Bill');
    expect(addToBillFinder, findsOneWidget);
    await tester.tap(addToBillFinder);
    await tester.pumpAndSettle();

    // Now find Save & WhatsApp button
    final saveWhatsappFinder = find.text('Save & WhatsApp');
    expect(saveWhatsappFinder, findsOneWidget);

    print('Tapping Save & WhatsApp...');
    await tester.runAsync(() async {
      await tester.tap(saveWhatsappFinder);
      await Future.delayed(const Duration(seconds: 1));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    print('Tap Save & WhatsApp completed successfully!');
  });
}
