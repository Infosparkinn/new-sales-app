import 'package:flutter_test/flutter_test.dart';
import 'package:new_sales_app/models/business_profile.dart';
import 'package:new_sales_app/models/invoice.dart';
import 'package:new_sales_app/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test PdfService.generateInvoicePdf', () async {
    final business = BusinessProfile(
      id: 'biz_1',
      name: 'Testing Sales Co',
      phone: '9876543210',
      email: 'sales@test.com',
      address: '123 Market Road',
      state: 'Tamil Nadu',
      gstin: '33AAAAA0000A1Z5',
      bankName: 'HDFC Bank',
      accountNumber: '1234567890',
      ifsc: 'HDFC0001234',
      upiId: 'test@upi',
      termsAndConditions: 'Goods once sold cannot be returned.',
    );

    final invoice = Invoice(
      id: 'inv_1',
      invoiceNumber: 'INV-001',
      partyName: 'Cash Customer',
      invoiceDate: DateTime.now(),
      subtotal: 308.47,
      cgstAmount: 27.76,
      sgstAmount: 27.76,
      totalAmount: 364.00,
      receivedAmount: 364.00,
      balanceAmount: 0.0,
      status: 'paid',
      items: [
        InvoiceItem(
          id: 'item_1',
          invoiceId: 'inv_1',
          itemId: 'prod_1',
          itemName: 'Organic Green Tea (250g)',
          quantity: 2.0,
          unit: 'Pcs',
          unitPrice: 154.24,
          purchasePrice: 100.0,
          taxRate: 18.0,
          cgstAmount: 27.76,
          sgstAmount: 27.76,
          totalAmount: 364.0,
        ),
      ],
    );

    try {
      final bytes = await PdfService.generateInvoicePdf(
        business: business,
        invoice: invoice,
      );
      print('PdfService generated ${bytes.length} bytes successfully!');
    } catch (e, stack) {
      print('PdfService error: $e');
      print(stack);
      rethrow;
    }
  });
}
