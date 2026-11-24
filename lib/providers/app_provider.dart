import 'package:flutter/foundation.dart';
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
import '../services/database_service.dart';
import '../services/share_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Firm> _firms = [];
  Firm _activeFirm = Firm(id: 'default_firm', name: 'My Business Store');
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
      _metrics = await _db.getDashboardMetrics();
    } catch (e) {
      debugPrint('Error loading enterprise data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}
