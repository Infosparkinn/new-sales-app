import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:new_sales_app/providers/app_provider.dart';
import 'package:new_sales_app/screens/dashboard_screen.dart';
import 'package:new_sales_app/screens/auth/login_screen.dart';
import 'package:new_sales_app/screens/auth/device_management_screen.dart';
import 'package:new_sales_app/screens/billing/mobile_pos_screen.dart';

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

  group('UI Screens & Widgets Integration Tests', () {
    testWidgets('1. DashboardScreen renders metrics, actions and user badge', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      await tester.runAsync(() async {
        await provider.loadAllData();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          DashboardScreen(
            onNavigateToParties: () {},
            onNavigateToItems: () {},
          ),
          provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify AppBar exists with firm name or FY
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.textContaining('FY 2026-27'), findsOneWidget);

      // 2. Verify Multi-Device Profile Badge in AppBar
      expect(find.byIcon(Icons.devices_other), findsOneWidget);

      // 3. Verify Metric Cards: "YOU'LL GET" and "YOU'LL PAY"
      expect(find.text("YOU'LL GET"), findsOneWidget);
      expect(find.text("YOU'LL PAY"), findsOneWidget);

      // 4. Verify Quick Action Buttons
      expect(find.text('+ Sale Bill'), findsOneWidget);
      expect(find.text('+ Purchase'), findsOneWidget);
      expect(find.text('+ Payment In'), findsOneWidget);
      expect(find.text('Mobile POS'), findsOneWidget);
    });

    testWidgets('2. LoginScreen displays 1 Desktop and 3 Mobile Android logins', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      await tester.runAsync(() async {
        await provider.loadAllData();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const LoginScreen(isSwitchingUser: false),
          provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify Screen Header & Branding
      expect(find.text('Multi-Device Login'), findsOneWidget);
      expect(find.text('4 of 4 Device Licenses Allocated'), findsOneWidget);

      // 2. Verify 1 Desktop Login Section
      expect(find.textContaining('1 DESKTOP LOGIN'), findsOneWidget);
      expect(find.text('Desktop Admin (Master Counter)'), findsOneWidget);

      // 3. Verify 3 Mobile Android Logins Section
      expect(find.textContaining('3 MOBILE ANDROID LOGINS'), findsOneWidget);
      expect(find.text('Mobile User 1 (Sales Executive)'), findsOneWidget);
      expect(find.text('Mobile User 2 (Delivery & Field Agent)'), findsOneWidget);
      expect(find.text('Mobile User 3 (Billing Assistant)'), findsOneWidget);

      // 4. Verify Device Management icon in AppBar
      expect(find.byIcon(Icons.devices_other), findsOneWidget);
    });

    testWidgets('3. DeviceManagementScreen renders terminal cards and permissions matrix', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      await tester.runAsync(() async {
        await provider.loadAllData();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const DeviceManagementScreen(),
          provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify Title & Summary
      expect(find.text('Device & Session Manager'), findsOneWidget);
      expect(find.text('Multi-Device Enterprise License'), findsOneWidget);
      expect(find.textContaining('4/4 SLOTS ALLOCATED'), findsOneWidget);

      // 2. Verify Terminals
      expect(find.text('Windows 11 POS Terminal #1'), findsOneWidget);
      expect(find.text('Samsung Galaxy S23 (Android 14)'), findsOneWidget);
      expect(find.text('Xiaomi Redmi Note 13 (Android 14)'), findsOneWidget);
      expect(find.text('OnePlus Nord CE (Android 14)'), findsOneWidget);

      // 3. Verify Permissions Matrix Table
      expect(find.text('Device Role Permissions Matrix'), findsOneWidget);
      expect(find.text('Role / Device'), findsOneWidget);
      expect(find.text('View Reports'), findsWidgets);
    });

    testWidgets('4. MobilePosScreen renders category filter, search bar, and cart checkout', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      await tester.runAsync(() async {
        await provider.loadAllData();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const MobilePosScreen(),
          provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify Header
      expect(find.text('Mobile POS • Quick Counter Billing'), findsOneWidget);

      // 2. Verify Search Bar
      expect(find.byType(TextField), findsOneWidget);

      // 3. Verify Categories ('All')
      expect(find.text('All'), findsOneWidget);

      // 4. Verify Payment Mode Chips (Cash, Card, UPI, Credit)
      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('CARD'), findsOneWidget);
      expect(find.text('G PAY / UPI'), findsOneWidget);
      expect(find.text('CREDIT'), findsOneWidget);
    });
  });
}