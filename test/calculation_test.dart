import 'package:flutter_test/flutter_test.dart';
import 'package:new_sales_app/models/invoice.dart';

void main() {
  group('GST Tax & Invoice Engine Tests', () {
    test('Intra-state invoice calculates equal CGST and SGST', () {
      const quantity = 2.0;
      const unitPrice = 500.0;
      const taxRate = 18.0;

      const baseAmount = quantity * unitPrice; // 1000.0
      const taxAmount = baseAmount * (taxRate / 100.0); // 180.0
      const cgst = taxAmount / 2.0; // 90.0
      const sgst = taxAmount / 2.0; // 90.0

      final item = InvoiceItem(
        id: '1',
        invoiceId: 'inv-1',
        itemId: 'item-1',
        itemName: 'Test Product',
        quantity: quantity,
        unitPrice: unitPrice,
        taxRate: taxRate,
        cgstAmount: cgst,
        sgstAmount: sgst,
        igstAmount: 0.0,
        totalAmount: baseAmount + taxAmount,
      );

      expect(item.totalAmount, 1180.0);
      expect(item.cgstAmount, 90.0);
      expect(item.sgstAmount, 90.0);
      expect(item.igstAmount, 0.0);
    });

    test('Invoice status resolves correctly based on received amount', () {
      final invoicePaid = Invoice(
        id: '1',
        invoiceNumber: 'INV-001',
        partyName: 'Ramesh',
        invoiceDate: DateTime.now(),
        subtotal: 1000.0,
        totalAmount: 1180.0,
        receivedAmount: 1180.0,
        balanceAmount: 0.0,
        status: 'paid',
      );

      final invoicePartial = Invoice(
        id: '2',
        invoiceNumber: 'INV-002',
        partyName: 'Suresh',
        invoiceDate: DateTime.now(),
        subtotal: 1000.0,
        totalAmount: 1180.0,
        receivedAmount: 500.0,
        balanceAmount: 680.0,
        status: 'partial',
      );

      expect(invoicePaid.isPaid, true);
      expect(invoicePaid.isPartial, false);
      expect(invoicePartial.isPaid, false);
      expect(invoicePartial.isPartial, true);
      expect(invoicePartial.balanceAmount, 680.0);
    });
  });
}
