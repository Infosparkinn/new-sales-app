import 'package:flutter_test/flutter_test.dart';
import 'package:new_sales_app/models/invoice.dart';
import 'package:new_sales_app/models/item.dart';
import 'package:new_sales_app/models/party.dart';

void main() {
  group('Testing Sales App - Complete Billing & Accounting Workflow Tests', () {
    test('1. End-to-End Invoice Calculation with GST, TCS & TDS', () {
      final items = [
        InvoiceItem(
          id: 'item_1',
          invoiceId: 'inv_101',
          itemId: 'sku_sports_bat',
          itemName: 'SS Kashmir Willow Cricket Bat',
          quantity: 2.0,
          unit: 'PCS',
          unitPrice: 2500.0,
          purchasePrice: 1600.0,
          taxRate: 18.0,
          cgstAmount: 2500.0 * 2.0 * 0.09, // 450.0
          sgstAmount: 2500.0 * 2.0 * 0.09, // 450.0
          igstAmount: 0.0,
          totalAmount: (2500.0 * 2.0) * 1.18, // 5900.0
        ),
        InvoiceItem(
          id: 'item_2',
          invoiceId: 'inv_101',
          itemId: 'sku_cricket_ball',
          itemName: 'Leather Match Ball (Red)',
          quantity: 5.0,
          unit: 'PCS',
          unitPrice: 400.0,
          purchasePrice: 250.0,
          taxRate: 12.0,
          cgstAmount: 400.0 * 5.0 * 0.06, // 120.0
          sgstAmount: 400.0 * 5.0 * 0.06, // 120.0
          igstAmount: 0.0,
          totalAmount: (400.0 * 5.0) * 1.12, // 2240.0
        ),
      ];

      final subtotal = items.fold(0.0, (sum, i) => sum + (i.quantity * i.unitPrice)); // 5000 + 2000 = 7000
      final totalCgst = items.fold(0.0, (sum, i) => sum + i.cgstAmount); // 450 + 120 = 570
      final totalSgst = items.fold(0.0, (sum, i) => sum + i.sgstAmount); // 450 + 120 = 570
      final itemsTotal = items.fold(0.0, (sum, i) => sum + i.totalAmount); // 5900 + 2240 = 8140

      expect(subtotal, equals(7000.0));
      expect(totalCgst, equals(570.0));
      expect(totalSgst, equals(570.0));
      expect(itemsTotal, equals(8140.0));

      // With TCS 1% and TDS 0.1%
      const tcsRate = 1.0;
      const tdsRate = 0.1;
      final tcsAmount = subtotal * (tcsRate / 100.0); // 70.0
      final tdsAmount = subtotal * (tdsRate / 100.0); // 7.0
      final grandTotal = itemsTotal + tcsAmount - tdsAmount; // 8140 + 70 - 7 = 8203.0

      final invoice = Invoice(
        id: 'inv_101',
        invoiceNumber: 'INV-00101',
        partyName: 'Ramesh Sports Academy',
        partyPhone: '9876543210',
        invoiceDate: DateTime.now(),
        subtotal: subtotal,
        cgstAmount: totalCgst,
        sgstAmount: totalSgst,
        tcsRate: tcsRate,
        tcsAmount: tcsAmount,
        tdsRate: tdsRate,
        tdsAmount: tdsAmount,
        totalAmount: grandTotal,
        receivedAmount: 5000.0, // Partial cash received
        balanceAmount: grandTotal - 5000.0, // 3203.0 balance
        status: 'partial',
        items: items,
      );

      expect(invoice.isPartial, isTrue);
      expect(invoice.isPaid, isFalse);
      expect(invoice.balanceAmount, equals(3203.0));
      expect(invoice.items.length, equals(2));
      expect(invoice.profitAmount, equals(0.0)); // Uncalculated defaults to 0
    });

    test('2. Multiple Pricing Tiers Calculation (Retail vs Wholesale vs Dealer)', () {
      final item = Item(
        id: 'sku_101',
        name: 'Pro Badminton Racket',
        code: 'RKT-01',
        unit: 'PCS',
        salePrice: 1500.0, // Default Retail
        wholesalePrice: 1200.0, // Wholesale Tier (-20%)
        dealerPrice: 1050.0, // Dealer Tier (-30%)
        purchasePrice: 900.0,
        taxRate: 18.0,
      );

      double getPriceForParty(Party p) {
        if (p.priceTier == 'wholesale' && item.wholesalePrice > 0) {
          return item.wholesalePrice;
        } else if (p.priceTier == 'dealer' && item.dealerPrice > 0) {
          return item.dealerPrice;
        }
        return item.salePrice;
      }

      final retailCustomer = Party(id: 'c1', name: 'Walk-in Retail', priceTier: 'retail');
      final wholesaleCustomer = Party(id: 'c2', name: 'City Sports Club', priceTier: 'wholesale');
      final dealerCustomer = Party(id: 'c3', name: 'Sub-Distributor TN', priceTier: 'dealer');

      expect(getPriceForParty(retailCustomer), equals(1500.0));
      expect(getPriceForParty(wholesaleCustomer), equals(1200.0));
      expect(getPriceForParty(dealerCustomer), equals(1050.0));
    });

    test('3. Stock Deduction & Low Stock Alert Detection', () {
      final item = Item(
        id: 'sku_202',
        name: 'Football Pro Match Size 5',
        stockQuantity: 10.0,
        minStockAlert: 5.0,
        salePrice: 850.0,
      );

      expect(item.isLowStock, isFalse);

      // Simulate selling 7 footballs
      const soldQty = 7.0;
      final updatedItem = item.copyWith(stockQuantity: item.stockQuantity - soldQty);

      expect(updatedItem.stockQuantity, equals(3.0));
      expect(updatedItem.isLowStock, isTrue); // 3 <= 5 -> Low Stock Alert!
    });

    test('4. Credit Limit Warning Check', () {
      final customer = Party(
        id: 'c_limit',
        name: 'Priya Supermarket',
        currentBalance: 12000.0,
        creditLimit: 15000.0,
      );

      bool isLimitExceeded(double newBillBalance) {
        return (customer.currentBalance + newBillBalance) > customer.creditLimit;
      }

      // Sale of ₹2,000 on credit (Total = 14,000 <= 15,000) -> Allowed
      expect(isLimitExceeded(2000.0), isFalse);

      // Sale of ₹4,000 on credit (Total = 16,000 > 15,000) -> Alert Exceeded!
      expect(isLimitExceeded(4000.0), isTrue);
    });

    test('5. Profit Margin Calculation per Bill Item', () {
      final item = InvoiceItem(
        id: 'i1',
        invoiceId: 'inv1',
        itemId: 'it1',
        itemName: 'Knee Guard',
        quantity: 4.0,
        unitPrice: 250.0, // Total Sale = 1000
        purchasePrice: 150.0, // Total Cost = 600
        totalAmount: 1180.0,
      );

      final totalSale = item.quantity * item.unitPrice; // 1000.0
      final totalCost = item.quantity * item.purchasePrice; // 600.0
      final grossProfit = totalSale - totalCost; // 400.0
      final marginPercent = (grossProfit / totalSale) * 100; // 40.0%

      expect(grossProfit, equals(400.0));
      expect(marginPercent, equals(40.0));
    });
  });
}