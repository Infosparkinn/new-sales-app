class UpiService {
  /// Generates NPCI-compliant UPI payment URL
  static String generateUpiUri({
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
  }) {
    final cleanUpi = upiId.trim().isEmpty ? 'merchant@upi' : upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim().isEmpty ? 'Store Merchant' : payeeName.trim());
    final cleanNote = Uri.encodeComponent(transactionNote.trim().isEmpty ? 'Bill Payment' : transactionNote.trim());
    final amountStr = amount.toStringAsFixed(2);

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$amountStr&cu=INR&tn=$cleanNote';
  }
}
