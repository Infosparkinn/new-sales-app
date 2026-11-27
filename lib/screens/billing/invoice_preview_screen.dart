import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../providers/app_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../services/upi_service.dart';
import '../../widgets/upi_qr_dialog.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final business = provider.business;
    final invoice = widget.invoice;

    final upiUri = UpiService.generateUpiUri(
      upiId: business.upiId.isNotEmpty ? business.upiId : 'merchant@upi',
      payeeName: business.name,
      amount: invoice.totalAmount,
      transactionNote: 'Bill #${invoice.invoiceNumber}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #${invoice.invoiceNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${AppTheme.currency.format(invoice.totalAmount)} • ${invoice.partyName}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Show UPI QR Pay',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => UpiQrDialog(
                  upiId: business.upiId,
                  businessName: business.name,
                  amount: invoice.totalAmount,
                  invoiceNumber: invoice.invoiceNumber,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF4ADE80)),
            tooltip: 'Share on WhatsApp',
            onPressed: () {
              ShareService.shareInvoiceViaWhatsApp(
                business: business,
                invoice: invoice,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'TAX INVOICE (A4)'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'THERMAL SLIP (80MM)'),
            Tab(icon: Icon(Icons.qr_code_rounded, size: 18), text: 'INSTANT UPI QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Standard A4 Tax Invoice
          PdfPreview(
            build: (format) => PdfService.generateInvoicePdf(
              business: business,
              invoice: invoice,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          ),

          // 2. POS Thermal Slip (80mm)
          PdfPreview(
            build: (format) => PdfService.generateThermalReceiptPdf(
              business: business,
              invoice: invoice,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            initialPageFormat: PdfPageFormat.roll80,
          ),

          // 3. Instant UPI QR Payment View
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 16, color: AppTheme.successGreen),
                                const SizedBox(width: 6),
                                Text(
                                  business.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppTheme.currency.format(invoice.totalAmount),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Invoice #${invoice.invoiceNumber} • ${invoice.partyName}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),

                          // QR
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.border, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: upiUri,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Scan with PhonePe, Google Pay, Paytm, or BHIM',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share PDF on WhatsApp'),
                onPressed: () {
                  ShareService.shareInvoiceViaWhatsApp(
                    business: business,
                    invoice: invoice,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('UPI QR'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => UpiQrDialog(
                    upiId: business.upiId,
                    businessName: business.name,
                    amount: invoice.totalAmount,
                    invoiceNumber: invoice.invoiceNumber,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
