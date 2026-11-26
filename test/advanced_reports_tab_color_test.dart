import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:new_sales_app/core/theme.dart';
import 'package:new_sales_app/providers/app_provider.dart';
import 'package:new_sales_app/screens/reports/advanced_reports_screen.dart';

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

  testWidgets('Verify TabBar color contrast in AdvancedReportsScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();
    await tester.runAsync(() async {
      await provider.loadAllData();
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdvancedReportsScreen(),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1000));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify TabBar exists
    final tabBarFinder = find.byType(TabBar);
    expect(tabBarFinder, findsOneWidget);

    final TabBar tabBar = tester.widget<TabBar>(tabBarFinder);
    expect(tabBar.labelColor, equals(Colors.white));
    expect(tabBar.unselectedLabelColor, equals(Colors.white70));
    expect(tabBar.indicatorColor, equals(Colors.white));

    // Verify all 4 tabs exist and are readable
    expect(find.text('BALANCE SHEET'), findsOneWidget);
    expect(find.text('BILLWISE PROFIT'), findsOneWidget);
    expect(find.text('PARTYWISE PROFIT'), findsOneWidget);
    expect(find.text('BATCH & SERIAL'), findsOneWidget);
  });
}
