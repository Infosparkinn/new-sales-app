import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

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

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;
  final Uuid _uuid = const Uuid();
  String _activeFirmId = 'default_firm';

  String get activeFirmId => _activeFirmId;
  void setActiveFirmId(String id) {
    _activeFirmId = id;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'vyapar_sales_app_v2.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Firms Table (Multiple Companies / Firms)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS firms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        state TEXT,
        gstin TEXT,
        upiId TEXT,
        bankName TEXT,
        accountNumber TEXT,
        ifsc TEXT,
        termsAndConditions TEXT,
        invoicePrefix TEXT,
        nextInvoiceNumber INTEGER,
        isDefault INTEGER
      )
    ''');

    // 2. Business Profile Table (Legacy / Active Firm pointer)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS business_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        state TEXT,
        gstin TEXT,
        upiId TEXT,
        bankName TEXT,
        accountNumber TEXT,
        ifsc TEXT,
        termsAndConditions TEXT,
        invoicePrefix TEXT,
        nextInvoiceNumber INTEGER
      )
    ''');

    // 3. Parties Table (with priceTier and customRates)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parties (
        id TEXT PRIMARY KEY,
        firmId TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        state TEXT,
        gstin TEXT,
        partyType TEXT NOT NULL,
        openingBalance REAL,
        currentBalance REAL,
        creditLimit REAL,
        priceTier TEXT,
        customRatesJson TEXT,
        createdAt TEXT
      )
    ''');

    // 4. Items Table (with wholesalePrice, dealerPrice, customFields, batch, expiry, serial)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT PRIMARY KEY,
        firmId TEXT,
        name TEXT NOT NULL,
        code TEXT,
        category TEXT,
        unit TEXT,
        salePrice REAL,
        wholesalePrice REAL,
        dealerPrice REAL,
        purchasePrice REAL,
        taxRate REAL,
        hsnCode TEXT,
        stockQuantity REAL,
        minStockAlert REAL,
        isTaxInclusive INTEGER,
        batchNumber TEXT,
        expiryDate TEXT,
        serialNumber TEXT,
        customFieldsJson TEXT,
        updatedAt TEXT
      )
    ''');

    // 5. Invoices Table (with TCS, TDS, E-way bill, Profit, Soft delete, hideBranding)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        firmId TEXT,
        invoiceNumber TEXT NOT NULL,
        partyId TEXT,
        partyName TEXT NOT NULL,
        partyPhone TEXT,
        partyAddress TEXT,
        partyState TEXT,
        partyGstin TEXT,
        invoiceDate TEXT NOT NULL,
        paymentMode TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discountAmount REAL,
        cgstAmount REAL,
        sgstAmount REAL,
        igstAmount REAL,
        tcsRate REAL,
        tcsAmount REAL,
        tdsRate REAL,
        tdsAmount REAL,
        totalAmount REAL NOT NULL,
        receivedAmount REAL NOT NULL,
        balanceAmount REAL NOT NULL,
        profitAmount REAL,
        status TEXT NOT NULL,
        notes TEXT,
        ewayBillNumber TEXT,
        vehicleNumber TEXT,
        transporterName TEXT,
        isDeleted INTEGER DEFAULT 0,
        hideBranding INTEGER DEFAULT 0
      )
    ''');

    // 6. Invoice Items Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        itemName TEXT NOT NULL,
        hsnCode TEXT,
        quantity REAL NOT NULL,
        unit TEXT,
        unitPrice REAL NOT NULL,
        purchasePrice REAL,
        discountPercent REAL,
        taxRate REAL,
        cgstAmount REAL,
        sgstAmount REAL,
        igstAmount REAL,
        totalAmount REAL NOT NULL,
        batchNumber TEXT,
        serialNumber TEXT,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 7. Transactions Table (with ITC, soft delete)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        firmId TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        partyId TEXT,
        partyName TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMode TEXT,
        referenceId TEXT,
        description TEXT,
        isItcEligible INTEGER DEFAULT 0,
        gstin TEXT,
        taxRate REAL,
        cgstAmount REAL,
        sgstAmount REAL,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    // 8. Fixed Assets Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fixed_assets (
        id TEXT PRIMARY KEY,
        firmId TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        purchaseDate TEXT NOT NULL,
        purchaseAmount REAL NOT NULL,
        currentBookValue REAL NOT NULL,
        depreciationRatePercent REAL,
        notes TEXT
      )
    ''');

    // 9. Service Reminders Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_reminders (
        id TEXT PRIMARY KEY,
        firmId TEXT NOT NULL,
        customerId TEXT,
        customerName TEXT NOT NULL,
        customerPhone TEXT,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL,
        reminderFrequency TEXT
      )
    ''');

    // 10. Chart of Accounts Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        firmId TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    // 11. Journal Entries Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id TEXT PRIMARY KEY,
        firmId TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        debitAccountId TEXT NOT NULL,
        debitAccountName TEXT NOT NULL,
        creditAccountId TEXT NOT NULL,
        creditAccountName TEXT NOT NULL,
        amount REAL NOT NULL,
        referenceType TEXT,
        referenceId TEXT
      )
    ''');

    // 12. Orders & Challans Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders_challans (
        id TEXT PRIMARY KEY,
        firmId TEXT NOT NULL,
        type TEXT NOT NULL,
        documentNumber TEXT NOT NULL,
        partyId TEXT NOT NULL,
        partyName TEXT NOT NULL,
        partyPhone TEXT,
        date TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // 13. Order & Challan Items Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_challan_items (
        id TEXT PRIMARY KEY,
        orderChallanId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        itemName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT,
        unitPrice REAL NOT NULL,
        taxRate REAL,
        totalAmount REAL NOT NULL,
        FOREIGN KEY (orderChallanId) REFERENCES orders_challans (id) ON DELETE CASCADE
      )
    ''');

    // Seed comprehensive initial enterprise data
    await _seedEnterpriseData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // If upgrading from v1
    await _onCreate(db, newVersion);
  }

  Future<void> _seedEnterpriseData(Database db) async {
    // 1. Primary Default Firm
    final defaultFirm = Firm(
      id: 'default_firm',
      name: 'Shree Ganesh Enterprises',
      phone: '9876543210',
      email: 'contact@shreeganesh.com',
      address: 'Shop #12, Market Main Road, Chennai',
      state: 'Tamil Nadu',
      gstin: '33AABCS1429B1Z8',
      upiId: '9876543210@upi',
      bankName: 'HDFC Bank',
      accountNumber: '50200012345678',
      ifsc: 'HDFC0001234',
      invoicePrefix: 'INV-',
      nextInvoiceNumber: 4,
      isDefault: true,
    );
    await db.insert('firms', defaultFirm.toMap());

    // Second Firm (Multiple Companies feature)
    final secondaryFirm = Firm(
      id: 'firm_logistics',
      name: 'Ganesh Logistics & Trading',
      phone: '9876543211',
      email: 'logistics@shreeganesh.com',
      address: 'Warehouse #4, Ring Road, Chennai',
      state: 'Tamil Nadu',
      gstin: '33AABCG5544B2Z1',
      upiId: 'ganeshlogistics@upi',
      bankName: 'State Bank of India',
      accountNumber: '30495839281',
      ifsc: 'SBIN0004567',
      invoicePrefix: 'GLT-',
      nextInvoiceNumber: 1,
      isDefault: false,
    );
    await db.insert('firms', secondaryFirm.toMap());

    // Legacy business profile pointer
    await db.insert('business_profile', BusinessProfile.fromMap(defaultFirm.toMap()).toMap());

    // 2. Chart of Accounts
    final accounts = [
      Account(id: 'acc_cash', firmId: 'default_firm', code: '1001', name: 'Cash in Hand', category: 'Asset', balance: 18500.0),
      Account(id: 'acc_bank', firmId: 'default_firm', code: '1002', name: 'HDFC Bank Account', category: 'Asset', balance: 94000.0),
      Account(id: 'acc_ar', firmId: 'default_firm', code: '1003', name: 'Accounts Receivable (Customers)', category: 'Asset', balance: 5700.0),
      Account(id: 'acc_inv', firmId: 'default_firm', code: '1004', name: 'Inventory Asset', category: 'Asset', balance: 34500.0),
      Account(id: 'acc_fa', firmId: 'default_firm', code: '1005', name: 'Fixed Assets', category: 'Asset', balance: 65000.0),
      Account(id: 'acc_ap', firmId: 'default_firm', code: '2001', name: 'Accounts Payable (Suppliers)', category: 'Liability', balance: 12500.0),
      Account(id: 'acc_gst_pay', firmId: 'default_firm', code: '2002', name: 'GST Output Liability', category: 'Liability', balance: 3480.0),
      Account(id: 'acc_equity', firmId: 'default_firm', code: '3001', name: "Owner's Capital", category: 'Equity', balance: 180000.0),
      Account(id: 'acc_sales', firmId: 'default_firm', code: '4001', name: 'Sales Revenue', category: 'Income', balance: 45000.0),
      Account(id: 'acc_cogs', firmId: 'default_firm', code: '5001', name: 'Cost of Goods Sold', category: 'Expense', balance: 32000.0),
      Account(id: 'acc_exp', firmId: 'default_firm', code: '5002', name: 'Operating Expenses', category: 'Expense', balance: 4200.0),
    ];
    for (var acc in accounts) {
      await db.insert('accounts', acc.toMap());
    }

    // 3. Fixed Assets
    final fa1 = FixedAsset(
      id: _uuid.v4(),
      firmId: 'default_firm',
      name: 'Billing Counter Computers & POS Terminal',
      category: 'IT Equipment',
      purchaseDate: DateTime(2025, 4, 10),
      purchaseAmount: 45000.0,
      currentBookValue: 38000.0,
      depreciationRatePercent: 15.0,
      notes: 'Dell i5 desktop, TVS barcode gun, 3-inch thermal printer',
    );
    final fa2 = FixedAsset(
      id: _uuid.v4(),
      firmId: 'default_firm',
      name: 'Store Display Racks & Wooden Counters',
      category: 'Furniture',
      purchaseDate: DateTime(2025, 2, 1),
      purchaseAmount: 32000.0,
      currentBookValue: 27000.0,
      depreciationRatePercent: 10.0,
    );
    await db.insert('fixed_assets', fa1.toMap());
    await db.insert('fixed_assets', fa2.toMap());

    // 4. Service Reminders
    final sr1 = ServiceReminder(
      id: _uuid.v4(),
      firmId: 'default_firm',
      customerName: 'Ramesh Stores',
      customerPhone: '9840123456',
      title: 'Annual AMC Service & Weight Scale Calibration',
      description: 'Check legal metrology stamp & POS battery renewal',
      dueDate: DateTime.now().add(const Duration(days: 4)),
      status: 'pending',
    );
    await db.insert('service_reminders', sr1.toMap());

    // 5. Parties with Price Tiers and Credit Limits
    final p1 = Party(
      id: 'party_ramesh',
      firmId: 'default_firm',
      name: 'Ramesh Stores',
      phone: '9840123456',
      address: '24 Anna Salai, Chennai',
      state: 'Tamil Nadu',
      gstin: '33AAACR1234A1Z1',
      partyType: 'customer',
      currentBalance: 4500.0,
      creditLimit: 25000.0,
      priceTier: 'wholesale',
      customRates: {'item_rice': 460.0},
    );
    final p2 = Party(
      id: 'party_murugan',
      firmId: 'default_firm',
      name: 'Murugan Wholesalers',
      phone: '9840987654',
      address: '15 Gandhi Nagar, Madurai',
      state: 'Tamil Nadu',
      gstin: '33AAAFM5678B1Z2',
      partyType: 'supplier',
      currentBalance: -12500.0,
    );
    final p3 = Party(
      id: 'party_priya',
      firmId: 'default_firm',
      name: 'Priya Supermarket',
      phone: '9790112233',
      address: '100 Feet Road, Coimbatore',
      state: 'Tamil Nadu',
      partyType: 'customer',
      currentBalance: 1200.0,
      creditLimit: 10000.0,
      priceTier: 'retail',
    );
    await db.insert('parties', p1.toMap());
    await db.insert('parties', p2.toMap());
    await db.insert('parties', p3.toMap());

    // 6. Items with Multi-Tier Pricing & Batches
    final i1 = Item(
      id: 'item_rice',
      firmId: 'default_firm',
      name: 'Basmati Rice 5kg',
      code: 'RICE05',
      category: 'Grains & Pulses',
      unit: 'Bag',
      salePrice: 480.0,
      wholesalePrice: 450.0,
      dealerPrice: 430.0,
      purchasePrice: 410.0,
      taxRate: 5.0,
      hsnCode: '1006',
      stockQuantity: 45.0,
      minStockAlert: 10.0,
      batchNumber: 'B-2026-08',
      expiryDate: DateTime(2027, 8, 30),
      serialNumber: 'SR-RC-001',
      customFields: {'Brand': 'Royal Treat', 'Origin': 'Punjab'},
    );
    final i2 = Item(
      id: 'item_oil',
      firmId: 'default_firm',
      name: 'Sunflower Oil 1L',
      code: 'OIL01',
      category: 'Edible Oils',
      unit: 'Pcs',
      salePrice: 150.0,
      wholesalePrice: 140.0,
      dealerPrice: 135.0,
      purchasePrice: 125.0,
      taxRate: 12.0,
      hsnCode: '1512',
      stockQuantity: 80.0,
      minStockAlert: 15.0,
      batchNumber: 'B-2026-11',
      expiryDate: DateTime(2027, 5, 15),
      customFields: {'Type': 'Refined', 'Packaging': 'Pouch'},
    );
    final i3 = Item(
      id: 'item_dal',
      firmId: 'default_firm',
      name: 'Toor Dal 1kg',
      code: 'DAL01',
      category: 'Grains & Pulses',
      unit: 'Kg',
      salePrice: 160.0,
      wholesalePrice: 150.0,
      dealerPrice: 142.0,
      purchasePrice: 132.0,
      taxRate: 5.0,
      hsnCode: '0713',
      stockQuantity: 4.0, // Low stock
      minStockAlert: 10.0,
      batchNumber: 'B-2026-09',
    );
    final i4 = Item(
      id: 'item_tea',
      firmId: 'default_firm',
      name: 'Tea Powder 500g',
      code: 'TEA50',
      category: 'Beverages',
      unit: 'Pcs',
      salePrice: 220.0,
      wholesalePrice: 205.0,
      dealerPrice: 195.0,
      purchasePrice: 175.0,
      taxRate: 5.0,
      hsnCode: '0902',
      stockQuantity: 25.0,
      minStockAlert: 5.0,
    );
    await db.insert('items', i1.toMap());
    await db.insert('items', i2.toMap());
    await db.insert('items', i3.toMap());
    await db.insert('items', i4.toMap());

    // 7. Invoices with Profit Tracking & E-Way Bill Details
    final invId1 = _uuid.v4();
    final inv1 = Invoice(
      id: invId1,
      firmId: 'default_firm',
      invoiceNumber: 'INV-001',
      partyId: p1.id,
      partyName: p1.name,
      partyPhone: p1.phone,
      partyAddress: p1.address,
      partyState: p1.state,
      partyGstin: p1.gstin,
      invoiceDate: DateTime.now().subtract(const Duration(days: 2)),
      paymentMode: 'online',
      subtotal: 960.0,
      cgstAmount: 24.0,
      sgstAmount: 24.0,
      totalAmount: 1008.0,
      receivedAmount: 1008.0,
      balanceAmount: 0.0,
      profitAmount: 140.0, // (480 - 410) * 2
      status: 'paid',
      ewayBillNumber: '281928391829',
      vehicleNumber: 'TN-01-AB-1234',
      transporterName: 'VRL Logistics',
      items: [
        InvoiceItem(
          id: _uuid.v4(),
          invoiceId: invId1,
          itemId: i1.id,
          itemName: i1.name,
          hsnCode: i1.hsnCode,
          quantity: 2,
          unit: i1.unit,
          unitPrice: i1.salePrice,
          purchasePrice: i1.purchasePrice,
          taxRate: i1.taxRate,
          cgstAmount: 24.0,
          sgstAmount: 24.0,
          totalAmount: 1008.0,
          batchNumber: i1.batchNumber,
        )
      ],
    );
    await db.insert('invoices', inv1.toMap());
    for (var item in inv1.items) {
      await db.insert('invoice_items', item.toMap());
    }

    // 8. Transactions
    await db.insert('transactions', TransactionRecord(
      id: _uuid.v4(),
      firmId: 'default_firm',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: 'sale',
      partyId: p1.id,
      partyName: p1.name,
      amount: 1008.0,
      paymentMode: 'online',
      referenceId: inv1.invoiceNumber,
      description: 'Sale Invoice ${inv1.invoiceNumber}',
    ).toMap());

    await db.insert('transactions', TransactionRecord(
      id: _uuid.v4(),
      firmId: 'default_firm',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      type: 'expense',
      partyName: 'Office Electricity Bill',
      amount: 2400.0,
      paymentMode: 'online',
      description: 'TNEB Commercial Power Tariff',
      isItcEligible: true,
      gstin: '33AAACT0000Z1Z5',
      taxRate: 18.0,
      cgstAmount: 183.05,
      sgstAmount: 183.05,
    ).toMap());
  }

  // ================= FIRMS (MULTIPLE COMPANIES) =================
  Future<List<Firm>> getFirms() async {
    final db = await database;
    final res = await db.query('firms', orderBy: 'isDefault DESC, name ASC');
    return res.map((m) => Firm.fromMap(m)).toList();
  }

  Future<Firm> getActiveFirm() async {
    final db = await database;
    final res = await db.query('firms', where: 'id = ?', whereArgs: [_activeFirmId], limit: 1);
    if (res.isNotEmpty) {
      return Firm.fromMap(res.first);
    }
    final def = await db.query('firms', where: 'isDefault = 1', limit: 1);
    if (def.isNotEmpty) {
      return Firm.fromMap(def.first);
    }
    return Firm(id: 'default_firm', name: 'My Firm');
  }

  Future<void> saveFirm(Firm firm) async {
    final db = await database;
    await db.insert('firms', firm.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Legacy compatibility for BusinessProfile
  Future<BusinessProfile> getBusinessProfile() async {
    final firm = await getActiveFirm();
    return BusinessProfile.fromMap(firm.toMap());
  }

  Future<void> updateBusinessProfile(BusinessProfile profile) async {
    final firm = Firm.fromMap(profile.toMap());
    await saveFirm(firm);
  }

  // ================= PARTIES =================
  Future<List<Party>> getParties({String? type}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (type != null) {
      res = await db.query('parties',
          where: 'partyType = ? AND (firmId = ? OR firmId IS NULL)',
          whereArgs: [type, _activeFirmId],
          orderBy: 'name ASC');
    } else {
      res = await db.query('parties',
          where: 'firmId = ? OR firmId IS NULL',
          whereArgs: [_activeFirmId],
          orderBy: 'name ASC');
    }
    return res.map((m) => Party.fromMap(m)).toList();
  }

  Future<Party?> getPartyById(String id) async {
    final db = await database;
    final res = await db.query('parties', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) return Party.fromMap(res.first);
    return null;
  }

  Future<void> saveParty(Party party) async {
    final db = await database;
    final map = party.toMap();
    map['firmId'] = _activeFirmId;
    await db.insert('parties', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteParty(String id) async {
    final db = await database;
    await db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  // ================= ITEMS & BULK UPDATES =================
  Future<List<Item>> getItems({String? category, bool? lowStockOnly}) async {
    final db = await database;
    String where = '(firmId = ? OR firmId IS NULL)';
    List<dynamic> whereArgs = [_activeFirmId];

    if (category != null && category != 'All') {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    final res = await db.query('items', where: where, whereArgs: whereArgs, orderBy: 'name ASC');
    final items = res.map((m) => Item.fromMap(m)).toList();

    if (lowStockOnly == true) {
      return items.where((it) => it.isLowStock).toList();
    }
    return items;
  }

  Future<Item?> getItemById(String id) async {
    final db = await database;
    final res = await db.query('items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) return Item.fromMap(res.first);
    return null;
  }

  Future<void> saveItem(Item item) async {
    final db = await database;
    final map = item.toMap();
    map['firmId'] = _activeFirmId;
    await db.insert('items', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> bulkUpdateItemPrices(Map<String, double> itemSalePrices) async {
    final db = await database;
    final batch = db.batch();
    itemSalePrices.forEach((itemId, newPrice) {
      batch.rawUpdate(
        'UPDATE items SET salePrice = ?, updatedAt = ? WHERE id = ?',
        [newPrice, DateTime.now().toIso8601String(), itemId],
      );
    });
    await batch.commit(noResult: true);
  }

  Future<void> bulkUpdateItemStock(Map<String, double> itemStocks) async {
    final db = await database;
    final batch = db.batch();
    itemStocks.forEach((itemId, newStock) {
      batch.rawUpdate(
        'UPDATE items SET stockQuantity = ?, updatedAt = ? WHERE id = ?',
        [newStock, DateTime.now().toIso8601String(), itemId],
      );
    });
    await batch.commit(noResult: true);
  }

  // ================= INVOICES & BILLING =================
  Future<List<Invoice>> getInvoices({bool includeDeleted = false, int limit = 100}) async {
    final db = await database;
    final where = includeDeleted
        ? '(firmId = ? OR firmId IS NULL)'
        : '(firmId = ? OR firmId IS NULL) AND (isDeleted = 0 OR isDeleted IS NULL)';
    final res = await db.query('invoices',
        where: where,
        whereArgs: [_activeFirmId],
        orderBy: 'invoiceDate DESC',
        limit: limit);

    List<Invoice> list = [];
    for (var m in res) {
      final itemsRes = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [m['id']]);
      final items = itemsRes.map((im) => InvoiceItem.fromMap(im)).toList();
      list.add(Invoice.fromMap(m, items));
    }
    return list;
  }

  Future<List<Invoice>> getDeletedInvoices() async {
    final db = await database;
    final res = await db.query('invoices',
        where: '(firmId = ? OR firmId IS NULL) AND isDeleted = 1',
        whereArgs: [_activeFirmId],
        orderBy: 'invoiceDate DESC');

    List<Invoice> list = [];
    for (var m in res) {
      final itemsRes = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [m['id']]);
      final items = itemsRes.map((im) => InvoiceItem.fromMap(im)).toList();
      list.add(Invoice.fromMap(m, items));
    }
    return list;
  }

  Future<String> getNextInvoiceNumber() async {
    final firm = await getActiveFirm();
    final numStr = firm.nextInvoiceNumber.toString().padLeft(3, '0');
    return '${firm.invoicePrefix}$numStr';
  }

  Future<void> createInvoice(Invoice invoice) async {
    final db = await database;
    await db.transaction((txn) async {
      final invMap = invoice.toMap();
      invMap['firmId'] = _activeFirmId;

      // 1. Insert Invoice
      await txn.insert('invoices', invMap, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Insert Invoice Items & Deduct Stock
      for (var item in invoice.items) {
        await txn.insert('invoice_items', item.toMap());
        await txn.rawUpdate('''
          UPDATE items 
          SET stockQuantity = stockQuantity - ? 
          WHERE id = ?
        ''', [item.quantity, item.itemId]);
      }

      // 3. Update Customer Balance if credit/partial
      if (invoice.partyId != null && invoice.balanceAmount > 0) {
        await txn.rawUpdate('''
          UPDATE parties 
          SET currentBalance = currentBalance + ? 
          WHERE id = ?
        ''', [invoice.balanceAmount, invoice.partyId]);
      }

      // 4. Record Transaction
      final txnRecord = TransactionRecord(
        id: _uuid.v4(),
        firmId: _activeFirmId,
        date: invoice.invoiceDate,
        type: 'sale',
        partyId: invoice.partyId,
        partyName: invoice.partyName,
        amount: invoice.receivedAmount > 0 ? invoice.receivedAmount : invoice.totalAmount,
        paymentMode: invoice.paymentMode,
        referenceId: invoice.invoiceNumber,
        description: 'Sale Invoice ${invoice.invoiceNumber}',
      );
      await txn.insert('transactions', txnRecord.toMap());

      // 5. Increment Next Invoice Number
      final firm = await getActiveFirm();
      await txn.rawUpdate('''
        UPDATE firms 
        SET nextInvoiceNumber = nextInvoiceNumber + 1 
        WHERE id = ?
      ''', [firm.id]);
    });
  }

  Future<void> softDeleteInvoice(String id) async {
    final db = await database;
    await db.rawUpdate('UPDATE invoices SET isDeleted = 1 WHERE id = ?', [id]);
  }

  Future<void> restoreInvoice(String id) async {
    final db = await database;
    await db.rawUpdate('UPDATE invoices SET isDeleted = 0 WHERE id = ?', [id]);
  }

  // ================= TRANSACTIONS & RECYCLE BIN =================
  Future<List<TransactionRecord>> getTransactions({bool includeDeleted = false, int limit = 100}) async {
    final db = await database;
    final where = includeDeleted
        ? '(firmId = ? OR firmId IS NULL)'
        : '(firmId = ? OR firmId IS NULL) AND (isDeleted = 0 OR isDeleted IS NULL)';
    final res = await db.query('transactions',
        where: where,
        whereArgs: [_activeFirmId],
        orderBy: 'date DESC',
        limit: limit);
    return res.map((m) => TransactionRecord.fromMap(m)).toList();
  }

  Future<List<TransactionRecord>> getDeletedTransactions() async {
    final db = await database;
    final res = await db.query('transactions',
        where: '(firmId = ? OR firmId IS NULL) AND isDeleted = 1',
        whereArgs: [_activeFirmId],
        orderBy: 'date DESC');
    return res.map((m) => TransactionRecord.fromMap(m)).toList();
  }

  Future<void> addTransaction(TransactionRecord record) async {
    final db = await database;
    final map = record.toMap();
    map['firmId'] = _activeFirmId;
    await db.insert('transactions', map);

    if (record.type == 'payment_in' && record.partyId != null) {
      await db.rawUpdate('''
        UPDATE parties 
        SET currentBalance = currentBalance - ? 
        WHERE id = ?
      ''', [record.amount, record.partyId]);
    } else if (record.type == 'payment_out' && record.partyId != null) {
      await db.rawUpdate('''
        UPDATE parties 
        SET currentBalance = currentBalance + ? 
        WHERE id = ?
      ''', [record.amount, record.partyId]);
    }
  }

  Future<void> softDeleteTransaction(String id) async {
    final db = await database;
    await db.rawUpdate('UPDATE transactions SET isDeleted = 1 WHERE id = ?', [id]);
  }

  Future<void> restoreTransaction(String id) async {
    final db = await database;
    await db.rawUpdate('UPDATE transactions SET isDeleted = 0 WHERE id = ?', [id]);
  }

  // ================= FIXED ASSETS =================
  Future<List<FixedAsset>> getFixedAssets() async {
    final db = await database;
    final res = await db.query('fixed_assets',
        where: 'firmId = ? OR firmId IS NULL',
        whereArgs: [_activeFirmId],
        orderBy: 'purchaseDate DESC');
    return res.map((m) => FixedAsset.fromMap(m)).toList();
  }

  Future<void> saveFixedAsset(FixedAsset asset) async {
    final db = await database;
    final map = asset.toMap();
    map['firmId'] = _activeFirmId;
    await db.insert('fixed_assets', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFixedAsset(String id) async {
    final db = await database;
    await db.delete('fixed_assets', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SERVICE REMINDERS =================
  Future<List<ServiceReminder>> getReminders() async {
    final db = await database;
    final res = await db.query('service_reminders',
        where: 'firmId = ? OR firmId IS NULL',
        whereArgs: [_activeFirmId],
        orderBy: 'dueDate ASC');
    return res.map((m) => ServiceReminder.fromMap(m)).toList();
  }

  Future<void> saveReminder(ServiceReminder reminder) async {
    final db = await database;
    final map = reminder.toMap();
    map['firmId'] = _activeFirmId;
    await db.insert('service_reminders', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> toggleReminderStatus(String id, String newStatus) async {
    final db = await database;
    await db.rawUpdate('UPDATE service_reminders SET status = ? WHERE id = ?', [newStatus, id]);
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('service_reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ================= ORDERS & DELIVERY CHALLANS =================
  Future<List<OrderChallan>> getOrdersChallans({String? type}) async {
    final db = await database;
    String where = '(firmId = ? OR firmId IS NULL)';
    List<dynamic> whereArgs = [_activeFirmId];
    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }
    final res = await db.query('orders_challans', where: where, whereArgs: whereArgs, orderBy: 'date DESC');
    List<OrderChallan> list = [];
    for (var m in res) {
      final itemsRes = await db.query('order_challan_items', where: 'orderChallanId = ?', whereArgs: [m['id']]);
      final items = itemsRes.map((im) => OrderChallanItem.fromMap(im)).toList();
      list.add(OrderChallan.fromMap(m, items));
    }
    return list;
  }

  Future<void> saveOrderChallan(OrderChallan doc) async {
    final db = await database;
    await db.transaction((txn) async {
      final map = doc.toMap();
      map['firmId'] = _activeFirmId;
      await txn.insert('orders_challans', map, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var it in doc.items) {
        await txn.insert('order_challan_items', it.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateOrderChallanStatus(String id, String status) async {
    final db = await database;
    await db.rawUpdate('UPDATE orders_challans SET status = ? WHERE id = ?', [status, id]);
  }

  // ================= ACCOUNTING & BALANCE SHEET =================
  Future<List<Account>> getAccounts() async {
    final db = await database;
    final res = await db.query('accounts',
        where: 'firmId = ? OR firmId IS NULL',
        whereArgs: [_activeFirmId],
        orderBy: 'code ASC');
    return res.map((m) => Account.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getBalanceSheetData() async {
    final metrics = await getDashboardMetrics();
    final assets = await getFixedAssets();
    final totalFixedAssets = assets.fold(0.0, (sum, a) => sum + a.currentBookValue);

    // Current Assets
    final debtors = metrics['totalReceivables'] ?? 0.0;
    final stockVal = metrics['totalStockValue'] ?? 0.0;
    const cashBank = 18500.0 + 94000.0; // Sample bank + cash balances
    final totalCurrentAssets = debtors + stockVal + cashBank;
    final totalAssets = totalFixedAssets + totalCurrentAssets;

    // Liabilities
    final creditors = metrics['totalPayables'] ?? 0.0;
    final totalLiabilities = creditors + 3480.0; // Accounts payable + Tax payable

    // Equity / Capital
    final equity = totalAssets - totalLiabilities;

    return {
      'fixedAssets': totalFixedAssets,
      'debtors': debtors,
      'stockValue': stockVal,
      'cashAndBank': cashBank,
      'totalAssets': totalAssets,
      'creditors': creditors,
      'taxLiability': 3480.0,
      'totalLiabilities': totalLiabilities,
      'equity': equity,
    };
  }

  // ================= ADVANCED REPORTS =================
  // 1. Billwise Profit Report
  Future<List<Map<String, dynamic>>> getBillwiseProfitReport() async {
    final invoices = await getInvoices();
    return invoices.map((inv) {
      final totalSale = inv.totalAmount;
      final totalCost = inv.items.fold(0.0, (sum, it) => sum + (it.purchasePrice * it.quantity));
      final profit = totalSale - totalCost;
      final marginPercent = totalSale > 0 ? (profit / totalSale) * 100 : 0.0;

      return {
        'invoiceNumber': inv.invoiceNumber,
        'date': inv.invoiceDate,
        'partyName': inv.partyName,
        'saleAmount': totalSale,
        'costAmount': totalCost,
        'profit': profit,
        'marginPercent': marginPercent,
      };
    }).toList();
  }

  // 2. Partywise Profit Report
  Future<List<Map<String, dynamic>>> getPartywiseProfitReport() async {
    final invoices = await getInvoices();
    final Map<String, Map<String, dynamic>> partyMap = {};

    for (var inv in invoices) {
      final name = inv.partyName;
      if (!partyMap.containsKey(name)) {
        partyMap[name] = {
          'partyName': name,
          'totalSales': 0.0,
          'totalCost': 0.0,
          'totalProfit': 0.0,
          'billCount': 0,
        };
      }
      final totalSale = inv.totalAmount;
      final totalCost = inv.items.fold(0.0, (sum, it) => sum + (it.purchasePrice * it.quantity));
      final profit = totalSale - totalCost;

      partyMap[name]!['totalSales'] += totalSale;
      partyMap[name]!['totalCost'] += totalCost;
      partyMap[name]!['totalProfit'] += profit;
      partyMap[name]!['billCount'] += 1;
    }

    return partyMap.values.toList();
  }

  // 3. Batch and Serial Report
  Future<List<Map<String, dynamic>>> getItemBatchReport() async {
    final items = await getItems();
    return items.where((it) => it.batchNumber.isNotEmpty || it.serialNumber.isNotEmpty).map((it) {
      return {
        'name': it.name,
        'code': it.code,
        'batchNumber': it.batchNumber,
        'serialNumber': it.serialNumber,
        'expiryDate': it.expiryDate,
        'stock': it.stockQuantity,
        'unit': it.unit,
      };
    }).toList();
  }

  // ================= DASHBOARD SUMMARY METRICS =================
  Future<Map<String, double>> getDashboardMetrics() async {
    final db = await database;

    final recRes = await db.rawQuery('''
      SELECT SUM(currentBalance) as total 
      FROM parties 
      WHERE currentBalance > 0 AND (firmId = ? OR firmId IS NULL)
    ''', [_activeFirmId]);
    final totalReceivables = (recRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final payRes = await db.rawQuery('''
      SELECT SUM(ABS(currentBalance)) as total 
      FROM parties 
      WHERE currentBalance < 0 AND (firmId = ? OR firmId IS NULL)
    ''', [_activeFirmId]);
    final totalPayables = (payRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final saleRes = await db.rawQuery('''
      SELECT SUM(totalAmount) as total 
      FROM invoices 
      WHERE invoiceDate LIKE '$todayStr%' 
        AND (firmId = ? OR firmId IS NULL) 
        AND (isDeleted = 0 OR isDeleted IS NULL)
    ''', [_activeFirmId]);
    final todaySale = (saleRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final stockRes = await db.rawQuery('''
      SELECT SUM(salePrice * stockQuantity) as total 
      FROM items
      WHERE (firmId = ? OR firmId IS NULL)
    ''', [_activeFirmId]);
    final totalStockValue = (stockRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final lowStockRes = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM items 
      WHERE stockQuantity <= minStockAlert AND (firmId = ? OR firmId IS NULL)
    ''', [_activeFirmId]);
    final lowStockCount = (lowStockRes.first['count'] as num?)?.toDouble() ?? 0.0;

    return {
      'totalReceivables': totalReceivables,
      'totalPayables': totalPayables,
      'todaySale': todaySale,
      'totalStockValue': totalStockValue,
      'lowStockCount': lowStockCount,
    };
  }
}
