import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:new_sales_app/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('VyaparApp initial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VyaparApp());
    expect(find.byType(VyaparApp), findsOneWidget);
  });
}
