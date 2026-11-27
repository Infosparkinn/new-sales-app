import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../models/business_profile.dart';
import '../models/firm.dart';
import '../models/fixed_asset.dart';
import '../models/service_reminder.dart';
import '../models/accounting_entry.dart';
import '../models/order_challan.dart';
import '../models/item.dart';
import '../models/party.dart';
import '../models/invoice.dart';
import '../models/transaction_record.dart';
import '../models/cash_bank_account.dart';
import '../models/loyalty_points.dart';
import '../models/loan_account.dart';
import '../models/app_user.dart';
import '../services/database_service.dart';
import '../services/share_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Firm> _firms = [];
  Firm _activeFirm = Firm(id: 'default_firm', name: 'Testing Sales App');
  List<Party> _parties = [];
  List<Item> _items = [];
  List<Invoice> _invoices = [];
  List<Invoice> _deletedInvoices = [];
  List<TransactionRecord> _transactions = [];
  List<TransactionRecord> _deletedTransactions = [];
  List<FixedAsset> _fixedAssets = [];
  List<ServiceReminder> _reminders = [];
  List<OrderChallan> _ordersChallans = [];
  List<Account> _accounts = [];
  List<CashBankAccount> _cashBankAccounts = [];
  List<LoanAccount> _loans = [];
  List<LoyaltyRecord> _loyaltyRecords = [];
  Map<String, dynamic> _syncCompanyInfo = {};
  List<Map<String, dynamic>> _messagesLog = [];

  // Multi-Device Users & Sessions (1 Desktop + 3 Mobile Android)
  List<AppUser> _appUsers = [];
  AppUser? _currentUser;
  List<DeviceSession> _deviceSessions = [];

  bool _sendSelfNotification = false;
  bool _sendUpdateAlert = false;
  bool _hideBranding = false;

  Map<String, double> _metrics = {
    'totalReceivables': 0.0,
    'totalPayables': 0.0,
    'todaySale': 0.0,
    'totalStockValue': 0.0,
    'lowStockCount': 0.0,
  };
  bool _isLoading = true;

  // Getters
  List<Firm> get firms => _firms;
  Firm get activeFirm => _activeFirm;
  BusinessProfile get business => BusinessProfile.fromMap(_activeFirm.toMap());
  List<Party> get parties => _parties;
  List<Party> get customers => _parties.where((p) => p.isCustomer).toList();
  List<Party> get suppliers => _parties.where((p) => p.isSupplier).toList();

  // Multi-Device Auth Getters
  List<AppUser> get appUsers => _appUsers;
  AppUser? get currentUser => _currentUser;
  List<DeviceSession> get deviceSessions => _deviceSessions;
  AppUser? get desktopUser => _appUsers.firstWhere(
        (u) => u.deviceSlot == 'desktop_1',
        orElse: () => _appUsers.isNotEmpty ? _appUsers.first : AppUser(
          id: 'user_desktop_admin',
          name: 'Desktop Admin (Master Counter)',
          phone: '9876543210',
          role: 'admin',
          deviceType: 'desktop',
          deviceSlot: 'desktop_1',
        ),
      );
  List<AppUser> get mobileUsers =>
      _appUsers.where((u) => u.deviceType == 'android').toList();
  int get activeDeviceCount => _deviceSessions.where((s) => s.isOnline).length;
  int get totalDeviceLicenses => 4; // 1 Desktop + 3 Mobile Android logins
  bool get isAuthenticated => _currentUser != null;
  List<Item> get items => _items;
  List<Item> get lowStockItems => _items.where((i) => i.isLowStock).toList();
  List<Invoice> get invoices => _invoices;
  List<Invoice> get deletedInvoices => _deletedInvoices;
  List<TransactionRecord> get transactions => _transactions;
  List<TransactionRecord> get deletedTransactions => _deletedTransactions;
  List<FixedAsset> get fixedAssets => _fixedAssets;
  List<ServiceReminder> get reminders => _reminders;
  List<OrderChallan> get ordersChallans => _ordersChallans;
  List<Account> get accounts => _accounts;
  List<CashBankAccount> get cashBankAccounts => _cashBankAccounts;
  List<LoanAccount> get loans => _loans;
  List<LoyaltyRecord> get loyaltyRecords => _loyaltyRecords;
  Map<String, dynamic> get syncCompanyInfo => _syncCompanyInfo;
  List<Map<String, dynamic>> get messagesLog => _messagesLog;

  CashBankAccount get cashInHand => _cashBankAccounts.firstWhere(
      (a) => a.accountType == 'cash',
      orElse: () => CashBankAccount(id: 'c1', firmId: _activeFirm.id, name: 'Cash in Hand', accountType: 'cash', balance: 18500.0));

  CashBankAccount get cashInGpay => _cashBankAccounts.firstWhere(
      (a) => a.accountType == 'gpay',
      orElse: () => CashBankAccount(id: 'g1', firmId: _activeFirm.id, name: 'Cash in GPay', accountType: 'gpay', balance: 12450.0));

  List<CashBankAccount> get bankAccounts => _cashBankAccounts.where((a) => a.accountType == 'bank').toList();
  List<CashBankAccount> get creditCards => _cashBankAccounts.where((a) => a.accountType == 'credit_card').toList();

  Map<String, double> get metrics => _metrics;
  bool get isLoading => _isLoading;
  bool get sendSelfNotification => _sendSelfNotification;
  bool get sendUpdateAlert => _sendUpdateAlert;
  bool get hideBranding => _hideBranding;

  void toggleSendSelfNotification(bool val) {
    _sendSelfNotification = val;
    notifyListeners();
  }

  void toggleSendUpdateAlert(bool val) {
    _sendUpdateAlert = val;
    notifyListeners();
  }

  void toggleHideBranding(bool val) {
    _hideBranding = val;
    notifyListeners();
  }

  AppProvider() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _firms = await _db.getFirms();
      _activeFirm = await _db.getActiveFirm();
      _parties = await _db.getParties();
      _items = await _db.getItems();
      _invoices = await _db.getInvoices();
      _deletedInvoices = await _db.getDeletedInvoices();
      _transactions = await _db.getTransactions();
      _deletedTransactions = await _db.getDeletedTransactions();
      _fixedAssets = await _db.getFixedAssets();
      _reminders = await _db.getReminders();
      _ordersChallans = await _db.getOrdersChallans();
      _accounts = await _db.getAccounts();
      _cashBankAccounts = await _db.getCashBankAccounts();
      _loans = await _db.getLoans();
      _loyaltyRecords = await _db.getLoyaltyRecords();
      _syncCompanyInfo = await _db.getSyncCompanyInfo();
      _messagesLog = await _db.getMessagesLog();
      _metrics = await _db.getDashboardMetrics();

      // Multi-Device Logins
      _appUsers = await _db.getAppUsers();
      _deviceSessions = await _db.getDeviceSessions();

      if (_currentUser == null && _appUsers.isNotEmpty) {
        final isDesktopTarget = kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));
        if (isDesktopTarget) {
          // Default to Desktop Version on Desktop / Webapp
          _currentUser = _appUsers.firstWhere(
            (u) => u.deviceType == 'desktop',
            orElse: () => _appUsers.first,
          );
        } else {
          // Default to Mobile Login on Android/Mobile
          _currentUser = _appUsers.firstWhere(
            (u) => u.deviceType == 'android',
            orElse: () => _appUsers.first,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading enterprise data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= MULTI-DEVICE AUTHENTICATION =================

  Future<bool> loginUser(String slot, String pin) async {
    final user = await _db.authenticateUser(slot, pin);
    if (user != null) {
      _currentUser = user;
      _appUsers = await _db.getAppUsers();
      _deviceSessions = await _db.getDeviceSessions();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> switchUser(AppUser user) async {
    _currentUser = user;
    await _db.setAppUserLastLogin(user.id);
    _appUsers = await _db.getAppUsers();
    _deviceSessions = await _db.getDeviceSessions();
    notifyListeners();
  }

  Future<void> logoutUser() async {
    if (_currentUser != null) {
      // Find matching session and set offline
      final session = _deviceSessions.firstWhere(
        (s) => s.userId == _currentUser!.id,
        orElse: () => _deviceSessions.first,
      );
      await _db.updateDeviceSessionStatus(session.id, false);
    }
    _currentUser = null;
    _deviceSessions = await _db.getDeviceSessions();
    notifyListeners();
  }

  Future<bool> updatePin(String userId, String oldPin, String newPin) async {
    final user = _appUsers.firstWhere((u) => u.id == userId);
    if (user.pin != oldPin) {
      return false;
    }
    await _db.updateAppUserPin(userId, newPin);
    _appUsers = await _db.getAppUsers();
    if (_currentUser?.id == userId) {
      _currentUser = _currentUser!.copyWith(pin: newPin);
    }
    notifyListeners();
    return true;
  }

  Future<void> toggleDeviceSession(String sessionId, bool isOnline) async {
    await _db.updateDeviceSessionStatus(sessionId, isOnline);
    _deviceSessions = await _db.getDeviceSessions();
    notifyListeners();
  }

  Future<void> refreshUsersAndSessions() async {
    _appUsers = await _db.getAppUsers();
    _deviceSessions = await _db.getDeviceSessions();
    notifyListeners();
  }

  // ================= MULTI-FIRM SWITCHING =================
  Future<void> switchFirm(String firmId) async {
    _db.setActiveFirmId(firmId);
    await loadAllData();
  }

  Future<void> saveFirm(Firm firm) async {
    await _db.saveFirm(firm);
    _firms = await _db.getFirms();
    _activeFirm = await _db.getActiveFirm();
    notifyListeners();
  }

  Future<void> updateBusiness(BusinessProfile profile) async {
    final firm = Firm.fromMap(profile.toMap());
    await saveFirm(firm);
  }

  // ================= PARTIES =================
  Future<void> saveParty(Party party) async {
    await _db.saveParty(party);
    _parties = await _db.getParties();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  Future<void> deleteParty(String id) async {
    await _db.deleteParty(id);
    _parties = await _db.getParties();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  // ================= ITEMS =================
  Future<void> saveItem(Item item) async {
    await _db.saveItem(item);
    _items = await _db.getItems();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteItem(id);
    _items = await _db.getItems();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  Future<void> bulkUpdatePrices(Map<String, double> newPrices) async {
    await _db.bulkUpdateItemPrices(newPrices);
    _items = await _db.getItems();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  Future<void> bulkUpdateStock(Map<String, double> newStocks) async {
    await _db.bulkUpdateItemStock(newStocks);
    _items = await _db.getItems();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  // ================= INVOICES & RECYCLE BIN =================
  Future<String> getNextInvoiceNumber() async {
    return await _db.getNextInvoiceNumber();
  }

  Future<void> createInvoice(Invoice invoice) async {
    await _db.createInvoice(invoice);

    // If "Send transaction message to self" is enabled
    if (_sendSelfNotification && _activeFirm.phone.isNotEmpty) {
      ShareService.shareSelfTransactionAlert(
        firm: _activeFirm,
        invoice: invoice,
      );
    }

    await loadAllData();
  }

  Future<void> softDeleteInvoice(String id) async {
    await _db.softDeleteInvoice(id);
    _invoices = await _db.getInvoices();
    _deletedInvoices = await _db.getDeletedInvoices();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  Future<void> restoreInvoice(String id) async {
    await _db.restoreInvoice(id);
    _invoices = await _db.getInvoices();
    _deletedInvoices = await _db.getDeletedInvoices();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  // ================= TRANSACTIONS & RECYCLE BIN =================
  Future<void> addTransaction(TransactionRecord txn) async {
    await _db.addTransaction(txn);
    _parties = await _db.getParties();
    _transactions = await _db.getTransactions();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  Future<void> softDeleteTransaction(String id) async {
    await _db.softDeleteTransaction(id);
    _transactions = await _db.getTransactions();
    _deletedTransactions = await _db.getDeletedTransactions();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  Future<void> restoreTransaction(String id) async {
    await _db.restoreTransaction(id);
    _transactions = await _db.getTransactions();
    _deletedTransactions = await _db.getDeletedTransactions();
    _metrics = await _db.getDashboardMetrics();
    notifyListeners();
  }

  // ================= FIXED ASSETS =================
  Future<void> saveFixedAsset(FixedAsset asset) async {
    await _db.saveFixedAsset(asset);
    _fixedAssets = await _db.getFixedAssets();
    notifyListeners();
  }

  Future<void> deleteFixedAsset(String id) async {
    await _db.deleteFixedAsset(id);
    _fixedAssets = await _db.getFixedAssets();
    notifyListeners();
  }

  // ================= SERVICE REMINDERS =================
  Future<void> saveReminder(ServiceReminder reminder) async {
    await _db.saveReminder(reminder);
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  Future<void> toggleReminderStatus(String id, String status) async {
    await _db.toggleReminderStatus(id, status);
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    await _db.deleteReminder(id);
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  // ================= ORDERS & DELIVERY CHALLANS =================
  Future<void> saveOrderChallan(OrderChallan doc) async {
    await _db.saveOrderChallan(doc);
    _ordersChallans = await _db.getOrdersChallans();
    notifyListeners();
  }

  Future<void> updateOrderChallanStatus(String id, String status) async {
    await _db.updateOrderChallanStatus(id, status);
    _ordersChallans = await _db.getOrdersChallans();
    notifyListeners();
  }

  // ================= ADVANCED REPORTS =================
  Future<Map<String, dynamic>> getBalanceSheet() async {
    return await _db.getBalanceSheetData();
  }

  Future<List<Map<String, dynamic>>> getBillwiseProfitReport() async {
    return await _db.getBillwiseProfitReport();
  }

  Future<List<Map<String, dynamic>>> getPartywiseProfitReport() async {
    return await _db.getPartywiseProfitReport();
  }

  Future<List<Map<String, dynamic>>> getItemBatchReport() async {
    return await _db.getItemBatchReport();
  }

  // ================= CASH & BANK OPERATIONS =================
  Future<void> saveCashBankAccount(CashBankAccount acc) async {
    await _db.saveCashBankAccount(acc);
    _cashBankAccounts = await _db.getCashBankAccounts();
    notifyListeners();
  }

  Future<void> deleteCashBankAccount(String id) async {
    await _db.deleteCashBankAccount(id);
    _cashBankAccounts = await _db.getCashBankAccounts();
    notifyListeners();
  }

  Future<void> transferBankFunds(BankTransaction txn) async {
    await _db.transferBankFunds(txn);
    _cashBankAccounts = await _db.getCashBankAccounts();
    notifyListeners();
  }

  Future<List<BankTransaction>> getBankTransactions() async {
    return await _db.getBankTransactions();
  }

  // ================= LOYALTY POINTS =================
  Future<int> getPartyLoyaltyPoints(String partyId) async {
    return await _db.getPartyLoyaltyPoints(partyId);
  }

  Future<void> addLoyaltyRecord(LoyaltyRecord rec) async {
    await _db.addLoyaltyRecord(rec);
    _loyaltyRecords = await _db.getLoyaltyRecords();
    notifyListeners();
  }

  // ================= LOANS & EMI =================
  Future<void> saveLoan(LoanAccount loan) async {
    await _db.saveLoan(loan);
    _loans = await _db.getLoans();
    notifyListeners();
  }

  Future<void> recordLoanPayment(LoanPayment payment) async {
    await _db.recordLoanPayment(payment);
    _loans = await _db.getLoans();
    notifyListeners();
  }

  Future<List<LoanPayment>> getLoanPayments(String loanId) async {
    return await _db.getLoanPayments(loanId);
  }

  // ================= SYNC COMPANY =================
  Future<void> triggerCompanySync() async {
    await _db.triggerCompanySync();
    _syncCompanyInfo = await _db.getSyncCompanyInfo();
    notifyListeners();
  }

  // ================= MESSAGES & BROADCAST =================
  Future<void> logMessage({
    required String phone,
    required String name,
    required String message,
    String channel = 'WhatsApp',
  }) async {
    await _db.logMessage(
      recipientPhone: phone,
      recipientName: name,
      messageContent: message,
      channel: channel,
    );
    _messagesLog = await _db.getMessagesLog();
    notifyListeners();
  }

  // ================= UTILITIES & INTEGRITY =================
  Future<Map<String, dynamic>> verifyDataIntegrity() async {
    return await _db.verifyDataIntegrity();
  }

  Future<void> bulkUpdateTaxSlabs(List<String> itemIds, double newTaxRate) async {
    await _db.bulkUpdateTaxSlabs(itemIds, newTaxRate);
    _items = await _db.getItems();
    notifyListeners();
  }

  Future<void> closeFinancialYear(String newYearLabel) async {
    await _db.closeFinancialYear(newYearLabel);
    await loadAllData();
  }

  // ================= BACKUP & RESTORE =================
  Future<String> exportBackupJson() async {
    return await _db.exportBackupJson();
  }

  Future<void> restoreBackupJson(String jsonStr) async {
    await _db.restoreBackupJson(jsonStr);
    await loadAllData();
  }
}
