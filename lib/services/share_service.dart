import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/business_profile.dart';
import '../models/firm.dart';
import '../models/invoice.dart';
import 'pdf_service.dart';

class ShareService {
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

  /// Share PDF invoice to WhatsApp / Email / etc. using Android / Windows / Web Share Sheet (100% Free)
  static Future<void> shareInvoiceViaWhatsApp({
    required BusinessProfile business,
    required Invoice invoice,
  }) async {
    final cleanInvNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename = 'Invoice_$cleanInvNum.pdf';

    final text = 'Dear ${invoice.partyName},\n\n'
        'Please find Tax Invoice *${invoice.invoiceNumber}* for *${currencyFormat.format(invoice.totalAmount)}* from *${business.name}*.\n\n'
        '${invoice.balanceAmount > 0 ? "Pending Balance Due: ${currencyFormat.format(invoice.balanceAmount)}\n" : "Status: Fully Paid [✓]\n"}'
        '${invoice.ewayBillNumber.isNotEmpty ? "E-Way Bill No: ${invoice.ewayBillNumber}\n" : ""}'
        '${business.upiId.isNotEmpty ? "Pay via UPI: ${business.upiId}\n" : ""}\n'
        'Thank you for your business!';

    // 1. Try launching WhatsApp directly with pre-filled message & details
    try {
      final cleanPhone = invoice.partyPhone.replaceAll(RegExp(r'[^0-9]'), '');
      String whatsappUrl;
      if (cleanPhone.isNotEmpty) {
        final phoneWithCountry = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
        whatsappUrl = 'https://wa.me/$phoneWithCountry?text=${Uri.encodeComponent(text)}';
      } else {
        whatsappUrl = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
      }
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp direct launch info: $e');
    }

    // 2. Generate PDF and invoke cross-platform sharing
    try {
      final pdfBytes = await PdfService.generateInvoicePdf(
        business: business,
        invoice: invoice,
      );

      // Printing.sharePdf natively works on Web (download/preview), Android, Windows & macOS
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
        subject: 'Invoice ${invoice.invoiceNumber} from ${business.name}',
      );
    } catch (e) {
      debugPrint('Printing.sharePdf fallback: $e');
      try {
        final pdfBytes = await PdfService.generateInvoicePdf(
          business: business,
          invoice: invoice,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                pdfBytes,
                name: filename,
                mimeType: 'application/pdf',
              ),
            ],
            text: text,
            subject: 'Invoice ${invoice.invoiceNumber} from ${business.name}',
          ),
        );
      } catch (err) {
        debugPrint('SharePlus fallback error: $err');
      }
    }
  }

  /// Share Ledger / Khata Reminder
  static Future<void> sharePartyReminder({
    required BusinessProfile business,
    required String partyName,
    required double balanceAmount,
    String? partyPhone,
  }) async {
    final text = 'Dear $partyName,\n\n'
        'This is a gentle reminder regarding your outstanding balance of *${currencyFormat.format(balanceAmount)}* with *${business.name}*.\n\n'
        'Kindly settle the dues at your earliest convenience.\n'
        '${business.upiId.isNotEmpty ? "Pay via UPI: ${business.upiId}\n" : ""}\n'
        'Thank you!';

    try {
      final cleanPhone = (partyPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      String whatsappUrl;
      if (cleanPhone.isNotEmpty) {
        final phoneWithCountry = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
        whatsappUrl = 'https://wa.me/$phoneWithCountry?text=${Uri.encodeComponent(text)}';
      } else {
        whatsappUrl = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
      }
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp party reminder launch info: $e');
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Payment Reminder from ${business.name}',
        ),
      );
    } catch (e) {
      debugPrint('SharePlus reminder fallback: $e');
    }
  }

  /// Send transaction alert message to self
  static Future<void> shareSelfTransactionAlert({
    required Firm firm,
    required Invoice invoice,
  }) async {
    final text = '[BUSINESS TRANSACTION ALERT]\n\n'
        'New Invoice Created: *${invoice.invoiceNumber}*\n'
        'Firm: ${firm.name}\n'
        'Customer: ${invoice.partyName}\n'
        'Total: ${currencyFormat.format(invoice.totalAmount)}\n'
        'Received: ${currencyFormat.format(invoice.receivedAmount)}\n'
        'Balance Due: ${currencyFormat.format(invoice.balanceAmount)}\n'
        'Date: ${invoice.invoiceDate.toIso8601String().substring(0, 10)}';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Self Alert: Invoice ${invoice.invoiceNumber}',
        ),
      );
    } catch (e) {
      debugPrint('Share self transaction alert: $e');
    }
  }

  /// Send message on updating any transaction
  static Future<void> shareTransactionUpdateAlert({
    required Firm firm,
    required String reference,
    required String changes,
  }) async {
    final text = '[TRANSACTION UPDATED ALERT]\n\n'
        'Reference: *$reference*\n'
        'Firm: ${firm.name}\n'
        'Details: $changes\n'
        'Time: ${DateTime.now().toLocal()}';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Alert: Transaction Updated - $reference',
        ),
      );
    } catch (e) {
      debugPrint('Share transaction update alert: $e');
    }
  }

  /// Generic share text / message via WhatsApp or system share sheet
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
        ),
      );
    } catch (e) {
      debugPrint('Share text error: $e');
    }
  }
}
