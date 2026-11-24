import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../providers/app_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final business = provider.business;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.greenAccent),
            tooltip: 'Share on WhatsApp',
            onPressed: () {
              ShareService.shareInvoiceViaWhatsApp(
                business: business,
                invoice: invoice,
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateInvoicePdf(
          business: business,
          invoice: invoice,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
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
          ],
        ),
      ),
    );
  }
}
