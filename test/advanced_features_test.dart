import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_sales_app/models/business_profile.dart';
import 'package:new_sales_app/models/invoice.dart';
import 'package:new_sales_app/providers/app_provider.dart';
import 'package:new_sales_app/services/pdf_service.dart';
import 'package:new_sales_app/services/upi_service.dart';
import 'package:new_sales_app/widgets/keyboard_shortcuts_dialog.dart';
import 'package:new_sales_app/widgets/sales_trend_chart_widget.dart';
import 'package:new_sales_app/widgets/upi_qr_dialog.dart';
import 'package:provider/provider.dart';

Widget buildTestableWidget(Widget child, [AppProvider? provider]) {
  final p = provider ?? AppProvider();
  return ChangeNotifierProvider<AppProvider>.value(
    value: p,
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Advanced Features & Design Tests', () {
    test('1. UpiService generates compliant NPCI UPI URI string', () {
      final uri = UpiService.generateUpiUri(
        upiId: 'sivan@okaxis',
        payeeName: 'Sivan Sports Pro',
        amount: 1450.50,
        transactionNote: 'Bill #INV-0042',
      );

      expect(uri, contains('upi://pay?'));
      expect(uri, contains('pa=sivan@okaxis'));
      expect(uri, contains('am=1450.50'));
      expect(uri, contains('cu=INR'));
      expect(uri, contains('pn=Sivan%20Sports%20Pro'));
      expect(uri, contains('tn=Bill%20%23INV-0042'));
    });

    testWidgets('2. SalesTrendChartWidget renders 7-day revenue analytics', (WidgetTester tester) async {
      final List<Invoice> invoices = [
        Invoice(
          id: 'inv_1',
          firmId: 'default_firm',
          partyName: 'Test Customer',
          invoiceNumber: 'INV-101',
          invoiceDate: DateTime.now(),
          subtotal: 1000,
          cgstAmount: 90,
          sgstAmount: 90,
          totalAmount: 1180,
          receivedAmount: 1180,
          balanceAmount: 0,
          status: 'paid',
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(SalesTrendChartWidget(invoices: invoices)));
      await tester.pump();

      expect(find.text('Weekly Sales Trend'), findsOneWidget);
      expect(find.text('Last 7 Days Revenue Analytics'), findsOneWidget);
      expect(find.text('Today Highlighted'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('3. UpiQrDialog renders QR code, amount, and payment apps strip', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const UpiQrDialog(
            upiId: 'sivan@okaxis',
            businessName: 'Sivan Sports Pro',
            amount: 2500.0,
            invoiceNumber: 'INV-888',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Scan & Pay via UPI'), findsOneWidget);
      expect(find.text('Sivan Sports Pro'), findsOneWidget);
      expect(find.text('Invoice: #INV-888'), findsOneWidget);
      expect(find.text('GPay'), findsOneWidget);
      expect(find.text('PhonePe'), findsOneWidget);
      expect(find.text('Paytm'), findsOneWidget);
      expect(find.text('Payment Received / Confirm'), findsOneWidget);
    });

    testWidgets('4. KeyboardShortcutsDialog renders fast-keys reference cheat-sheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const KeyboardShortcutsDialog()));
      await tester.pump();

      expect(find.text('Desktop POS Fast-Keys'), findsOneWidget);
      expect(find.text('Enterprise Keyboard Shortcuts'), findsOneWidget);
      expect(find.text('F1 or Ctrl+N'), findsOneWidget);
      expect(find.text('F2 or Ctrl+P'), findsOneWidget);
      expect(find.text('F3 or Ctrl+I'), findsOneWidget);
      expect(find.text('F9 or Ctrl+C'), findsOneWidget);
    });

    test('5. PdfService.generateThermalReceiptPdf generates 80mm roll vector PDF bytes', () async {
      final business = BusinessProfile(
        id: 'biz_1',
        name: 'Sivan Sports Pro',
        phone: '9840123456',
        gstin: '33AAAAA0000A1Z5',
        state: 'Tamil Nadu',
        upiId: 'sivan@okaxis',
      );

      final invoice = Invoice(
        id: 'test_thermal',
        firmId: 'default_firm',
        partyName: 'Counter Customer',
        invoiceNumber: 'POS-001',
        invoiceDate: DateTime.now(),
        subtotal: 500,
        cgstAmount: 25,
        sgstAmount: 25,
        totalAmount: 550,
        receivedAmount: 550,
        balanceAmount: 0,
        status: 'paid',
        paymentMode: 'cash',
        items: [
          InvoiceItem(
            id: 'it_1',
            invoiceId: 'test_thermal',
            itemId: 'item_bat',
            itemName: 'Cricket Bat Pro',
            quantity: 1,
            unit: 'PCS',
            unitPrice: 500,
            purchasePrice: 350,
            taxRate: 10,
            cgstAmount: 25,
            sgstAmount: 25,
            totalAmount: 550,
          ),
        ],
      );

      final bytes = await PdfService.generateThermalReceiptPdf(
        business: business,
        invoice: invoice,
      );

      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
