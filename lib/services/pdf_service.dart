import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/business_profile.dart';
import '../models/invoice.dart';

class PdfService {
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
  static final dateFormat = DateFormat('dd/MM/yyyy');

  /// Generate Vector PDF Invoice with E-Way Bill & Tax enhancements
  static Future<Uint8List> generateInvoicePdf({
    required BusinessProfile business,
    required Invoice invoice,
  }) async {
    final pdf = pw.Document();

    final isInterState = invoice.partyState.isNotEmpty && 
                         business.state.isNotEmpty && 
                         invoice.partyState.toLowerCase() != business.state.toLowerCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header (Business Details + INVOICE tag)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          business.name,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        if (business.address.isNotEmpty)
                          pw.Text(business.address, style: const pw.TextStyle(fontSize: 10)),
                        if (business.phone.isNotEmpty)
                          pw.Text('Phone: ${business.phone}', style: const pw.TextStyle(fontSize: 10)),
                        if (business.gstin.isNotEmpty)
                          pw.Text('GSTIN: ${business.gstin}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('State: ${business.state}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue800,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text('Date: ${dateFormat.format(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Payment Mode: ${invoice.paymentMode.toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                      if (invoice.ewayBillNumber.isNotEmpty)
                        pw.Text('E-Way Bill #: ${invoice.ewayBillNumber}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                      if (invoice.vehicleNumber.isNotEmpty)
                        pw.Text('Vehicle #: ${invoice.vehicleNumber}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // 2. Bill To (Customer Details)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.partyName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (invoice.partyPhone.isNotEmpty)
                          pw.Text('Mobile: ${invoice.partyPhone}', style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.partyAddress.isNotEmpty)
                          pw.Text('Address: ${invoice.partyAddress}', style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.partyGstin.isNotEmpty)
                          pw.Text('GSTIN: ${invoice.partyGstin}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Place of Supply: ${invoice.partyState}', style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.transporterName.isNotEmpty)
                          pw.Text('Transporter: ${invoice.transporterName}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      ],
                    ),
                    if (business.upiId.isNotEmpty)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: 'upi://pay?pa=${business.upiId}&pn=${Uri.encodeComponent(business.name)}&am=${invoice.totalAmount}&cu=INR',
                            width: 60,
                            height: 60,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text('Scan to Pay UPI', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 3. Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // S.No
                  1: const pw.FlexColumnWidth(3.5), // Description
                  2: const pw.FlexColumnWidth(1.2), // HSN
                  3: const pw.FlexColumnWidth(1.2), // Qty
                  4: const pw.FlexColumnWidth(1.5), // Rate
                  5: const pw.FlexColumnWidth(1.0), // GST %
                  6: const pw.FlexColumnWidth(1.8), // Amount
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      _tableHeader('#'),
                      _tableHeader('Item Description'),
                      _tableHeader('HSN'),
                      _tableHeader('Qty'),
                      _tableHeader('Rate'),
                      _tableHeader('GST %'),
                      _tableHeader('Total'),
                    ],
                  ),
                  // Table Rows
                  ...invoice.items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final it = entry.value;
                    final String itemDesc = it.batchNumber.isNotEmpty 
                        ? '${it.itemName} (Batch: ${it.batchNumber})'
                        : it.itemName;

                    return pw.TableRow(
                      children: [
                        _tableCell('$idx', align: pw.TextAlign.center),
                        _tableCell(itemDesc, bold: true),
                        _tableCell(it.hsnCode.isNotEmpty ? it.hsnCode : '-', align: pw.TextAlign.center),
                        _tableCell('${it.quantity.toStringAsFixed(1)} ${it.unit}', align: pw.TextAlign.center),
                        _tableCell(it.unitPrice.toStringAsFixed(2), align: pw.TextAlign.right),
                        _tableCell('${it.taxRate.toStringAsFixed(0)}%', align: pw.TextAlign.center),
                        _tableCell(it.totalAmount.toStringAsFixed(2), align: pw.TextAlign.right, bold: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),

              // 4. Calculations Summary & Bank Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bank Details & Terms
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (business.bankName.isNotEmpty) ...[
                          pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text('Bank: ${business.bankName}', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('A/C No: ${business.accountNumber}', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('IFSC: ${business.ifsc}', style: const pw.TextStyle(fontSize: 8)),
                          if (business.upiId.isNotEmpty)
                            pw.Text('UPI ID: ${business.upiId}', style: const pw.TextStyle(fontSize: 8)),
                          pw.SizedBox(height: 8),
                        ],
                        pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text(business.termsAndConditions, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Summary Breakdown
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        children: [
                          _summaryRow('Subtotal (Taxable):', currencyFormat.format(invoice.subtotal)),
                          if (invoice.discountAmount > 0)
                            _summaryRow('Discount:', '- ${currencyFormat.format(invoice.discountAmount)}'),
                          if (!isInterState) ...[
                            _summaryRow('CGST:', currencyFormat.format(invoice.cgstAmount)),
                            _summaryRow('SGST:', currencyFormat.format(invoice.sgstAmount)),
                          ] else ...[
                            _summaryRow('IGST:', currencyFormat.format(invoice.igstAmount)),
                          ],
                          if (invoice.tcsAmount > 0)
                            _summaryRow('TCS (${invoice.tcsRate}%):', '+ ${currencyFormat.format(invoice.tcsAmount)}'),
                          if (invoice.tdsAmount > 0)
                            _summaryRow('TDS (${invoice.tdsRate}%):', '- ${currencyFormat.format(invoice.tdsAmount)}'),
                          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                          _summaryRow('Total Amount:', currencyFormat.format(invoice.totalAmount), isBold: true, fontSize: 11),
                          pw.SizedBox(height: 4),
                          _summaryRow('Received:', currencyFormat.format(invoice.receivedAmount)),
                          _summaryRow(
                            'Balance Due:', 
                            currencyFormat.format(invoice.balanceAmount), 
                            isBold: true,
                            color: invoice.balanceAmount > 0 ? PdfColors.red800 : PdfColors.green800,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 5. Signature Footer & Branding
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    invoice.hideBranding ? '' : 'Generated with Vyapar App',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('For ${business.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 28),
                      pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate 80mm POS Thermal Slip Vector PDF
  static Future<Uint8List> generateThermalReceiptPdf({
    required BusinessProfile business,
    required Invoice invoice,
  }) async {
    final pdf = pw.Document();

    final upiUri = 'upi://pay?pa=${business.upiId.isNotEmpty ? business.upiId : 'merchant@upi'}&pn=${Uri.encodeComponent(business.name)}&am=${invoice.totalAmount.toStringAsFixed(2)}&cu=INR&tn=Invoice_${invoice.invoiceNumber}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              pw.Text(
                business.name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              if (business.address.isNotEmpty)
                pw.Text(business.address, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              if (business.phone.isNotEmpty)
                pw.Text('Tel: ${business.phone}', style: const pw.TextStyle(fontSize: 8)),
              if (business.gstin.isNotEmpty)
                pw.Text('GSTIN: ${business.gstin}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('------------------------------------------------', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('CASH MEMO / POS RECEIPT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('------------------------------------------------', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 2),

              // Invoice Info Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${dateFormat.format(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (invoice.partyName.isNotEmpty && invoice.partyName != 'Cash Customer') ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cust: ${invoice.partyName}', style: const pw.TextStyle(fontSize: 8)),
                    if (invoice.partyPhone.isNotEmpty)
                      pw.Text('Ph: ${invoice.partyPhone}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text('------------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // Items Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 5, child: pw.Text('ITEM', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Text('------------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // Items Rows
              ...invoice.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          item.itemName,
                          style: const pw.TextStyle(fontSize: 8),
                          maxLines: 1,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '${item.quantity.toInt()} ${item.unit}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.unitPrice.toStringAsFixed(0),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          item.totalAmount.toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Text('------------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // Total Calculation
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Items: ${invoice.items.length}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Subtotal: ${currencyFormat.format(invoice.subtotal)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (invoice.cgstAmount > 0 || invoice.sgstAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GST Tax Breakdown:', style: const pw.TextStyle(fontSize: 7.5)),
                    pw.Text('CGST+SGST: ${currencyFormat.format(invoice.cgstAmount + invoice.sgstAmount)}', style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
              pw.SizedBox(height: 3),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(width: 0.8),
                    bottom: pw.BorderSide(width: 0.8),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(currencyFormat.format(invoice.totalAmount), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paid Mode: ${invoice.paymentMode.toUpperCase()}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                    invoice.balanceAmount <= 0 ? 'STATUS: PAID' : 'DUE: ${currencyFormat.format(invoice.balanceAmount)}',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              // UPI QR Code on Slip
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: upiUri,
                width: 70,
                height: 70,
              ),
              pw.SizedBox(height: 2),
              pw.Text('Scan to Pay with UPI', style: const pw.TextStyle(fontSize: 7)),

              pw.SizedBox(height: 6),
              pw.Text('------------------------------------------------', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Thank you for shopping with us!', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('Goods once sold cannot be taken back.', style: const pw.TextStyle(fontSize: 6.5)),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<File?> savePdfToFile(Uint8List bytes, String filename) async {
    if (kIsWeb) return null;
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$filename');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('savePdfToFile error: $e');
      return null;
    }
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 9, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
