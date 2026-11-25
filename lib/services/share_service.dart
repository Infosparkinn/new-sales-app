import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/business_profile.dart';
import '../models/firm.dart';
import '../models/invoice.dart';
import 'pdf_service.dart';

class ShareService {
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

  /// Share PDF invoice to WhatsApp / Email / etc. using Android / Windows Share Sheet (100% Free)
  static Future<void> shareInvoiceViaWhatsApp({
    required BusinessProfile business,
    required Invoice invoice,
  }) async {
    final pdfBytes = await PdfService.generateInvoicePdf(
      business: business,
      invoice: invoice,
    );

    final cleanInvNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename = 'Invoice_$cleanInvNum.pdf';
    final file = await PdfService.savePdfToFile(pdfBytes, filename);

    final text = 'Dear ${invoice.partyName},\n\n'
        'Please find attached Tax Invoice *${invoice.invoiceNumber}* for *${currencyFormat.format(invoice.totalAmount)}* from *${business.name}*.\n\n'
        '${invoice.balanceAmount > 0 ? "Pending Balance Due: ${currencyFormat.format(invoice.balanceAmount)}\n" : "Status: Fully Paid [✓]\n"}'
        '${invoice.ewayBillNumber.isNotEmpty ? "E-Way Bill No: ${invoice.ewayBillNumber}\n" : ""}'
        '${business.upiId.isNotEmpty ? "Pay via UPI: ${business.upiId}\n" : ""}\n'
        'Thank you for your business!';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: text,
        subject: 'Invoice ${invoice.invoiceNumber} from ${business.name}',
      ),
    );
  }

  /// Share Ledger / Khata Reminder
  static Future<void> sharePartyReminder({
    required BusinessProfile business,
    required String partyName,
    required double balanceAmount,
  }) async {
    final text = 'Dear $partyName,\n\n'
        'This is a gentle reminder regarding your outstanding balance of *${currencyFormat.format(balanceAmount)}* with *${business.name}*.\n\n'
        'Kindly settle the dues at your earliest convenience.\n'
        '${business.upiId.isNotEmpty ? "Pay via UPI: ${business.upiId}\n" : ""}\n'
        'Thank you!';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Payment Reminder from ${business.name}',
      ),
    );
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

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Self Alert: Invoice ${invoice.invoiceNumber}',
      ),
    );
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

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Alert: Transaction Updated - $reference',
      ),
    );
  }

  /// Generic share text / message via WhatsApp or system share sheet
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }
}
