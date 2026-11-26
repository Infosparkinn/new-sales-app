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

    test('Inter-state invoice calculates full IGST and zero CGST/SGST', () {
      const quantity = 3.0;
      const unitPrice = 1000.0;
      const taxRate = 18.0;

      const baseAmount = quantity * unitPrice; // 3000.0
      const igst = baseAmount * (taxRate / 100.0); // 540.0

      final item = InvoiceItem(
        id: '2',
        invoiceId: 'inv-2',
        itemId: 'item-2',
        itemName: 'Inter-State Goods',
        quantity: quantity,
        unitPrice: unitPrice,
        taxRate: taxRate,
        cgstAmount: 0.0,
        sgstAmount: 0.0,
        igstAmount: igst,
        totalAmount: baseAmount + igst,
      );

      expect(item.totalAmount, 3540.0);
      expect(item.cgstAmount, 0.0);
      expect(item.sgstAmount, 0.0);
      expect(item.igstAmount, 540.0);
    });

    test('TCS and TDS adjustments calculate correctly on bill total', () {
      const subtotal = 10000.0;
      const tcsRate = 1.0; // +1% TCS = 100.0
      const tdsRate = 2.0; // -2% TDS = 200.0

      final tcsAmount = subtotal * (tcsRate / 100.0);
      final tdsAmount = subtotal * (tdsRate / 100.0);
      final grandTotal = subtotal + tcsAmount - tdsAmount;

      expect(tcsAmount, 100.0);
      expect(tdsAmount, 200.0);
      expect(grandTotal, 9900.0);
    });

    test('Party price tiers resolve correctly', () {
      const baseRetail = 500.0;
      const wholesaleDiscount = 0.15; // 15% off
      const dealerDiscount = 0.25; // 25% off

      final wholesalePrice = baseRetail * (1 - wholesaleDiscount);
      final dealerPrice = baseRetail * (1 - dealerDiscount);

      expect(wholesalePrice, 425.0);
      expect(dealerPrice, 375.0);
    });
  });
}
